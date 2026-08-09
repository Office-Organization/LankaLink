import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_strings.dart';
import '../../../models/housing.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/app_check_option.dart';
import '../../../widgets/app_dropdown.dart';
import '../survey_view_model.dart';

class HousingStep extends StatefulWidget {
  const HousingStep({super.key});

  @override
  State<HousingStep> createState() => _HousingStepState();
}

class _HousingStepState extends State<HousingStep> {
  late HousingInfo _housing;

  @override
  void initState() {
    super.initState();
    final vm = context.read<SurveyViewModel>();
    _housing = vm.survey?.housing ?? const HousingInfo();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SurveyViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCheckRow('නිවාස හිමිකම', _housing.houseOwnership, (val) {
          setState(() => _housing = _housing.copyWith(houseOwnership: val));
          vm.updateHousing(_housing);
        }),
        AppTextField(
          controller: TextEditingController(text: _housing.houseName)
            ..addListener(() {
              _housing = _housing.copyWith(houseName: (context as dynamic).text);
              vm.updateHousing(_housing);
            }),
          label: 'ස්ථානය',
        ),
        _buildCheckRow('විදුලිය', _housing.electricity, (val) {
          setState(() => _housing = _housing.copyWith(electricity: val));
          vm.updateHousing(_housing);
        }),
        _buildCheckRow('ජලය', _housing.water, (val) {
          setState(() => _housing = _housing.copyWith(water: val));
          vm.updateHousing(_housing);
        }),
        AppTextField(
          controller: TextEditingController(text: _housing.houseType)
            ..addListener(() {
              _housing = _housing.copyWith(houseType: (context as dynamic).text);
              vm.updateHousing(_housing);
            }),
          label: 'නිවාස වර්ගය',
        ),
        _buildCheckRow('නිවාස පහසුකම්', _housing.housingFacilities, (val) {
          setState(() => _housing = _housing.copyWith(housingFacilities: val));
          vm.updateHousing(_housing);
        }),
        AppDropdown<String>(
          value: _housing.mobileNetwork,
          items: ['3G', '4G', '5G', 'නැත'],
          onChanged: (val) {
            setState(() => _housing = _housing.copyWith(mobileNetwork: val!));
            vm.updateHousing(_housing);
          },
        ),
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
            label: AppStrings.yes,
            selected: value,
            onTap: () => onChanged(true),
          ),
          const SizedBox(width: 16),
          AppCheckOption(
            label: AppStrings.no,
            selected: !value,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}