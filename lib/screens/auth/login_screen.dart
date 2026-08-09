import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_strings.dart';
import '../../widgets/app_screen.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';
import '../../widgets/status_views.dart';
import 'login_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nicCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _nicCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();

    return AppScreen(
      title: AppStrings.loginTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _nicCtrl,
            label: 'ඔබේ ජා.හැ.අංකය ඇතුලත් කරන්න',
            keyboardType: TextInputType.number,
          ),
          AppTextField(
            controller: _passCtrl,
            label: 'මුරපදය ඇතුලත් කරන්න',
            obscureText: true,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
              child: const Text('Forgot Password ?'),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: AppButton(
              label: 'ඇතුල් වන්න',
              isLoading: vm.isLoading,
              onPressed: () => context.read<LoginViewModel>()
                  .login(_nicCtrl.text.trim(), _passCtrl.text.trim()),
            ),
          ),
          if (vm.error != null) ...[
            const SizedBox(height: 16),
            ErrorView(vm.error!),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account? "),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/signup'),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}