import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import 'assets_view_model.dart';

class ImmovableAssetsScreen extends StatelessWidget {
  const ImmovableAssetsScreen({super.key});

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
          'දේපල හා වත්කම්',
          style: TextStyle(
            fontFamily: 'UNSamantha',
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ගොඩ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ගොඩ',
                  style: TextStyle(
                    fontFamily: 'UNSamantha',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      details.hasHighland ? 'ඇත' : 'නැත',
                      style: const TextStyle(
                        fontFamily: 'UNGanganee',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: details.hasHighland,
                      activeThumbColor: AppColors.danger,
                      onChanged: (val) => vm.updateField(hasHighland: val),
                    ),
                  ],
                ),
              ],
            ),
            if (details.hasHighland) ...[
              const SizedBox(height: 12),
              const Text(
                'මුළු ඉඩම් ප්‍රමාණය',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: details.highlandExtent,
                onChanged: (val) => vm.updateField(highlandExtent: val),
                decoration: _inputStyle(),
              ),
              const SizedBox(height: 16),
              const Text(
                'ඉඩමේ තත්ත්වය',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  const Text(
                    'වගා කර ඇත',
                    style: TextStyle(fontFamily: 'UNGanganee', fontSize: 14),
                  ),
                  Checkbox(
                    value: details.isHighlandCultivated,
                    activeColor: AppColors.textSecondary,
                    onChanged: (v) =>
                        vm.updateField(isHighlandCultivated: true),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    'වගා කර නැත',
                    style: TextStyle(fontFamily: 'UNGanganee', fontSize: 14),
                  ),
                  Checkbox(
                    value: !details.isHighlandCultivated,
                    activeColor: AppColors.textSecondary,
                    onChanged: (v) =>
                        vm.updateField(isHighlandCultivated: false),
                  ),
                ],
              ),
              if (!details.isHighlandCultivated) ...[
                const SizedBox(height: 16),
                const Text(
                  'වගා නොකළා නම් හේතුව',
                  style: TextStyle(
                    fontFamily: 'UNSamantha',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'ජලය නොමැත',
                      style: TextStyle(fontFamily: 'UNGanganee', fontSize: 13),
                    ),
                    Checkbox(
                      value: details.hlNoWater,
                      activeColor: AppColors.textSecondary,
                      onChanged: (v) => vm.updateField(hlNoWater: v),
                    ),
                    const Spacer(),
                    const Text(
                      'සත්ව හානි',
                      style: TextStyle(fontFamily: 'UNGanganee', fontSize: 13),
                    ),
                    Checkbox(
                      value: details.hlAnimalDamage,
                      activeColor: AppColors.textSecondary,
                      onChanged: (v) => vm.updateField(hlAnimalDamage: v),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'මුදල්/ශ්‍රමය',
                      style: TextStyle(fontFamily: 'UNGanganee', fontSize: 13),
                    ),
                    Checkbox(
                      value: details.hlMoneyLabor,
                      activeColor: AppColors.textSecondary,
                      onChanged: (v) => vm.updateField(hlMoneyLabor: v),
                    ),
                    const Spacer(),
                    const Text(
                      'වෙනත්',
                      style: TextStyle(fontFamily: 'UNGanganee', fontSize: 13),
                    ),
                    Checkbox(
                      value: details.hlOther,
                      activeColor: AppColors.textSecondary,
                      onChanged: (v) => vm.updateField(hlOther: v),
                    ),
                  ],
                ),
              ],
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: AppColors.textPrimary),
            ),

            // මඩ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'මඩ',
                  style: TextStyle(
                    fontFamily: 'UNSamantha',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      details.hasMudland ? 'ඇත' : 'නැත',
                      style: const TextStyle(
                        fontFamily: 'UNGanganee',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: details.hasMudland,
                      activeThumbColor: AppColors.danger,
                      onChanged: (val) => vm.updateField(hasMudland: val),
                    ),
                  ],
                ),
              ],
            ),
            if (details.hasMudland) ...[
              const SizedBox(height: 12),
              const Text(
                'මුළු ඉඩම් ප්‍රමාණය',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: details.mudlandExtent,
                onChanged: (val) => vm.updateField(mudlandExtent: val),
                decoration: _inputStyle(),
              ),
              const SizedBox(height: 16),
              const Text(
                'ඉඩමේ තත්ත්වය',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  const Text(
                    'වගා කර ඇත',
                    style: TextStyle(fontFamily: 'UNGanganee', fontSize: 14),
                  ),
                  Checkbox(
                    value: details.isMudlandCultivated,
                    activeColor: AppColors.textSecondary,
                    onChanged: (v) => vm.updateField(isMudlandCultivated: true),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    'වගා කර නැත',
                    style: TextStyle(fontFamily: 'UNGanganee', fontSize: 14),
                  ),
                  Checkbox(
                    value: !details.isMudlandCultivated,
                    activeColor: AppColors.textSecondary,
                    onChanged: (v) =>
                        vm.updateField(isMudlandCultivated: false),
                  ),
                ],
              ),
              if (!details.isMudlandCultivated) ...[
                const SizedBox(height: 16),
                const Text(
                  'වගා නොකළා නම් හේතුව',
                  style: TextStyle(
                    fontFamily: 'UNSamantha',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'ජලය නොමැත',
                      style: TextStyle(fontFamily: 'UNGanganee', fontSize: 13),
                    ),
                    Checkbox(
                      value: details.mlNoWater,
                      activeColor: AppColors.textSecondary,
                      onChanged: (v) => vm.updateField(mlNoWater: v),
                    ),
                    const Spacer(),
                    const Text(
                      'සත්ව හානි',
                      style: TextStyle(fontFamily: 'UNGanganee', fontSize: 13),
                    ),
                    Checkbox(
                      value: details.mlAnimalDamage,
                      activeColor: AppColors.textSecondary,
                      onChanged: (v) => vm.updateField(mlAnimalDamage: v),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'මුදල්/ශ්‍රමය',
                      style: TextStyle(fontFamily: 'UNGanganee', fontSize: 13),
                    ),
                    Checkbox(
                      value: details.mlMoneyLabor,
                      activeColor: AppColors.textSecondary,
                      onChanged: (v) => vm.updateField(mlMoneyLabor: v),
                    ),
                    const Spacer(),
                    const Text(
                      'උපකරණ',
                      style: TextStyle(fontFamily: 'UNGanganee', fontSize: 13),
                    ),
                    Checkbox(
                      value: details.mlEquipment,
                      activeColor: AppColors.textSecondary,
                      onChanged: (v) => vm.updateField(mlEquipment: v),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'පොහොර',
                      style: TextStyle(fontFamily: 'UNGanganee', fontSize: 13),
                    ),
                    Checkbox(
                      value: details.mlFertilizer,
                      activeColor: AppColors.textSecondary,
                      onChanged: (v) => vm.updateField(mlFertilizer: v),
                    ),
                    const Spacer(),
                    const Text(
                      'වෙනත්',
                      style: TextStyle(fontFamily: 'UNGanganee', fontSize: 13),
                    ),
                    Checkbox(
                      value: details.mlOther,
                      activeColor: AppColors.textSecondary,
                      onChanged: (v) => vm.updateField(mlOther: v),
                    ),
                  ],
                ),
              ],
            ],

            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: 200,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await vm.save();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    'ඊළඟ පිටුවට',
                    style: TextStyle(
                      fontFamily: 'UNSamantha',
                      fontSize: 24,
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputStyle() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.fieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
