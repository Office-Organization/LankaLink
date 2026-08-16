import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import 'housing_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_screen.dart';

class HousingScreen extends StatelessWidget {
  const HousingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HousingViewModel>();
    final details = vm.details;

    return AppScreen(
      title: 'පදිංචිය හා නිවාස',
      child: vm.isBusy
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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

                  const SizedBox(height: 10),
                  _buildLabel('නිවසක් තිබේද'),
                  Row(
                    children: [
                      const Text(
                        'ඇත',
                        style: TextStyle(
                          fontFamily: 'UNGanganee',
                          fontSize: 16,
                        ),
                      ),
                      Radio<bool>(
                        value: true,
                        groupValue: details.hasHouse,
                        activeColor: AppColors.primary,
                        onChanged: (val) => vm.updateField(hasHouse: val),
                      ),
                      const SizedBox(width: 20),
                      const Text(
                        'නැත',
                        style: TextStyle(
                          fontFamily: 'UNGanganee',
                          fontSize: 16,
                        ),
                      ),
                      Radio<bool>(
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
                    items: [
                      'මහල් නිවාස (ෆ්ලැට්)',
                      'ස්ථිර තනි',
                      'අර්ධ ස්ථිර',
                      'තාවකාලික',
                    ],
                    onChanged: (val) => vm.updateField(nature: val),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('සනීපාරක්ෂක පහසුකම්'),
                  _buildDropdown(
                    value: details.sanitation,
                    items: ['ජල මුද්රිත', 'වල'],
                    onChanged: (val) => vm.updateField(sanitation: val),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('විදුලිය'),
                  _buildDropdown(
                    value: details.electricity,
                    items: ['ඇත', 'නැත'],
                    onChanged: (val) => vm.updateField(electricity: val),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('ජලය'),
                  _buildDropdown(
                    value: details.water,
                    items: [
                      'වෝටර් බෝඩ්',
                      'ආරක්ෂිත ළිං',
                      'අනාරක්ෂිත ළිං',
                      'ප්රජා ජල ව්යාපෘත',
                    ],
                    onChanged: (val) => vm.updateField(water: val),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('සන්නිවේදන පහසුකම්'),
                  Row(
                    children: [
                      const Text(
                        'දුරකථන',
                        style: TextStyle(
                          fontFamily: 'UNGanganee',
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Text(
                        'ස්ථාවර',
                        style: TextStyle(
                          fontFamily: 'UNGanganee',
                          fontSize: 16,
                        ),
                      ),
                      Checkbox(
                        value: details.hasFixedPhone ?? false,
                        activeColor: AppColors.primary,
                        onChanged: (val) => vm.updateField(hasFixedPhone: val),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'ජංගම',
                        style: TextStyle(
                          fontFamily: 'UNGanganee',
                          fontSize: 16,
                        ),
                      ),
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
                    items: ['3G', '4G', '5G', 'නැත'],
                    onChanged: (val) => vm.updateField(signal: val),
                  ),
                  const SizedBox(height: 40),

                  AppButton(
                    label: 'ඊළඟ පිටුවට',
                    isLoading: vm.isBusy,
                    onPressed: () async {
                      final success = await vm.save();
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('දත්ත සාර්ථකව සුරැකිණි!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        Navigator.pushNamed(
                          context,
                          Routes.income,
                          arguments: vm.houseNumber,
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

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    // Ensure the value exists in the items list to prevent assertion errors.
    // If not, default to the first item.
    String dropdownValue = (value != null && items.contains(value))
        ? value
        : items.first;

    // If the original value was invalid, schedule a state update to sync the view model.
    if (value != dropdownValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChanged(dropdownValue);
      });
    }

    return InputDecorator(
      decoration: const InputDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dropdownValue,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
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
        ),
      ),
    );
  }
}
