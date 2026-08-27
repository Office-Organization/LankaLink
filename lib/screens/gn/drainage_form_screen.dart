import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_screen.dart'; // Adjust path if necessary based on your folder structure
import 'drainage_view_model.dart';
import 'tourist_attractions_form_screen.dart'; // Added import for the next screen

class DrainageFormScreen extends StatelessWidget {
  const DrainageFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DrainageViewModel(),
      child: const _DrainageFormView(),
    );
  }
}

class _DrainageFormView extends StatefulWidget {
  const _DrainageFormView();

  @override
  State<_DrainageFormView> createState() => _DrainageFormViewState();
}

class _DrainageFormViewState extends State<_DrainageFormView> {
  // Controllers for the 4 input fields from the sketch
  final _locationNameCtrl = TextEditingController();
  final _developmentAmountCtrl = TextEditingController();
  final _currentConditionCtrl = TextEditingController();
  final _beneficiariesCtrl = TextEditingController();

  @override
  void dispose() {
    _locationNameCtrl.dispose();
    _developmentAmountCtrl.dispose();
    _currentConditionCtrl.dispose();
    _beneficiariesCtrl.dispose();
    super.dispose();
  }

  void _handleSave(BuildContext context) async {
    final viewModel = context.read<DrainageViewModel>();

    final success = await viewModel.saveDataAndProceed(
      locationName: _locationNameCtrl.text.trim(),
      developmentAmount: _developmentAmountCtrl.text.trim(),
      currentCondition: _currentConditionCtrl.text.trim(),
      beneficiariesCount: _beneficiariesCtrl.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ජලාපවහන පද්ධති තොරතුරු සාර්ථකව සුරකින ලදී.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigating directly to the Tourist Attractions page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TouristAttractionsFormScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DrainageViewModel>();

    return AppScreen(
      title: 'ජලාපවහන පද්ධති',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Section 5)
                const Text(
                  '05. ජලාපවහන පද්ධති',
                  style: TextStyle(
                    fontFamily: 'UNSamantha', // Matching your existing font
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'සංවර්ධනය කළ යුතු ස්ථානය පිළිබඳ විස්තර ඇතුළත් කරන්න.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 24),

                // 1. Location Name Input
                _buildInputField(
                  label: 'ස්ථානයෙහි නම:',
                  hint: 'ස්ථානයේ නම',
                  controller: _locationNameCtrl,
                ),
                const SizedBox(height: 20),

                // 2. Approximate Development Amount Input
                _buildInputField(
                  label: 'සංවර්ධනය කළයුතු ප්‍රමාණය ආසන්න වශයෙන්:',
                  hint: '00000 000',
                  controller: _developmentAmountCtrl,
                  isNumber: true, // Shows numeric keyboard
                ),
                const SizedBox(height: 20),

                // 3. Current Condition Input
                _buildInputField(
                  label: 'දැනට පවතින තත්වය:',
                  hint: 'දැනට පවතින තත්වය',
                  controller: _currentConditionCtrl,
                ),
                const SizedBox(height: 20),

                // 4. Approximate Beneficiaries Input
                _buildInputField(
                  label: 'ප්‍රතිලාභීන් ගණන ආසන්නව:',
                  hint: '0000 0000',
                  controller: _beneficiariesCtrl,
                  isNumber: true, // Shows numeric keyboard
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Bottom Action Button (Next Page)
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

  // Helper method for the white card background
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

  // Helper method for standard text inputs
  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isNumber = false,
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
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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