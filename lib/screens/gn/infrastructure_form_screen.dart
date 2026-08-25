import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_screen.dart';
import 'infrastructure_view_model.dart';
import 'agriculture_form_screen.dart';

class InfrastructureFormScreen extends StatelessWidget {
  const InfrastructureFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InfrastructureViewModel(),
      child: const _InfrastructureFormView(),
    );
  }
}

class _InfrastructureFormView extends StatefulWidget {
  const _InfrastructureFormView();

  @override
  State<_InfrastructureFormView> createState() =>
      _InfrastructureFormViewState();
}

class _InfrastructureFormViewState extends State<_InfrastructureFormView> {
  // Controllers for road details
  final _roadNameCtrl = TextEditingController();
  final _roadDistanceCtrl = TextEditingController();
  final _roadBeneficiariesCtrl = TextEditingController();

  // Controllers for bridge details
  final _bridgeNameCtrl = TextEditingController();
  final _bridgeConditionCtrl = TextEditingController();
  final _bridgeBeneficiariesCtrl = TextEditingController();

  @override
  void dispose() {
    _roadNameCtrl.dispose();
    _roadDistanceCtrl.dispose();
    _roadBeneficiariesCtrl.dispose();
    _bridgeNameCtrl.dispose();
    _bridgeConditionCtrl.dispose();
    _bridgeBeneficiariesCtrl.dispose();
    super.dispose();
  }

  void _handleSave(BuildContext context) async {
    final viewModel = context.read<InfrastructureViewModel>();

    final success = await viewModel.saveDataAndProceed(
      roadName: _roadNameCtrl.text.trim(),
      roadDistance: _roadDistanceCtrl.text.trim(),
      roadBeneficiaries: _roadBeneficiariesCtrl.text.trim(),
      bridgeName: _bridgeNameCtrl.text.trim(),
      bridgeCondition: _bridgeConditionCtrl.text.trim(),
      bridgeBeneficiaries: _bridgeBeneficiariesCtrl.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('යටිතල පහසුකම් තොරතුරු සාර්ථකව සුරකින ලදී.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AgricultureFormScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InfrastructureViewModel>();

    return AppScreen(
      title: 'යටිතල පහසුකම්',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          // Roads Section
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '01. මාර්ග සංවර්ධනය',
                  style: TextStyle(
                    fontFamily: 'UNSamantha',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'මාර්ග සංවර්ධන කටයුතු පිළිබඳ විස්තර මෙහි ඇතුළත් කරන්න.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                _buildInputField(
                  label: 'මාර්ගයේ නම:',
                  hint: 'මාර්ගයේ නම ඇතුළත් කරන්න',
                  controller: _roadNameCtrl,
                ),
                const SizedBox(height: 20),
                _buildDropdownField(
                  label: 'මාර්ග වර්ගය:',
                  hint: 'තෝරන්න',
                  value: viewModel.selectedRoadType,
                  items: viewModel.roadTypes,
                  onChanged: (val) => viewModel.updateRoadType(val),
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'සංවර්ධනය කළ යුතු දුර (km):',
                  hint: '0.0',
                  controller: _roadDistanceCtrl,
                  isNumber: true,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'ප්‍රතිලාභීන් ගණන:',
                  hint: '0000',
                  controller: _roadBeneficiariesCtrl,
                  isNumber: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bridges Section
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '02. පාලම් හා බෝක්කු',
                  style: TextStyle(
                    fontFamily: 'UNSamantha',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'පාලම් හා බෝක්කු සංවර්ධනය පිළිබඳ විස්තර මෙහි ඇතුළත් කරන්න.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                _buildInputField(
                  label: 'පාලම/බෝක්කුවේ නම:',
                  hint: 'නම ඇතුළත් කරන්න',
                  controller: _bridgeNameCtrl,
                ),
                const SizedBox(height: 20),
                _buildDropdownField(
                  label: 'වර්ගය:',
                  hint: 'තෝරන්න',
                  value: viewModel.selectedBridgeType,
                  items: viewModel.bridgeTypes,
                  onChanged: (val) => viewModel.updateBridgeType(val),
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'වර්තමාන තත්ත්වය:',
                  hint: 'තත්ත්වය පිළිබඳ විස්තරයක්',
                  controller: _bridgeConditionCtrl,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'ප්‍රතිලාභීන් ගණන:',
                  hint: '0000',
                  controller: _bridgeBeneficiariesCtrl,
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
