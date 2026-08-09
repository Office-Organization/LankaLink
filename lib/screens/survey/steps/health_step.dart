import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/health.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/app_check_option.dart';
import '../survey_view_model.dart';

class HealthStep extends StatefulWidget {
  const HealthStep({super.key});

  @override
  State<HealthStep> createState() => _HealthStepState();
}

class _HealthStepState extends State<HealthStep> {
  late HealthInfo _health;

  @override
  void initState() {
    super.initState();
    final vm = context.read<SurveyViewModel>();
    _health = vm.survey?.health ?? const HealthInfo();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SurveyViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCheckRow('ප්‍රධාන ආබාධ මාර්ග', _health.hasMainDisability, (val) {
          setState(() => _health = _health.copyWith(hasMainDisability: val));
          vm.updateHealth(_health);
        }),
        _buildCheckRow('අනෙකුත් ආබාධ මාර්ග', _health.otherDisability, (val) {
          setState(() => _health = _health.copyWith(otherDisability: val));
          vm.updateHealth(_health);
        }),
        AppTextField(
          controller: TextEditingController(text: _health.diseases)
            ..addListener(() {
              setState(() => _health = _health.copyWith(diseases: (context as dynamic).text));
              vm.updateHealth(_health);
            }),
          label: 'රෝගී',
        ),
        AppTextField(
          controller: TextEditingController(text: _health.careType)
            ..addListener(() {
              setState(() => _health = _health.copyWith(careType: (context as dynamic).text));
              vm.updateHealth(_health);
            }),
          label: 'සාත්තු',
        ),
        AppTextField(
          controller: TextEditingController(text: _health.medicalTreatment)
            ..addListener(() {
              setState(() => _health = _health.copyWith(medicalTreatment: (context as dynamic).text));
              vm.updateHealth(_health);
            }),
          label: 'වෛද්‍ය ප්‍රතිකාර',
        ),
        AppTextField(
          controller: TextEditingController(text: _health.prevention)
            ..addListener(() {
              setState(() => _health = _health.copyWith(prevention: (context as dynamic).text));
              vm.updateHealth(_health);
            }),
          label: 'නිවාරණ',
        ),
        AppTextField(
          controller: TextEditingController(text: _health.medicalCheckup)
            ..addListener(() {
              setState(() => _health = _health.copyWith(medicalCheckup: (context as dynamic).text));
              vm.updateHealth(_health);
            }),
          label: 'වෛද්‍ය පරීක්ෂාව',
        ),
        AppTextField(
          controller: TextEditingController(text: _health.nutrition)
            ..addListener(() {
              setState(() => _health = _health.copyWith(nutrition: (context as dynamic).text));
              vm.updateHealth(_health);
            }),
          label: 'පෝෂණ',
        ),
        _buildRadioRow('බීම', _health.drinks, ['පානය කරන', 'පානය නොකරන'], (val) {
          setState(() => _health = _health.copyWith(drinks: val!));
          vm.updateHealth(_health);
        }),
        _buildRadioRow('කිරි', _health.milk, ['බොන', 'බොන්නේ නැත'], (val) {
          setState(() => _health = _health.copyWith(milk: val!));
          vm.updateHealth(_health);
        }),
        _buildRadioRow('මත්පැන්', _health.alcohol, ['පානය කරන', 'පානය නොකරන'], (val) {
          setState(() => _health = _health.copyWith(alcohol: val!));
          vm.updateHealth(_health);
        }),
      ],
    );
  }

  Widget _buildCheckRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 16),
          AppCheckOption(
            label: 'ඇත',
            selected: value,
            onTap: () => onChanged(true),
          ),
          const SizedBox(width: 16),
          AppCheckOption(
            label: 'නැත',
            selected: !value,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioRow(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 16),
          ...options.map((opt) {
            return Row(
              children: [
                AppCheckOption(
                  label: opt,
                  selected: value == opt,
                  onTap: () => onChanged(opt),
                ),
                const SizedBox(width: 16),
              ],
            );
          }),
        ],
      ),
    );
  }
}