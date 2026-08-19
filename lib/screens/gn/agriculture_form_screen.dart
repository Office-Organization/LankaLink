import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_screen.dart';
import 'agriculture_view_model.dart';
import 'map_selection_screen.dart'; // Import the new map screen

class AgricultureFormScreen extends StatelessWidget {
  const AgricultureFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AgricultureViewModel(),
      child: const _AgricultureFormView(),
    );
  }
}

class _AgricultureFormView extends StatefulWidget {
  const _AgricultureFormView();

  @override
  State<_AgricultureFormView> createState() => _AgricultureFormViewState();
}

class _AgricultureFormViewState extends State<_AgricultureFormView> {
  final _locationNameCtrl = TextEditingController();
  final _beneficiariesCtrl = TextEditingController();

  @override
  void dispose() {
    _locationNameCtrl.dispose();
    _beneficiariesCtrl.dispose();
    super.dispose();
  }

  void _handleSave(BuildContext context) async {
    final viewModel = context.read<AgricultureViewModel>();

    final success = await viewModel.saveDataAndProceed(
      locationName: _locationNameCtrl.text.trim(),
      beneficiariesCount: _beneficiariesCtrl.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('කෘෂිකර්මාන්ත තොරතුරු සාර්ථකව සුරකින ලදී.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  // UPDATED DIALOG LOGIC
  void _pickMapLocation(BuildContext context) {
    final viewModel = context.read<AgricultureViewModel>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'ස්ථානය ලකුණු කිරීම',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'GPS මගින් ඔබ සිටින ස්ථානය ලබා ගැනීම හෝ සිතියමෙන් ලකුණු කිරීම තෝරන්න.',
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Integrate Geolocator package here if you want live GPS fetching
              viewModel.setLocationCoordinates('6.9271° N, 79.8612° E (GPS)');
              Navigator.pop(ctx);
            },
            child: const Text(
              'GPS මගින්',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog

              // Navigate to Map Selection Screen and wait for the result
              final selectedCoordinates = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MapSelectionScreen(),
                ),
              );

              if (selectedCoordinates != null && mounted) {
                viewModel.setLocationCoordinates(selectedCoordinates);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'සිතියමෙන් තෝරන්න',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AgricultureViewModel>();

    return AppScreen(
      title: 'කෘෂිකර්මාන්තය',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '02. කෘෂිකර්මාන්තය',
                  style: TextStyle(
                    fontFamily: 'UNSamantha',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'කෘෂිකාර්මික සංවර්ධන කටයුතු පිළිබඳ විස්තර මෙහි ඇතුළත් කරන්න.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 24),

                // 1. Category Dropdown
                _buildDropdownField(
                  label: 'සංවර්ධන කටයුත්ත අවශ්‍ය වර්ගය තෝරන්න:',
                  hint: 'තෝරන්න',
                  value: viewModel.selectedDevelopmentCategory,
                  items: viewModel.developmentCategories,
                  onChanged: (val) => viewModel.updateDevelopmentCategory(val),
                ),
                const SizedBox(height: 20),

                // 2. Development Type Dropdown
                _buildDropdownField(
                  label: 'අවශ්‍ය සංවර්ධන වර්ගය තෝරන්න:',
                  hint: 'ප්‍රතිසංස්කරණය / නව ඉදිකිරීම',
                  value: viewModel.selectedDevelopmentType,
                  items: viewModel.developmentTypes,
                  onChanged: (val) => viewModel.updateDevelopmentType(val),
                ),
                const SizedBox(height: 20),

                // 3. Location Name Input
                _buildInputField(
                  label: 'අවශ්‍ය ස්ථානයේ නම:',
                  hint: 'ස්ථානයේ නම ඇතුළත් කරන්න',
                  controller: _locationNameCtrl,
                ),
                const SizedBox(height: 20),

                // 4. Map Point Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'අවශ්‍ය ස්ථානය ලකුණු කරන්න:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickMapLocation(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: viewModel.selectedLocationCoordinates != null
                                ? Colors.blue
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color:
                                  viewModel.selectedLocationCoordinates != null
                                  ? Colors.blue
                                  : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              viewModel.selectedLocationCoordinates ??
                                  'Map Point තෝරන්න',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    viewModel.selectedLocationCoordinates !=
                                        null
                                    ? Colors.blue
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 5. Beneficiaries Count Input
                _buildInputField(
                  label: 'ප්‍රතිලාභීන් ගණන:',
                  hint: '0000',
                  controller: _beneficiariesCtrl,
                  isNumber: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Bottom Action Button
          ElevatedButton(
            onPressed: viewModel.isSaving ? null : () => _handleSave(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: viewModel.isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'තොරතුරු සුරකින්න',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Card Helper
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // Input Field Helper
  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // Dropdown Field Helper
  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
