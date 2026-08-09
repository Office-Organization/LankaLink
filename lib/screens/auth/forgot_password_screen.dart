import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';
import '../../widgets/status_views.dart';
import 'forgot_password_view_model.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ForgotPasswordViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Reset your password',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter your email and we will send you a link to reset your password.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            AppTextField(
              controller: _emailCtrl,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Send Reset Link',
              isLoading: vm.isLoading,
              onPressed: () => context.read<ForgotPasswordViewModel>()
                  .sendResetLink(_emailCtrl.text.trim()),
            ),
            if (vm.message != null) ...[
              const SizedBox(height: 12),
              Text(vm.message!, style: const TextStyle(color: Colors.green)),
            ],
            if (vm.error != null) ...[
              const SizedBox(height: 12),
              ErrorView(vm.error!),
            ],
          ],
        ),
      ),
    );
  }
}