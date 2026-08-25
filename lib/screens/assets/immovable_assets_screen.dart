import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import 'assets_view_model.dart';
import '../../widgets/app_button.dart'; // AppButton එක ඇතුළත් කර ඇත

class ImmovableAssetsScreen extends StatefulWidget {
  const ImmovableAssetsScreen({super.key});

  @override
  State<ImmovableAssetsScreen> createState() => _ImmovableAssetsScreenState();
}

class _ImmovableAssetsScreenState extends State<ImmovableAssetsScreen> {
  // නිශ්චල දේපල තොරතුරු සංස්කරණය කරනවාද යන්න තීරණය කරන State variable එක
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
          'නිශ්චල දේපල',
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

                  // නව View/Edit ලොජික් එක ඇතුළත් කළ දේපල තොරතුරු කොටස
                  _buildImmovableSection(details, vm),

                  const SizedBox(height: 40),

                  // Submit Data Button
                  AppButton(
                    label: 'සුරකින්න',
                    isLoading: vm.isBusy,
                    onPressed: () async {
                      final success = await vm.save();
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'තොරතුරු සාර්ථකව සුරැකිණි!',
                              style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        Navigator.pop(context); // ආපසු Assets Main තිරයට
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
  Widget _buildImmovableSection(dynamic details, AssetsViewModel vm) {
    // දත්ත දැනටමත් ඇතුළත් කර ඇත්දැයි බැලීම
    final hasData = details.hasHighland == true || details.hasMudland == true;

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
                  'නිශ්චල දේපල තොරතුරු',
                  style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => setState(() => _isEditingInfo = true),
                ),
              ],
            ),
            const Divider(),
            
            // ගොඩ ඉඩම් View
            _buildViewRow('ගොඩ ඉඩම්:', details.hasHighland ? 'ඇත' : 'නැත'),
            if (details.hasHighland) ...[
              _buildViewRow('  • ප්‍රමාණය:', details.highlandExtent ?? '-'),
              _buildViewRow('  • තත්ත්වය:', details.isHighlandCultivated ? 'වගා කර ඇත' : 'වගා කර නැත'),
              if (!details.isHighlandCultivated)
                _buildViewRow('  • හේතුව:', _getHighlandReasons(details)),
            ],
            
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // මඩ ඉඩම් View
            _buildViewRow('මඩ ඉඩම්:', details.hasMudland ? 'ඇත' : 'නැත'),
            if (details.hasMudland) ...[
              _buildViewRow('  • ප්‍රමාණය:', details.mudlandExtent ?? '-'),
              _buildViewRow('  • තත්ත්වය:', details.isMudlandCultivated ? 'වගා කර ඇත' : 'වගා කර නැත'),
              if (!details.isMudlandCultivated)
                _buildViewRow('  • හේතුව:', _getMudlandReasons(details)),
            ],
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
              'තොරතුරු ඇතුළත් කරන්න',
              style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (hasData)
              IconButton(
                icon: const Icon(Icons.check, color: AppColors.success, size: 24),
                onPressed: () => setState(() => _isEditingInfo = false),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ======================= ගොඩ ඉඩම් =======================
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
              _buildLabel('ගොඩ ඉඩම් තිබේද?'),
              _buildYesNoRadio(
                value: details.hasHighland,
                onChanged: (val) => vm.updateField(hasHighland: val),
              ),
              
              if (details.hasHighland) ...[
                const SizedBox(height: 16),
                _buildLabel('මුළු ඉඩම් ප්‍රමාණය'),
                TextFormField(
                  initialValue: details.highlandExtent,
                  onChanged: (val) => vm.updateField(highlandExtent: val),
                  decoration: _inputStyle(hint: 'ප්‍රමාණය ඇතුළත් කරන්න (අක්කර/පර්චස්)'),
                ),
                const SizedBox(height: 16),
                _buildLabel('ඉඩමේ තත්ත්වය'),
                _buildCultivatedRadio(
                  isCultivated: details.isHighlandCultivated,
                  onChanged: (val) => vm.updateField(isHighlandCultivated: val),
                ),
                
                if (!details.isHighlandCultivated) ...[
                  const SizedBox(height: 16),
                  _buildLabel('වගා නොකළා නම් හේතුව'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _buildCheckbox('ජලය නොමැත', details.hlNoWater, (v) => vm.updateField(hlNoWater: v)),
                      _buildCheckbox('සත්ව හානි', details.hlAnimalDamage, (v) => vm.updateField(hlAnimalDamage: v)),
                      _buildCheckbox('මුදල්/ශ්‍රමය', details.hlMoneyLabor, (v) => vm.updateField(hlMoneyLabor: v)),
                      _buildCheckbox('වෙනත්', details.hlOther, (v) => vm.updateField(hlOther: v)),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ======================= මඩ ඉඩම් =======================
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
              _buildLabel('මඩ ඉඩම් තිබේද?'),
              _buildYesNoRadio(
                value: details.hasMudland,
                onChanged: (val) => vm.updateField(hasMudland: val),
              ),

              if (details.hasMudland) ...[
                const SizedBox(height: 16),
                _buildLabel('මුළු ඉඩම් ප්‍රමාණය'),
                TextFormField(
                  initialValue: details.mudlandExtent,
                  onChanged: (val) => vm.updateField(mudlandExtent: val),
                  decoration: _inputStyle(hint: 'ප්‍රමාණය ඇතුළත් කරන්න (අක්කර/පර්චස්)'),
                ),
                const SizedBox(height: 16),
                _buildLabel('ඉඩමේ තත්ත්වය'),
                _buildCultivatedRadio(
                  isCultivated: details.isMudlandCultivated,
                  onChanged: (val) => vm.updateField(isMudlandCultivated: val),
                ),

                if (!details.isMudlandCultivated) ...[
                  const SizedBox(height: 16),
                  _buildLabel('වගා නොකළා නම් හේතුව'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _buildCheckbox('ජලය නොමැත', details.mlNoWater, (v) => vm.updateField(mlNoWater: v)),
                      _buildCheckbox('සත්ව හානි', details.mlAnimalDamage, (v) => vm.updateField(mlAnimalDamage: v)),
                      _buildCheckbox('මුදල්/ශ්‍රමය', details.mlMoneyLabor, (v) => vm.updateField(mlMoneyLabor: v)),
                      _buildCheckbox('උපකරණ', details.mlEquipment, (v) => vm.updateField(mlEquipment: v)),
                      _buildCheckbox('පොහොර', details.mlFertilizer, (v) => vm.updateField(mlFertilizer: v)),
                      _buildCheckbox('වෙනත්', details.mlOther, (v) => vm.updateField(mlOther: v)),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- Helper Methods ---

  String _getHighlandReasons(dynamic details) {
    List<String> reasons = [];
    if (details.hlNoWater == true) reasons.add('ජලය නොමැත');
    if (details.hlAnimalDamage == true) reasons.add('සත්ව හානි');
    if (details.hlMoneyLabor == true) reasons.add('මුදල්/ශ්‍රමය');
    if (details.hlOther == true) reasons.add('වෙනත්');
    return reasons.isEmpty ? '-' : reasons.join(', ');
  }

  String _getMudlandReasons(dynamic details) {
    List<String> reasons = [];
    if (details.mlNoWater == true) reasons.add('ජලය නොමැත');
    if (details.mlAnimalDamage == true) reasons.add('සත්ව හානි');
    if (details.mlMoneyLabor == true) reasons.add('මුදල්/ශ්‍රමය');
    if (details.mlEquipment == true) reasons.add('උපකරණ');
    if (details.mlFertilizer == true) reasons.add('පොහොර');
    if (details.mlOther == true) reasons.add('වෙනත්');
    return reasons.isEmpty ? '-' : reasons.join(', ');
  }

  Widget _buildViewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'UNSamantha',
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildYesNoRadio({required bool value, required Function(bool) onChanged}) {
    return Row(
      children: [
        const Text('ඇත', style: TextStyle(fontFamily: 'UNGanganee', fontSize: 16)),
        Radio<bool>(
          value: true,
          groupValue: value,
          activeColor: AppColors.primary,
          onChanged: (val) => onChanged(true),
        ),
        const SizedBox(width: 20),
        const Text('නැත', style: TextStyle(fontFamily: 'UNGanganee', fontSize: 16)),
        Radio<bool>(
          value: false,
          groupValue: value,
          activeColor: AppColors.danger, // 'නැත' සඳහා රතු පැහැය
          onChanged: (val) => onChanged(false),
        ),
      ],
    );
  }

  Widget _buildCultivatedRadio({required bool isCultivated, required Function(bool) onChanged}) {
    return Row(
      children: [
        const Text('වගා කර ඇත', style: TextStyle(fontFamily: 'UNGanganee', fontSize: 14)),
        Radio<bool>(
          value: true,
          groupValue: isCultivated,
          activeColor: AppColors.primary,
          onChanged: (val) => onChanged(true),
        ),
        const SizedBox(width: 10),
        const Text('වගා කර නැත', style: TextStyle(fontFamily: 'UNGanganee', fontSize: 14)),
        Radio<bool>(
          value: false,
          groupValue: isCultivated,
          activeColor: AppColors.danger,
          onChanged: (val) => onChanged(false),
        ),
      ],
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'UNGanganee', fontSize: 13, color: AppColors.textPrimary)),
        Checkbox(
          value: value,
          activeColor: AppColors.primary,
          onChanged: (v) => onChanged(v ?? false),
        ),
      ],
    );
  }

  InputDecoration _inputStyle({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.fieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none, // AppTheme එකේ මෙන් Border.none
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}