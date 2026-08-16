import 'package:flutter/material.dart';
import 'package:lankalink/core/admin_dashboard_screen.dart';
import 'package:lankalink/core/admin_login_view_model.dart';
import 'package:lankalink/widgets/app_button.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
    final vm = context.read<AdminLoginViewModel>();
    final success = await vm.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      if (success) {
        // Navigate to the admin dashboard on successful login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else if (vm.error != null) {
        // Show an error message if login fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.error!), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminLoginViewModel(),
      child: Consumer<AdminLoginViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Admin Login'),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your admin email',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !vm.isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                    ),
                    obscureText: true,
                    enabled: !vm.isLoading,
                  ),
                  const SizedBox(height: 40),
                  AppButton(
                    label: 'Login',
                    isLoading: vm.isLoading,
                    onPressed: () => _login(context),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: vm.isLoading
                        ? null
                        : () =>
                              Navigator.of(context).pushNamed('/admin_signup'),
                    child: const Text('Create Admin Account (For Testing)'),
                  ),
                  TextButton(
                    onPressed: vm.isLoading
                        ? null
                        : () => Navigator.of(context).pushNamed('/signup'),
                    child: const Text('Create User Account'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
