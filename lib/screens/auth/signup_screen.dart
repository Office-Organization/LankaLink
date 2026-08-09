import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_screen.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/status_views.dart';
import 'signup_view_model.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _fullNameCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _gnCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  String? _selectedDistrict;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  final List<String> _districts = [
    'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo',
    'Galle', 'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara',
    'Kandy', 'Kegalle', 'Kilinochchi', 'Kurunegala', 'Mannar',
    'Matale', 'Matara', 'Monaragala', 'Mullaitivu', 'Nuwara Eliya',
    'Polonnaruwa', 'Puttalam', 'Ratnapura', 'Trincomalee', 'Vavuniya'
  ];

  @override
  void initState() {
    super.initState();
    _nicCtrl.addListener(_onNicChanged);
  }

  void _onNicChanged() {
    final nic = _nicCtrl.text.trim();
    if (nic.length >= 6) {
      context.read<SignupViewModel>().checkNic(nic);
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _nicCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _gnCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();

    return AppScreen(
      title: AppStrings.signupTitle,
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(controller: _fullNameCtrl, label: 'සම්පූර්ණ නම'),
          AppTextField(
            controller: _nicCtrl,
            label: 'ජා.හැ.අංකය (NIC)',
            hint: 'උදා: 200302001961',
            keyboardType: TextInputType.number,
            errorText: vm.isNicTaken ? AppStrings.errDuplicateNic : null,
          ),
          if (vm.isCheckingNic)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('පරීක්ෂා කරමින්...', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          AppDropdown<String>(
            value: _selectedDistrict ?? '',
            items: _districts,
            hint: 'දිස්ත්‍රික්කය තෝරන්න',
            onChanged: (v) => setState(() => _selectedDistrict = v),
          ),
          AppTextField(controller: _gnCtrl, label: 'ග්‍රාම නිලධාරී කොට්ඨාසය'),
          AppTextField(
            controller: _emailCtrl,
            label: 'විද්‍යුත් තැපෑල',
            keyboardType: TextInputType.emailAddress,
          ),
          AppTextField(
            controller: _mobileCtrl,
            label: 'ජංගම දුරකථන අංකය',
            keyboardType: TextInputType.phone,
          ),
          AppTextField(
            controller: _passCtrl,
            label: 'මුරපදය',
            obscureText: _obscurePass,
            onChanged: (_) => _checkPasswords(vm),
          ),
          AppTextField(
            controller: _confirmPassCtrl,
            label: 'මුරපදය නැවත ඇතුලත් කරන්න',
            obscureText: _obscureConfirm,
            onChanged: (_) => _checkPasswords(vm),
          ),
          const SizedBox(height: 16),
          Center(
            child: AppButton(
              label: 'ලියාපදිංචි වන්න',
              isLoading: vm.isLoading,
              onPressed: () => _signUp(vm),
            ),
          ),
          if (vm.error != null) ...[
            const SizedBox(height: 16),
            ErrorView(vm.error!),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already Registered? '),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text('Sign in', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _checkPasswords(SignupViewModel vm) {
    // optional: can set error if mismatch, but we'll handle at submission
  }

  void _signUp(SignupViewModel vm) {
    vm.signUp(
      fullName: _fullNameCtrl.text.trim(),
      nic: _nicCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      district: _selectedDistrict,
      gnDivision: _gnCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      confirmPassword: _confirmPassCtrl.text.trim(),
    );
  }
}