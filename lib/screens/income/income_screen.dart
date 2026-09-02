import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import 'income_view_model.dart';
import '../../models/income_details.dart';
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                        border: Border.all(color: AppColors.danger.withOpacity(0.5)),
                      ),
                      width: double.infinity,
                      child: Text(
                        vm.error!,
                        style: const TextStyle(color: AppColors.danger, fontFamily: 'UNGanganee'),
                      ),
                    ),

                  _buildLabel('ගෘහ මූලික අංකය'),
                  TextFormField(
                    initialValue: vm.houseNumber,
                    enabled: false,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
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

  Widget _buildIncomeSection(IncomeDetails details, IncomeViewModel vm) {
    final hasData = details.mainIncome.isNotEmpty;

    // ================= VIEW MODE =================
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
            
            const Text('ප්‍රධාන ආදායම් මාර්ගය', style: TextStyle(fontFamily: 'UNSamantha', fontSize: 14, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            _buildCategoryDataView(details.mainIncome, details),
            
            const Divider(height: 30),
            
            const Text('අමතර ආදායම් මාර්ග', style: TextStyle(fontFamily: 'UNSamantha', fontSize: 14, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            _buildViewRow('අමතර ආදායම් තිබේද:', details.extraIncome),
            
            if (details.extraIncome == 'ඇත') ...[
              if (details.mainIncome != 'රැකියාව / කුලී වැඩ / ව්‍යාපාර') _buildCategoryDataView('රැකියාව / කුලී වැඩ / ව්‍යාපාර', details),
              if (details.mainIncome != 'කෘෂිකර්මාන්තය') _buildCategoryDataView('කෘෂිකර්මාන්තය', details),
              if (details.mainIncome != 'සත්ත්ව කර්මාන්තය') _buildCategoryDataView('සත්ත්ව කර්මාන්තය', details),
              if (details.mainIncome != 'ධීවර කර්මාන්තය') _buildCategoryDataView('ධීවර කර්මාන්තය', details),
              if (details.mainIncome != 'සංචාරක කර්මාන්තය') _buildCategoryDataView('සංචාරක කර්මාන්තය', details),
              if (details.mainIncome != 'වෙනත්') _buildCategoryDataView('වෙනත්', details),
            ]
          ],
        ),
      );
    }

    // ================= EDIT MODE =================
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

        _buildLabel('ප්‍රධාන ආදායම් මාර්ගය කුමක්ද?'),
        _buildDropdown(
          value: details.mainIncome,
          hintText: 'ප්‍රධාන ආදායම තෝරන්න',
          items: [
            'රැකියාව / කුලී වැඩ / ව්‍යාපාර', 
            'කෘෂිකර්මාන්තය', 
            'සත්ත්ව කර්මාන්තය', 
            'ධීවර කර්මාන්තය', 
            'සංචාරක කර්මාන්තය', 
            'වෙනත්'
          ],
          onChanged: (val) => vm.updateField(mainIncome: val),
        ),
        
        if (details.mainIncome.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildCategoryForm(details.mainIncome, details, vm, isMain: true),
          const SizedBox(height: 24),
          const Divider(thickness: 1.5),
          const SizedBox(height: 16),
        ],

        _buildLabel('අමතර ආදායම් මාර්ග තිබේද?'),
        _buildDropdown(
          value: details.extraIncome,
          hintText: 'තෝරන්න',
          items: ['ඇත', 'නැත'],
          onChanged: (val) => vm.updateField(extraIncome: val),
        ),
        
        if (details.extraIncome == 'ඇත') ...[
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
                const Text(
                  'අමතර ආදායම් මාර්ග විස්තර (අදාළ ඒවා පමණක් පුරවන්න)',
                  style: TextStyle(fontFamily: 'UNSamantha', fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                if (details.mainIncome != 'රැකියාව / කුලී වැඩ / ව්‍යාපාර') _buildCategoryForm('රැකියාව / කුලී වැඩ / ව්‍යාපාර', details, vm, isMain: false),
                if (details.mainIncome != 'කෘෂිකර්මාන්තය') _buildCategoryForm('කෘෂිකර්මාන්තය', details, vm, isMain: false),
                if (details.mainIncome != 'සත්ත්ව කර්මාන්තය') _buildCategoryForm('සත්ත්ව කර්මාන්තය', details, vm, isMain: false),
                if (details.mainIncome != 'ධීවර කර්මාන්තය') _buildCategoryForm('ධීවර කර්මාන්තය', details, vm, isMain: false),
                if (details.mainIncome != 'සංචාරක කර්මාන්තය') _buildCategoryForm('සංචාරක කර්මාන්තය', details, vm, isMain: false),
                if (details.mainIncome != 'වෙනත්') _buildCategoryForm('වෙනත්', details, vm, isMain: false),
              ],
            ),
          )
        ],
      ],
    );
  }

  // ================= HELPER METHODS (FORMS) =================

  Widget _buildCategoryForm(String category, IncomeDetails details, IncomeViewModel vm, {required bool isMain}) {
    switch (category) {
      case 'රැකියාව / කුලී වැඩ / ව්‍යාපාර': return _buildJobForm(details, vm, isMain);
      case 'කෘෂිකර්මාන්තය': return _buildAgriForm(details, vm, isMain);
      case 'සත්ත්ව කර්මාන්තය': return _buildAnimalForm(details, vm, isMain);
      case 'ධීවර කර්මාන්තය': return _buildFishingForm(details, vm, isMain);
      case 'සංචාරක කර්මාන්තය': return _buildTourismForm(details, vm, isMain);
      case 'වෙනත්': return _buildOtherForm(details, vm, isMain);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildJobForm(IncomeDetails details, IncomeViewModel vm, bool isMain) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(isMain ? 'ස්වභාවය තෝරන්න' : 'රැකියාවක්/කුලී වැඩක් කරන්නේද?'),
        _buildDropdown(
          value: details.jobType,
          hintText: 'තෝරන්න',
          items: [
            'රජයේ', 
            'අර්ධ රාජ්‍ය', 
            'පුද්ගලික අංශයේ', 
            'කුලී වැඩ / දෛනික වැටුප්', 
            'ස්වයං රැකියා', 
            'ව්‍යාපාර / වෙළඳාම්', 
            'විදෙස් රැකියා', 
            'විශ්‍රාම වැටුප්', 
            'වෙනත්', 
            'නැත'
          ],
          onChanged: (val) => vm.updateField(jobType: val),
        ),
        if (details.jobType != 'නැත' && details.jobType.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('තනතුර / විස්තරය', style: TextStyle(fontFamily: 'UNSamantha', fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: details.jobPosition,
                  onChanged: (val) => vm.updateField(jobPosition: val),
                  decoration: _inputStyle(hint: 'උදා: පෙදරේරු / කළමනාකරු'),
                ),
                const SizedBox(height: 12),
                const Text('ආයතනය / සේවා ස්ථානය (ඇත්නම් පමණක්)', style: TextStyle(fontFamily: 'UNSamantha', fontSize: 13, fontWeight: FontWeight.bold)),
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
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAgriForm(IncomeDetails details, IncomeViewModel vm, bool isMain) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(isMain ? 'කෘෂිකාර්මික වර්ගය' : 'කෘෂිකාර්මික කටයුතු කරන්නේද?'),
        _buildDropdown(
          value: details.agricultureType,
          hintText: 'තෝරන්න',
          items: [
            'වී වගාව (තමන්ගේ ඉඩමේ)', 
            'අඳ ගොවිතැන (හවුල් වගාව)', 
            'තේ', 
            'රබර්', 
            'පොල්', 
            'එළවළු / පලතුරු වගාව', 
            'සුළු අපනයන බෝග (කුරුඳු ආදිය)', 
            'හේන් ගොවිතැන', 
            'වෙනත්', 
            'නැත'
          ],
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
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAnimalForm(IncomeDetails details, IncomeViewModel vm, bool isMain) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(isMain ? 'සත්ත්ව කර්මාන්තය' : 'සත්ත්ව කර්මාන්තයේ නියැලෙන්නේද?'),
        _buildDropdown(
          value: details.animalHusbandryType,
          hintText: 'තෝරන්න',
          items: ['කිරි ගව පාලනය', 'කුකුළු පාලනය', 'ඌරු පාලනය', 'එළු පාලනය', 'මී මැසි පාලනය', 'වෙනත්', 'නැත'],
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
          const Text('සතුන් ගණන (ආසන්න වශයෙන්)', style: TextStyle(fontFamily: 'UNSamantha', fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: details.animalCount?.toString(),
            onChanged: (val) => vm.updateField(animalCount: val),
            keyboardType: TextInputType.number,
            decoration: _inputStyle(),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFishingForm(IncomeDetails details, IncomeViewModel vm, bool isMain) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(isMain ? 'ධීවර කර්මාන්තයේ වර්ගය' : 'ධීවර කර්මාන්තයේ නියැලෙන්නේද?'),
        _buildDropdown(
          value: details.fishingType,
          hintText: 'තෝරන්න',
          items: ['මුහුදු ධීවර කර්මාන්තය', 'මිරිදිය ධීවර කර්මාන්තය', 'විසිතුරු මසුන් ඇති කිරීම', 'කරවල / මාළු අලෙවිය', 'වෙනත්', 'නැත'],
          onChanged: (val) => vm.updateField(fishingType: val),
        ),
        if (details.fishingType == 'වෙනත්') ...[
          const SizedBox(height: 8),
          TextFormField(
            initialValue: details.fishingOther,
            onChanged: (val) => vm.updateField(fishingOther: val),
            decoration: _inputStyle(hint: 'විස්තරය ඇතුළත් කරන්න'),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTourismForm(IncomeDetails details, IncomeViewModel vm, bool isMain) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(isMain ? 'සංචාරක කර්මාන්තය' : 'සංචාරක කර්මාන්තයේ නියැලෙන්නේද?'),
        _buildDropdown(
          value: details.tourismType,
          hintText: 'තෝරන්න',
          items: ['හෝටල් / නවාතැන් සැපයීම', 'ප්‍රවාහන සේවා (සෆාරි, ටුක්ටුක්)', 'මඟ පෙන්වන්නන් (Tour Guide)', 'සංචාරක භාණ්ඩ අලෙවිය', 'වෙනත්', 'නැත'],
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
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildOtherForm(IncomeDetails details, IncomeViewModel vm, bool isMain) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(isMain ? 'වෙනත් ආදායම් මාර්ග විස්තරය' : 'වෙනත් ආදායම් තිබේද? (විස්තරය)'),
        TextFormField(
          initialValue: details.otherIncomeDesc,
          onChanged: (val) => vm.updateField(otherIncomeDesc: val),
          decoration: _inputStyle(hint: 'උදා: කුලී නිවාස / ආධාර මුදල්'),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ================= VIEW MODE HELPERS =================

  Widget _buildCategoryDataView(String category, IncomeDetails details) {
    switch (category) {
      case 'රැකියාව / කුලී වැඩ / ව්‍යාපාර':
        if (details.jobType.isEmpty || details.jobType == 'නැත') return const SizedBox.shrink();
        return Column(
          children: [
            _buildViewRow(' • ස්වභාවය:', details.jobType),
            if (details.jobPosition.isNotEmpty) _buildViewRow('   - තනතුර / විස්තරය:', details.jobPosition),
            if (details.jobInstitute.isNotEmpty) _buildViewRow('   - සේවා ස්ථානය:', details.jobInstitute),
          ],
        );
      case 'කෘෂිකර්මාන්තය':
        if (details.agricultureType.isEmpty || details.agricultureType == 'නැත') return const SizedBox.shrink();
        return Column(
          children: [
            _buildViewRow(' • කෘෂිකාර්මික:', details.agricultureType),
            if (details.agricultureType == 'වෙනත්') _buildViewRow('   - විස්තරය:', details.agricultureOther),
          ],
        );
      case 'සත්ත්ව කර්මාන්තය':
        if (details.animalHusbandryType.isEmpty || details.animalHusbandryType == 'නැත') return const SizedBox.shrink();
        return Column(
          children: [
            _buildViewRow(' • සත්ත්ව කර්මාන්තය:', details.animalHusbandryType),
            if (details.animalHusbandryType == 'වෙනත්') _buildViewRow('   - වර්ගය:', details.animalHusbandryOther),
            if (details.animalCount.isNotEmpty) _buildViewRow('   - සතුන් ගණන:', details.animalCount),
          ],
        );
      case 'ධීවර කර්මාන්තය':
        if (details.fishingType.isEmpty || details.fishingType == 'නැත') return const SizedBox.shrink();
        return Column(
          children: [
             _buildViewRow(' • ධීවර කර්මාන්තය:', details.fishingType),
             if (details.fishingType == 'වෙනත්') _buildViewRow('   - විස්තරය:', details.fishingOther),
          ],
        );
      case 'සංචාරක කර්මාන්තය':
        if (details.tourismType.isEmpty || details.tourismType == 'නැත') return const SizedBox.shrink();
        return Column(
          children: [
            _buildViewRow(' • සංචාරක:', details.tourismType),
            if (details.tourismType == 'වෙනත්') _buildViewRow('   - විස්තරය:', details.tourismOther),
          ],
        );
      case 'වෙනත්':
        if (details.otherIncomeDesc.isEmpty) return const SizedBox.shrink();
        return _buildViewRow(' • වෙනත් ආදායම්:', details.otherIncomeDesc);
      default:
        return const SizedBox.shrink();
    }
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
            child: Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13, fontFamily: 'UNGanganee')),
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