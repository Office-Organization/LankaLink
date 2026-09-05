import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import 'housing_view_model.dart';
import '../../widgets/app_button.dart';

class HousingScreen extends StatefulWidget {
  const HousingScreen({super.key});

  @override
  State<HousingScreen> createState() => _HousingScreenState();
}

class _HousingScreenState extends State<HousingScreen> {
  // නිවාස තොරතුරු සංස්කරණය කරනවාද යන්න තීරණය කරන State variable එක
  bool _isEditingHousingInfo = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HousingViewModel>();
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
          'පදිංචිය හා නිවාස',
          style: TextStyle(
            fontFamily: 'UNSamantha',
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
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

                  // ==========================================
                  // අගුළු දැමූ ගෘහ මූලික අංකය (Locked House ID)
                  // ==========================================
                  _buildLabel('ගෘහ මූලික අංකය'),
                  TextFormField(
                    initialValue: vm.houseNumber,
                    enabled: false,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey, // අළු පැහැති අකුරු
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5), // ලා අළු පැහැති පසුබිම
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // නව View/Edit ලොජික් එක ඇතුළත් කළ නිවාස තොරතුරු කොටස
                  _buildHousingSection(details, vm),

                  _buildUpdateLog(details.updatedBy, details.updatedAt),

                  const SizedBox(height: 40),

                  // Submit Data / Next Page Button
                  AppButton(
                    label: 'ඊළඟ පිටුවට',
                    isLoading: vm.isBusy,
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final currentHouseNumber = vm.houseNumber;
                      
                      final success = await vm.save();
                      
                      if (success) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('දත්ත සාර්ථකව සුරැකිණි!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        navigator.pushNamed(
                          Routes.income,
                          arguments: currentHouseNumber,
                        );
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
  Widget _buildHousingSection(dynamic details, HousingViewModel vm) {
    // දත්ත දැනටමත් ඇතුළත් කර ඇත්දැයි බැලීම
    final hasData = details.nature != null && details.nature!.isNotEmpty;

    // View Mode (දත්ත පෙන්වන කොටුව)
    if (hasData && !_isEditingHousingInfo) {
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
                  'නිවාස තොරතුරු',
                  style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => setState(() => _isEditingHousingInfo = true),
                ),
              ],
            ),
            const Divider(),
            _buildViewRow('නිවසක් තිබේද:', details.hasHouse == true ? 'ඇත' : (details.hasHouse == false ? 'නැත' : '-')),
            _buildViewRow('ස්වභාවය:', details.nature ?? '-'),
            _buildViewRow('සනීපාරක්ෂක:', details.sanitation ?? '-'),
            _buildViewRow('විදුලිය:', details.electricity ?? '-'),
            _buildViewRow('ජලය:', details.water ?? '-'),
            _buildViewRow('ස්ථාවර දුරකථන:', (details.hasFixedPhone == true) ? 'ඇත' : 'නැත'),
            _buildViewRow('ජංගම දුරකථන:', (details.hasMobilePhone == true) ? 'ඇත' : 'නැත'),
            _buildViewRow('සිග්නල්:', details.signal ?? '-'),
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
              'නිවාස තොරතුරු ඇතුළත් කරන්න',
              style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (hasData)
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green, size: 24),
                onPressed: () => setState(() => _isEditingHousingInfo = false),
              ),
          ],
        ),
        const SizedBox(height: 16),

        _buildLabel('නිවසක් තිබේද'),
        Row(
          children: [
            const Text('ඇත', style: TextStyle(fontFamily: 'UNGanganee', fontSize: 16)),
            Radio<bool?>( // bool? ලෙස යෙදීමෙන් මුලදී කිසිවක් තෝරා නොමැති ලෙස (null) තැබිය හැක
              value: true,
              groupValue: details.hasHouse,
              activeColor: AppColors.primary,
              onChanged: (val) => vm.updateField(hasHouse: val),
            ),
            const SizedBox(width: 20),
            const Text('නැත', style: TextStyle(fontFamily: 'UNGanganee', fontSize: 16)),
            Radio<bool?>(
              value: false,
              groupValue: details.hasHouse,
              activeColor: AppColors.success,
              onChanged: (val) => vm.updateField(hasHouse: val),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildLabel('ස්වභාවය'),
        _buildDropdown(
          value: details.nature,
          hintText: 'ස්වභාවය තෝරන්න',
          items: [
            'මහල් නිවාස (ෆ්ලැට්)',
            'ස්ථිර තනි',
            'අර්ධ ස්ථිර',
            'තාවකාලික',
            'ලැයින් කාමර', // 🟢 Added Line House here
          ],
          onChanged: (val) => vm.updateField(nature: val),
        ),
        const SizedBox(height: 16),

        _buildLabel('සනීපාරක්ෂක පහසුකම්'),
        _buildDropdown(
          value: details.sanitation,
          hintText: 'පහසුකම තෝරන්න',
          items: ['ජල මුද්‍රිත', 'වල'],
          onChanged: (val) => vm.updateField(sanitation: val),
        ),
        const SizedBox(height: 16),

        _buildLabel('විදුලිය'),
        _buildDropdown(
          value: details.electricity,
          hintText: 'විදුලිය ඇත/නැත තෝරන්න',
          items: ['ඇත', 'නැත'],
          onChanged: (val) => vm.updateField(electricity: val),
        ),
        const SizedBox(height: 16),

        _buildLabel('ජලය'),
        _buildDropdown(
          value: details.water,
          hintText: 'ජල මූලාශ්‍රය තෝරන්න',
          items: [
            'වෝටර් බෝඩ්',
            'ආරක්ෂිත ළිං',
            'අනාරක්ෂිත ළිං',
            'ප්‍රජා ජල ව්‍යාපෘති',
          ],
          onChanged: (val) => vm.updateField(water: val),
        ),
        const SizedBox(height: 16),

        _buildLabel('සන්නිවේදන පහසුකම්'),
        Row(
          children: [
            const Text('දුරකථන', style: TextStyle(fontFamily: 'UNGanganee', fontSize: 16)),
            const SizedBox(width: 20),
            const Text('ස්ථාවර', style: TextStyle(fontFamily: 'UNGanganee', fontSize: 16)),
            Checkbox(
              value: details.hasFixedPhone ?? false,
              activeColor: AppColors.primary,
              onChanged: (val) => vm.updateField(hasFixedPhone: val),
            ),
            const SizedBox(width: 10),
            const Text('ජංගම', style: TextStyle(fontFamily: 'UNGanganee', fontSize: 16)),
            Checkbox(
              value: details.hasMobilePhone ?? false,
              activeColor: AppColors.primary,
              onChanged: (val) => vm.updateField(hasMobilePhone: val),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildLabel('සිග්නල්'),
        _buildDropdown(
          value: details.signal,
          hintText: 'සිග්නල් තත්වය තෝරන්න',
          items: ['3G', '4G', '5G', 'නැත'],
          onChanged: (val) => vm.updateField(signal: val),
        ),
      ],
    );
  }

  // View Mode එකේ පේළි පෙන්වීමට සරල Widget එකක්
  Widget _buildViewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13, fontFamily: 'UNGanganee')),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'UNGanganee')),
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

  // 🟢 Dropdown එක හිස්ව තබාගැනීමට සකස් කරන ලද නව කේතය
  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String hintText,
  }) {
    // අගයක් නොමැති නම් null ලෙස පවතී
    String? dropdownValue = (value != null && items.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      value: dropdownValue,
      hint: Text(hintText, style: const TextStyle(fontFamily: 'UNGanganee', color: Colors.black54)),
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: const TextStyle(fontFamily: 'UNGanganee', fontSize: 16),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // 🟢 ලොගය පෙන්වන Widget එක 
  Widget _buildUpdateLog(String? updatedBy, DateTime? updatedAt) {
    // දත්ත නොමැති නම් (අලුත් ගෙදරක් නම්)
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
                'මෙම ගෙදරට අදාළව මින් පෙර නිවාස තොරතුරු පද්ධතියට ඇතුළත් කර නොමැත. මෙය නව ඇතුළත් කිරීමකි.',
                style: TextStyle(fontFamily: 'UNGanganee', fontSize: 14, color: Colors.green.shade900),
              ),
            ),
          ],
        ),
      );
    }

    // දත්ත තිබේ නම් (කලින් සංස්කරණය කර ඇත්නම්)
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