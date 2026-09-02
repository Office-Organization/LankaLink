import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import 'assets_view_model.dart';
import '../../widgets/app_button.dart'; 

class MovableAssetsScreen extends StatefulWidget {
  const MovableAssetsScreen({super.key});

  @override
  State<MovableAssetsScreen> createState() => _MovableAssetsScreenState();
}

class _MovableAssetsScreenState extends State<MovableAssetsScreen> {
  // චංචල දේපල තොරතුරු සංස්කරණය කරනවාද යන්න තීරණය කරන State variable එක
  bool _isEditingInfo = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssetsViewModel>();
    final details = vm.details;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.lightBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'චංචල දේපල',
          style: TextStyle(
            fontFamily: 'UNSamantha',
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: vm.isBusy
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message display area
                  if (vm.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.danger.withOpacity(0.5),
                        ),
                      ),
                      width: double.infinity,
                      child: Text(
                        vm.error!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontFamily: 'UNGanganee',
                        ),
                      ),
                    ),

                  // නව View/Edit ලොජික් එක ඇතුළත් කළ චංචල දේපල තොරතුරු කොටස
                  _buildMovableSection(details, vm),

                  // 🟢 දත්ත යාවත්කාලීන කළ ලොගය (Update Log)
                  _buildUpdateLog(details.updatedBy, details.updatedAt),

                  const SizedBox(height: 40),

                  // Submit Data Button (AppButton)
                  AppButton(
                    label: 'සුරකින්න',
                    isLoading: vm.isBusy,
                    onPressed: () async {
                      // 🟢 Buffering දෝෂය වළක්වා ගැනීමට Navigator/Messenger කලින් ලබා ගැනීම
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      final success = await vm.save();
                      if (success) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'තොරතුරු සාර්ථකව සුරැකිණි!',
                              style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: Color.fromARGB(241, 159, 6, 98),
                          ),
                        );
                        navigator.pop(); // ආපසු Assets Main තිරයට
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // View Mode සහ Edit Mode පාලනය කරන ප්‍රධාන කොටස
  Widget _buildMovableSection(dynamic details, AssetsViewModel vm) {
    // වාහන එකක් හෝ තෝරා ඇත්දැයි පරීක්ෂා කිරීම
    final hasData = details.hasBike || details.hasThreeWheeler || details.hasVan || 
                    details.hasLorry || details.hasBus || details.hasTractor || 
                    details.hasCar || details.hasCab || details.hasOtherVehicle;

    // View Mode (දත්ත පෙන්වන කොටුව)
    if (hasData && !_isEditingInfo) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'චංචල දේපල තොරතුරු',
                  style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => setState(() => _isEditingInfo = true),
                ),
              ],
            ),
            const Divider(),
            _buildViewRow('ඔබට ඇති වාහන:', _getSelectedVehicles(details)),
          ],
        ),
      );
    }

    // Edit Mode (දත්ත වෙනස් කරන Forms)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'වාහන ඇත්නම් තෝරන්න',
              style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (hasData)
              IconButton(
                icon: const Icon(Icons.check, color: Color.fromARGB(255, 187, 229, 245), size: 24),
                onPressed: () => setState(() => _isEditingInfo = false),
              ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCheckRow(
                'බයික්', details.hasBike ?? false, (v) => vm.updateField(hasBike: v),
                'ත්‍රී වීල්', details.hasThreeWheeler ?? false, (v) => vm.updateField(hasThreeWheeler: v),
              ),
              _buildCheckRow(
                'වෑන්', details.hasVan ?? false, (v) => vm.updateField(hasVan: v),
                'ලොරි', details.hasLorry ?? false, (v) => vm.updateField(hasLorry: v),
              ),
              _buildCheckRow(
                'බස්', details.hasBus ?? false, (v) => vm.updateField(hasBus: v),
                'ට්‍රැක්ටර්', details.hasTractor ?? false, (v) => vm.updateField(hasTractor: v),
              ),
              _buildCheckRow(
                'කාර්', details.hasCar ?? false, (v) => vm.updateField(hasCar: v),
                'කැබ්', details.hasCab ?? false, (v) => vm.updateField(hasCab: v),
              ),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Text(
                          'වෙනත්',
                          style: TextStyle(
                            fontFamily: 'UNGanganee',
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Checkbox(
                          value: details.hasOtherVehicle ?? false,
                          activeColor: AppColors.primary,
                          onChanged: (v) => vm.updateField(hasOtherVehicle: v),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: Container()), // Empty space for layout balance
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Helper Methods ---

  String _getSelectedVehicles(dynamic details) {
    List<String> vehicles = [];
    if (details.hasBike) vehicles.add('බයික්');
    if (details.hasThreeWheeler) vehicles.add('ත්‍රී වීල්');
    if (details.hasVan) vehicles.add('වෑන්');
    if (details.hasLorry) vehicles.add('ලොරි');
    if (details.hasBus) vehicles.add('බස්');
    if (details.hasTractor) vehicles.add('ට්‍රැක්ටර්');
    if (details.hasCar) vehicles.add('කාර්');
    if (details.hasCab) vehicles.add('කැබ්');
    if (details.hasOtherVehicle) vehicles.add('වෙනත්');
    
    return vehicles.isEmpty ? 'නැත' : vehicles.join(', ');
  }

  Widget _buildViewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
          ),
          Expanded(
            child: Text(
              value, 
              style: const TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 15, 
                color: AppColors.textPrimary,
                fontFamily: 'UNGanganee',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckRow(
    String t1,
    bool v1,
    Function(bool?) onChange1,
    String t2,
    bool v2,
    Function(bool?) onChange2,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  t1,
                  style: const TextStyle(
                    fontFamily: 'UNGanganee',
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Checkbox(
                  value: v1,
                  activeColor: AppColors.primary,
                  onChanged: onChange1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Row(
              children: [
                Text(
                  t2,
                  style: const TextStyle(
                    fontFamily: 'UNGanganee',
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Checkbox(
                  value: v2,
                  activeColor: AppColors.primary,
                  onChanged: onChange2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🟢 ලොගය පෙන්වන Widget එක 
  Widget _buildUpdateLog(String? updatedBy, DateTime? updatedAt) {
    if (updatedBy == null && updatedAt == null) {
      return Container(
        margin: const EdgeInsets.only(top: 24),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.green.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'මෙම ගෙදරට අදාළව මින් පෙර චංචල දේපල තොරතුරු පද්ධතියට ඇතුළත් කර නොමැත. මෙය නව ඇතුළත් කිරීමකි.',
                style: TextStyle(fontFamily: 'UNGanganee', fontSize: 14, color: Colors.green.shade900),
              ),
            ),
          ],
        ),
      );
    }

    final dateStr = updatedAt != null 
        ? "${updatedAt.year}-${updatedAt.month.toString().padLeft(2, '0')}-${updatedAt.day.toString().padLeft(2, '0')}  |  ${updatedAt.hour}:${updatedAt.minute.toString().padLeft(2, '0')}" 
        : "නොදන්නා දිනයකි";
        
    return Container(
      margin: const EdgeInsets.only(top: 24),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 20, color: Colors.blueGrey.shade700),
              const SizedBox(width: 8),
              Text('දත්ත යාවත්කාලීන ලොගය', style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey.shade800)),
            ],
          ),
          const SizedBox(height: 12),
          Text('අවසන් වරට වෙනස් කළේ: $updatedBy', style: const TextStyle(fontFamily: 'UNGanganee', fontSize: 14)),
          const SizedBox(height: 4),
          Text('දිනය සහ වේලාව: $dateStr', style: const TextStyle(fontFamily: 'UNGanganee', fontSize: 14)),
        ],
      ),
    );
  }
}