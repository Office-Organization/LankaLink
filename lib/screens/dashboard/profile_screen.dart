
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_view_model.dart';
import '../../widgets/app_screen.dart'; // Adjust path based on your architecture

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog(BuildContext context, ProfileViewModel vm) {
    final passCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isObscure = true;
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('මුරපදය වෙනස් කරන්න (Change Password)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: passCtrl,
                  obscureText: isObscure,
                  decoration: const InputDecoration(
                    labelText: 'නව මුරපදය (New Password)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: isObscure,
                  decoration: const InputDecoration(
                    labelText: 'නව මුරපදය තහවුරු කරන්න (Confirm)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: !isObscure,
                      onChanged: (val) {
                        setDialogState(() => isObscure = !(val ?? false));
                      },
                    ),
                    const Text('මුරපදය පෙන්වන්න (Show password)', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                child: const Text('අවලංගු කරන්න (Cancel)', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: isProcessing ? null : () async {
                  if (passCtrl.text.trim().length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('මුරපදය අකුරු 6 කට වඩා වැඩි විය යුතුය!'), backgroundColor: Colors.red));
                    return;
                  }
                  if (passCtrl.text.trim() != confirmPassCtrl.text.trim()) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('මුරපදයන් නොගැලපේ!'), backgroundColor: Colors.red));
                    return;
                  }

                  setDialogState(() => isProcessing = true);
                  
                  final error = await vm.changePassword(passCtrl.text.trim());
                  
                  if (!context.mounted) return;
                  
                  if (error == null) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('මුරපදය සාර්ථකව වෙනස් කරන ලදී!'), backgroundColor: Colors.green));
                  } else {
                    setDialogState(() => isProcessing = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
                  }
                },
                child: isProcessing 
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('සුරකින්න (Save)', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();

    // Initialize controllers once data is loaded
    if (!viewModel.isLoading && !_controllersInitialized) {
      _nameCtrl.text = viewModel.name ?? '';
      _phoneCtrl.text = viewModel.phone ?? '';
      _controllersInitialized = true;
    }

    return AppScreen(
      title: 'මගේ ගිණුම (My Profile)',
      child: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  // Role Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        'Role: ${(viewModel.role ?? 'User').toUpperCase()}',
                        style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ප්‍රධාන තොරතුරු (Primary Information)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                        const SizedBox(height: 20),
                        
                        // NON-EDITABLE FIELDS
                        _buildNonEditableField(label: 'ජාතික හැඳුනුම්පත (NIC)', value: viewModel.nic ?? 'N/A', icon: Icons.badge_outlined),
                        const SizedBox(height: 16),
                        _buildNonEditableField(label: 'විද්‍යුත් තැපෑල (Email)', value: viewModel.email ?? 'N/A', icon: Icons.email_outlined),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 20),

                        const Text('වෙනස් කළ හැකි තොරතුරු (Editable Information)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 20),

                        // EDITABLE FIELDS
                        _buildEditableField(label: 'නම (Full Name)', controller: _nameCtrl, icon: Icons.person_outline),
                        const SizedBox(height: 16),
                        _buildEditableField(label: 'දුරකථන අංකය (Mobile No)', controller: _phoneCtrl, icon: Icons.phone_outlined, isPhone: true),
                        const SizedBox(height: 24),

                        // LOCATION FIELDS
                        const Text('ඔබගේ වසම (Assigned Location)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                        const SizedBox(height: 12),

                        // Local Authority Dropdown
                        DropdownButtonFormField<String>(
                          value: viewModel.selectedAuthorityId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'පළාත් පාලන ආයතනය (Local Authority)',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          ),
                          items: viewModel.authoritiesList.map((auth) {
                            final nameEn = auth['name_en'] ?? 'Unknown';
                            final nameSi = auth['name_si']?.toString() ?? '';
                            final displayName = nameSi.isNotEmpty ? '$nameSi ($nameEn)' : nameEn;
                            return DropdownMenuItem<String>(value: auth['id'], child: Text(displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)));
                          }).toList(),
                          onChanged: (val) => viewModel.onAuthorityChanged(val),
                        ),
                        const SizedBox(height: 16),

                        // GN Division Dropdown
                        DropdownButtonFormField<String>(
                          value: viewModel.gnDivision,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'ග්‍රාම නිලධාරී වසම (GN Division)',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          ),
                          items: viewModel.currentGNDivisionsList.map((gn) {
                            final gnNameEn = gn['en']?.toString() ?? 'Unknown'; 
                            final gnNameSi = gn['si']?.toString() ?? '';
                            final displayGnName = gnNameSi.isNotEmpty ? '$gnNameSi ($gnNameEn)' : gnNameEn;
                            return DropdownMenuItem<String>(value: gnNameEn, child: Text(displayGnName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)));
                          }).toList(),
                          onChanged: (val) => viewModel.onGnDivisionChanged(val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CHANGE PASSWORD BUTTON
                  OutlinedButton.icon(
                    onPressed: () => _showChangePasswordDialog(context, viewModel),
                    icon: const Icon(Icons.lock_reset_rounded, color: Colors.blue),
                    label: const Text('මුරපදය වෙනස් කරන්න (Change Password)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.blue, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SAVE CHANGES BUTTON
                  ElevatedButton.icon(
                    onPressed: viewModel.isSaving ? null : () async {
                      if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty || viewModel.gnDivision == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('කරුණාකර සියලුම දත්ත ඇතුලත් කරන්න.'), backgroundColor: Colors.red));
                        return;
                      }

                      final success = await viewModel.updateProfileData(
                        newName: _nameCtrl.text.trim(),
                        newPhone: _phoneCtrl.text.trim(),
                      );

                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ගිණුමේ තොරතුරු සාර්ථකව යාවත්කාලීන කරන ලදී!'), backgroundColor: Colors.green));
                        Navigator.pop(context); // Go back to dashboard on success
                      }
                    },
                    icon: viewModel.isSaving ? const SizedBox.shrink() : const Icon(Icons.save_rounded, color: Colors.white),
                    label: viewModel.isSaving 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('වෙනස්කම් සුරකින්න (Save Changes)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildNonEditableField({required String label, required String value, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          readOnly: true,
          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField({required String label, required TextEditingController controller, required IconData icon, bool isPhone = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.name,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blue.shade700),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
          ),
        ),
      ],
    );
  }
}