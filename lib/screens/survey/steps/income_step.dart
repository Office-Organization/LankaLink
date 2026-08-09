import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/income.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/app_dropdown.dart';
import '../survey_view_model.dart';

class IncomeStep extends StatefulWidget {
  const IncomeStep({super.key});

  @override
  State<IncomeStep> createState() => _IncomeStepState();
}

class _IncomeStepState extends State<IncomeStep> {
  late IncomeInfo _income;

  final List<String> _yesNo = ['ඇත', 'නැත'];
  final List<String> _jobList = ['රජයේ', 'පුද්ගලික අංශයේ', 'අර්ධ රාජ්‍ය', 'විදෙස්', 'නැත'];
  final List<String> _tourismList = ['සේවා සැපයීම', 'පහසුකම් සැපයීම', 'වෙනත්', 'නැත'];
  final List<String> _agriList = ['තේ', 'වී', 'රබර්', 'පොල්', 'වෙනත්', 'නැත'];
  final List<String> _animalList = ['ඌරන්', 'කුකුළන්', 'හරකුන්', 'එළුවන්', 'වෙනත්', 'නැත'];
  final List<String> _fishingList = ['කරදිය', 'මිරිදිය', 'සුරතල් මසුන්', 'නැත'];

  @override
  void initState() {
    super.initState();
    final vm = context.read<SurveyViewModel>();
    _income = vm.survey?.income ?? const IncomeInfo();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SurveyViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown('ප්‍රධාන ආදායම් මාර්ග', _yesNo, _income.mainIncome, (val) {
          setState(() => _income = _income.copyWith(mainIncome: val!));
          vm.updateIncome(_income);
        }),
        _buildDropdown('අමතර ආදායම් මාර්ග', _yesNo, _income.additionalIncome, (val) {
          setState(() => _income = _income.copyWith(additionalIncome: val!));
          vm.updateIncome(_income);
        }),
        _buildDropdown('රැකියාව', _jobList, _income.job, (val) {
          setState(() => _income = _income.copyWith(job: val!));
          vm.updateIncome(_income);
        }),
        _buildDropdown('සංචාරක', _tourismList, _income.tourism, (val) {
          setState(() => _income = _income.copyWith(tourism: val!));
          vm.updateIncome(_income);
        }),
        _buildDropdown('කෘෂිකාර්මික', _agriList, _income.agriculture, (val) {
          setState(() => _income = _income.copyWith(agriculture: val!));
          vm.updateIncome(_income);
        }),
        _buildDropdown('සත්ත්ව කර්මාන්තය', _animalList, _income.animalHusbandry, (val) {
          setState(() => _income = _income.copyWith(animalHusbandry: val!));
          vm.updateIncome(_income);
        }),
        AppTextField(
          controller: TextEditingController(text: _income.animalCount)
            ..addListener(() {
              setState(() => _income = _income.copyWith(animalCount: (context as dynamic).text));
              vm.updateIncome(_income);
            }),
          label: 'සතුන් ගණන',
        ),
        _buildDropdown('ධීවර කර්මාන්තය', _fishingList, _income.fishingIndustry, (val) {
          setState(() => _income = _income.copyWith(fishingIndustry: val!));
          vm.updateIncome(_income);
        }),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          AppDropdown<String>(
            value: items.contains(value) ? value : items.first,
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}