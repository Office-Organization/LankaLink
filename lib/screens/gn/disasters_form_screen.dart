import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_screen.dart';
import 'disasters_view_model.dart';
import 'map_selection_screen.dart';

class DisastersFormScreen extends StatelessWidget {
  const DisastersFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DisastersViewModel(),
      child: const _DisastersFormView(),
    );
  }
}

class _DisastersFormView extends StatefulWidget {
  const _DisastersFormView();

  @override
  State<_DisastersFormView> createState() => _DisastersFormViewState();
}

class _DisastersFormViewState extends State<_DisastersFormView> {
  void _handleFinish(BuildContext context) async {
    final viewModel = context.read<DisastersViewModel>();

    final success = await viewModel.finishAndSave();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('සියලුම තොරතුරු සාර්ථකව සුරකින ලදී!'), // "All info saved successfully"
          backgroundColor: Colors.green,
        ),
      );
      
      // Pop back to the first screen/home screen since this is the final step
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _pickMapLocation(BuildContext context) {
    final viewModel = context.read<DisastersViewModel>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ස්ථානය ලකුණු කිරීම', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: const Text('GPS මගින් ඔබ සිටින ස්ථානය ලබා ගැනීම හෝ සිතියමෙන් ලකුණු කිරීම තෝරන්න.'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () {
              viewModel.setLocationCoordinates('6.9271° N, 79.8612° E (GPS)');
              Navigator.pop(ctx);
            },
            child: const Text('GPS මගින්', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final selectedCoordinates = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapSelectionScreen()),
              );

              if (selectedCoordinates != null && mounted) {
                viewModel.setLocationCoordinates(selectedCoordinates);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('සිතියමෙන් තෝරන්න', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DisastersViewModel>();

    return AppScreen(
      title: 'ආපදා තොරතුරු',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '09. ආපදා තොරතුරු',
                  style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                ),
                const SizedBox(height: 24),

                // Disaster Type Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ආපදා වර්ගය තෝරන්න:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: viewModel.selectedDisasterType,
                      hint: Text('තෝරන්න', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
                      ),
                      items: viewModel.disasterTypes.map((String item) {
                        return DropdownMenuItem<String>(value: item, child: Text(item));
                      }).toList(),
                      onChanged: (val) => viewModel.updateDisasterType(val),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Affected Area Map Point
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'මෙමගින් පීඩාවට පත්වන ප්‍රදේශය සලකුණු කරන්න:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickMapLocation(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: viewModel.selectedLocationCoordinates != null ? Colors.blue : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: viewModel.selectedLocationCoordinates != null ? Colors.blue : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              viewModel.selectedLocationCoordinates ?? 'Google map',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: viewModel.selectedLocationCoordinates != null ? Colors.blue : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // "හරි" (OK) Final Button
          ElevatedButton(
            onPressed: viewModel.isSaving ? null : () => _handleFinish(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // Differentiated color for the final 'OK' button
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: viewModel.isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('හරි', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
