import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import 'housing_view_model.dart';

class HousingScreen extends StatelessWidget {
  const HousingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HousingViewModel>();
    final details = vm.details;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.lightBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('පදිංචිය හා නිවාස', style: TextStyle(fontFamily: 'UNSamantha', color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
      ),
      body: vm.isBusy 
        ? const Center(child: CircularProgressIndicator(color: Colors.lightBlue))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vm.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    color: Colors.red.shade100,
                    width: double.infinity,
                    child: Text(vm.error!, style: const TextStyle(color: Colors.red, fontFamily: 'UNGanganee')),
                  ),
                
                const SizedBox(height: 10),
                _buildLabel('නිවසක් තිබේද'),
                Row(
                  children: [
                    const Text('ඇත', style: TextStyle(fontFamily: 'UNGanganee', fontSize: 16)),
                    Checkbox(
                      value: details.hasHouse, 
                      activeColor: Colors.black87,
                      onChanged: (val) => vm.updateField(hasHouse: true)
                    ),
                    const SizedBox(width: 20),
                    const Text('නැත', style: TextStyle(fontFamily: 'UNGanganee', fontSize: 16)),
                    Checkbox(
                      value: !details.hasHouse, 
                      activeColor: Colors.black87,
                      onChanged: (val) => vm.updateField(hasHouse: false)
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildLabel('ස්වභාවය'),
                _buildDropdown(
                  value: details.nature,
                  items: ['මහල් නිවාස (ෆ්ලැට්)', 'ස්ථිර තනි', 'අර්ධ ස්ථිර', 'තාවකාලික'],
                  onChanged: (val) => vm.updateField(nature: val),
                ),
                const SizedBox(height: 16),

                _buildLabel('සනීපාරක්ෂක පහසුකම්'),
                _buildDropdown(
                  value: details.sanitation,
                  items: ['ජල මුද්‍රිත', 'වල'],
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
                  items: ['වෝටර් බෝඩ්', 'ආරක්ෂිත ළිං', 'අනාරක්ෂිත ළිං', 'ප්‍රජා ජල ව්‍යාපෘත'],
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
                      value: details.hasFixedPhone, 
                      activeColor: Colors.black87,
                      onChanged: (val) => vm.updateField(hasFixedPhone: val)
                    ),
                    const SizedBox(width: 10),
                    const Text('ජංගම', style: TextStyle(fontFamily: 'UNGanganee', fontSize: 16)),
                    Checkbox(
                      value: details.hasMobilePhone, 
                      activeColor: Colors.black87,
                      onChanged: (val) => vm.updateField(hasMobilePhone: val)
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

                Center(
                  child: SizedBox(
                    width: 200,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF56B4F8), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final success = await vm.save();
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('දත්ත සාර්ථකව සුරැකිණි!')),
                          );
                          Navigator.pushNamed(
                            context, 
                            Routes.income, 
                            arguments: vm.houseNumber,
                          );
                        }
                      },
                      child: const Text('ඊළඟ පිටුවට', style: TextStyle(fontFamily: 'UNSamantha', fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
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
      child: Text(text, style: const TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required Function(String?) onChanged}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.lightBlue.shade200, width: 1.5), 
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          items: items.map((String item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(fontFamily: 'UNGanganee', fontSize: 16)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}