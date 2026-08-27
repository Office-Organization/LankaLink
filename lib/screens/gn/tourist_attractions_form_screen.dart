import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_screen.dart';
import 'tourist_attractions_view_model.dart';
import 'map_selection_screen.dart';
import 'proposals_form_screen.dart'; // <-- Added import for the next screen (Section 08)

class TouristAttractionsFormScreen extends StatelessWidget {
  const TouristAttractionsFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TouristAttractionsViewModel(),
      child: const _TouristAttractionsFormView(),
    );
  }
}

class _TouristAttractionsFormView extends StatefulWidget {
  const _TouristAttractionsFormView();

  @override
  State<_TouristAttractionsFormView> createState() =>
      _TouristAttractionsFormViewState();
}

class _TouristAttractionsFormViewState extends State<_TouristAttractionsFormView> {
  final _locationNameCtrl = TextEditingController();
  final _developmentNeedsCtrl = TextEditingController();

  @override
  void dispose() {
    _locationNameCtrl.dispose();
    _developmentNeedsCtrl.dispose();
    super.dispose();
  }

  void _handleSave(BuildContext context) async {
    final viewModel = context.read<TouristAttractionsViewModel>();

    final success = await viewModel.saveDataAndProceed(
      locationName: _locationNameCtrl.text.trim(),
      developmentNeeds: _developmentNeedsCtrl.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('සංචාරක ආකර්ෂණ ස්ථාන තොරතුරු සාර්ථකව සුරකින ලදී.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // <-- Navigation to Section 08
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProposalsFormScreen(),
        ),
      );
    }
  }

  void _pickMapLocation(BuildContext context) {
    final viewModel = context.read<TouristAttractionsViewModel>();

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
              Navigator.pop(ctx);
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
    final viewModel = context.watch<TouristAttractionsViewModel>();

    return AppScreen(
      title: 'සංචාරක ආකර්ෂණ ස්ථාන',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '07. සංචාරක ආකර්ෂණ ස්ථාන',
                  style: TextStyle(
                    fontFamily: 'UNSamantha',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'එවැනි ස්ථානයක් මෙහි දක්වන්න:',
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
                                  'Google map point',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    viewModel.selectedLocationCoordinates != null
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

                _buildInputField(
                  label: 'ස්ථානයේ නම:',
                  hint: 'ස්ථානයේ නම ඇතුලත් කරන්න',
                  controller: _locationNameCtrl,
                ),
                const SizedBox(height: 20),

                _buildInputField(
                  label: 'සංවර්ධනය වියයුතු තැන්:',
                  hint: 'විස්තරය ඇතුලත් කරන්න...',
                  controller: _developmentNeedsCtrl,
                  maxLines: 4, 
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

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
                    'ඊළඟ පිටුවට',
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

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: maxLines > 1 ? TextInputType.multiline : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
}