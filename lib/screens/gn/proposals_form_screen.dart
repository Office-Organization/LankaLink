import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_screen.dart';
import 'proposals_view_model.dart';
import 'disasters_form_screen.dart'; // Routes to Section 09

class ProposalsFormScreen extends StatelessWidget {
  const ProposalsFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProposalsViewModel(),
      child: const _ProposalsFormView(),
    );
  }
}

class _ProposalsFormView extends StatefulWidget {
  const _ProposalsFormView();

  @override
  State<_ProposalsFormView> createState() => _ProposalsFormViewState();
}

class _ProposalsFormViewState extends State<_ProposalsFormView> {
  final _projectCtrl = TextEditingController();
  final _beneficiariesCtrl = TextEditingController();

  @override
  void dispose() {
    _projectCtrl.dispose();
    _beneficiariesCtrl.dispose();
    super.dispose();
  }

  void _handleSave(BuildContext context) async {
    final viewModel = context.read<ProposalsViewModel>();

    final success = await viewModel.saveDataAndProceed(
      proposedProject: _projectCtrl.text.trim(),
      beneficiariesCount: _beneficiariesCtrl.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('යෝජනා තොරතුරු සාර්ථකව සුරකින ලදී.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DisastersFormScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProposalsViewModel>();

    return AppScreen(
      title: 'යෝජනා',
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
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '08. යෝජනා',
                  style: TextStyle(
                    fontFamily: 'UNSamantha',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                _buildInputField(
                  label: 'යෝජිත සංවර්ධන ව්‍යාපෘතිය ඇතුලත් කරන්න:',
                  hint: 'ව්‍යාපෘතියේ නම / විස්තරය',
                  controller: _projectCtrl,
                ),
                const SizedBox(height: 20),

                _buildInputField(
                  label: 'මෙමගින් ප්‍රතිලාභ ලබන්නන් ගණන ආසන්නව:',
                  hint: '0000000',
                  controller: _beneficiariesCtrl,
                  isNumber: true,
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
        ],
      ),
    );
  }

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
}
