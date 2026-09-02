import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import 'income_view_model.dart';
import '../../widgets/app_button.dart'; 

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  bool _isEditingIncomeInfo = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<IncomeViewModel>();
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
          'ආදායම් මාර්ග',
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

                  _buildLabel('ගෘහ මූලික අංකය'),
                  TextFormField(
                    initialValue: vm.houseNumber,
                    enabled: false,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey, 
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5), 
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildIncomeSection(details, vm),

                  // 🟢 දත්ත යාවත්කාලීන කළ ලොගය (Update Log)
                  _buildUpdateLog(details.updatedBy, details.updatedAt),

                  const SizedBox(height: 40),

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
                          Routes.assetsMain,
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

  Widget _buildIncomeSection(dynamic details, IncomeViewModel vm) {
    final hasData = details.mainIncome != null && details.mainIncome.isNotEmpty;

    if (hasData && !_isEditingIncomeInfo) {
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
                  'ආදායම් තොරතුරු',
                  style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => setState(() => _isEditingIncomeInfo = true),
                ),
              ],
            ),
            const Divider(),
            _buildViewRow('ප්‍රධාන ආදායම් මාර්ග:', details.mainIncome),
            _buildViewRow('අමතර ආදායම් මාර්ග:', details.extraIncome),
            _buildViewRow('රැකියාව:', details.jobType),
            if (details.jobType != 'නැත' && details.jobType.isNotEmpty) ...[
              _buildViewRow('  • තනතුර:', details.jobPosition),
              _buildViewRow('  • ආයතනය:', details.jobInstitute),
            ],
            _buildViewRow('සංචාරක:', details.tourismType),
            if (details.tourismType == 'වෙනත්')
              _buildViewRow('  • විස්තරය:', details.tourismOther),
            _buildViewRow('කෘෂිකාර්මික:', details.agricultureType),
            if (details.agricultureType == 'වෙනත්')
              _buildViewRow('  • විස්තරය:', details.agricultureOther),
            _buildViewRow('සත්ත්ව කර්මාන්තය:', details.animalHusbandryType),
            if (details.animalHusbandryType == 'වෙනත්')
              _buildViewRow('  • වර්ගය:', details.animalHusbandryOther),
            if (details.animalHusbandryType != 'නැත' && details.animalHusbandryType.isNotEmpty)
              _buildViewRow('  • සතුන් ගණන:', details.animalCount?.toString()),
            _buildViewRow('ධීවර කර්මාන්තය:', details.fishingType),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ආදායම් තොරතුරු ඇතුළත් කරන්න',
              style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (hasData)
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green, size: 24),
                onPressed: () => setState(() => _isEditingIncomeInfo = false),
              ),
          ],
        ),
        const SizedBox(height: 16),

        _buildLabel('ප්‍රධාන ආදායම් මාර්ග'),
        _buildDropdown(
          value: details.mainIncome,
          hintText: 'ප්‍රධාන ආදායමක් තිබේද?',
          items: ['ඇත', 'නැත'],
          onChanged: (val) => vm.updateField(mainIncome: val),
        ),
        const SizedBox(height: 16),

        _buildLabel('අමතර ආදායම් මාර්ග'),
        _buildDropdown(
          value: details.extraIncome,
          hintText: 'අමතර ආදායමක් තිබේද?',
          items: ['ඇත', 'නැත'],
          onChanged: (val) => vm.updateField(extraIncome: val),
        ),
        const SizedBox(height: 16),

        _buildLabel('රැකියාව'),
        _buildDropdown(
          value: details.jobType,
          hintText: 'රැකියාවේ වර්ගය තෝරන්න',
          items: [
            'රජයේ',
            'පුද්ගලික අංශයේ',
            'අර්ධ රාජ්‍ය',
            'විදෙස්',
            'නැත',
          ],
          onChanged: (val) => vm.updateField(jobType: val),
        ),

        if (details.jobType != 'නැත' && details.jobType.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('තනතුර', style: TextStyle(fontFamily: 'UNSamantha', fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: details.jobPosition,
                  onChanged: (val) => vm.updateField(jobPosition: val),
                  decoration: _inputStyle(),
                ),
                const SizedBox(height: 12),
                const Text('ආයතනය', style: TextStyle(fontFamily: 'UNSamantha', fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: details.jobInstitute,
                  onChanged: (val) => vm.updateField(jobInstitute: val),
                  decoration: _inputStyle(),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        _buildLabel('සංචාරක'),
        _buildDropdown(
          value: details.tourismType,
          hintText: 'සංචාරක කර්මාන්තයේ නියැලෙන්නේද?',
          items: ['සේවා සැපයීම', 'පහසුකම් සැපයීම', 'වෙනත්', 'නැත'],
          onChanged: (val) => vm.updateField(tourismType: val),
        ),
        if (details.tourismType == 'වෙනත්') ...[
          const SizedBox(height: 8),
          TextFormField(
            initialValue: details.tourismOther,
            onChanged: (val) => vm.updateField(tourismOther: val),
            decoration: _inputStyle(hint: 'විස්තරය ඇතුළත් කරන්න'),
          ),
        ],
        const SizedBox(height: 16),

        _buildLabel('කෘෂිකාර්මික'),
        _buildDropdown(
          value: details.agricultureType,
          hintText: 'කෘෂිකාර්මික කටයුතු',
          items: ['තේ', 'වී', 'රබර්', 'පොල්', 'වෙනත්', 'නැත'],
          onChanged: (val) => vm.updateField(agricultureType: val),
        ),
        if (details.agricultureType == 'වෙනත්') ...[
          const SizedBox(height: 8),
          TextFormField(
            initialValue: details.agricultureOther,
            onChanged: (val) => vm.updateField(agricultureOther: val),
            decoration: _inputStyle(hint: 'විස්තරය ඇතුළත් කරන්න'),
          ),
        ],
        const SizedBox(height: 16),

        _buildLabel('සත්ත්ව කර්මාන්තය'),
        _buildDropdown(
          value: details.animalHusbandryType,
          hintText: 'සත්ත්ව කර්මාන්තය',
          items: ['ඌරන්', 'කුකුළන්', 'හරකුන්', 'එළුවන්', 'වෙනත්', 'නැත'],
          onChanged: (val) => vm.updateField(animalHusbandryType: val),
        ),
        if (details.animalHusbandryType == 'වෙනත්') ...[
          const SizedBox(height: 8),
          TextFormField(
            initialValue: details.animalHusbandryOther,
            onChanged: (val) => vm.updateField(animalHusbandryOther: val),
            decoration: _inputStyle(hint: 'කුමන සතුන්ද?'),
          ),
        ],
        if (details.animalHusbandryType != 'නැත' && details.animalHusbandryType.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('සතුන් ගණන', style: TextStyle(fontFamily: 'UNSamantha', fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: details.animalCount?.toString(),
            onChanged: (val) => vm.updateField(animalCount: val),
            keyboardType: TextInputType.number,
            decoration: _inputStyle(),
          ),
        ],
        const SizedBox(height: 16),

        _buildLabel('ධීවර කර්මාන්තය'),
        _buildDropdown(
          value: details.fishingType,
          hintText: 'ධීවර කර්මාන්තය',
          items: ['කරදිය', 'මිරිදිය', 'සුරතල් මසුන්', 'නැත'],
          onChanged: (val) => vm.updateField(fishingType: val),
        ),
      ],
    );
  }

  Widget _buildViewRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
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
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

  InputDecoration _inputStyle({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.lightBlue200, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.white, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // 🟢 හිස් (Empty) Dropdown එකක් පෙන්වීම සඳහා සකසන ලද Dropdown Widget එක
  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String hintText,
  }) {
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
          child: Text(item, style: const TextStyle(fontFamily: 'UNGanganee', fontSize: 16)),
        );
      }).toList(),
      onChanged: onChanged,
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
                'මෙම ගෙදරට අදාළව මින් පෙර ආදායම් තොරතුරු පද්ධතියට ඇතුළත් කර නොමැත. මෙය නව ඇතුළත් කිරීමකි.',
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