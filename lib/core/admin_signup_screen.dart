import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lankalink/core/app_theme.dart';

class AdminSignupScreen extends StatefulWidget {
  const AdminSignupScreen({super.key});

  @override
  State<AdminSignupScreen> createState() => _AdminSignupScreenState();
}

class _AdminSignupScreenState extends State<AdminSignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nicController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUpAdmin() async {
    String name = _nameController.text.trim();
    String nic = _nicController.text.trim();
    String email = _emailController.text.trim();
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'name': name.isNotEmpty ? name : 'Admin (Test)',
            'nic': nic.isNotEmpty ? nic : '000000000V',
            'email': email,
            'phone': phone,
            'role': 'admin', // Assign admin role
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Admin account created successfully! You can now log in.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    bool isConfirmPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'UNSamantha',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword
              ? _obscurePassword
              : (isConfirmPassword ? _obscureConfirmPassword : false),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 13),
            filled: true,
            fillColor: AppColors.fieldFill,
            suffixIcon: isPassword || isConfirmPassword
                ? IconButton(
                    icon: Icon(
                      (isPassword ? _obscurePassword : _obscureConfirmPassword)
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.lightBlue,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isPassword) {
                          _obscurePassword = !_obscurePassword;
                        } else {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        }
                      });
                    },
                  )
                : Icon(icon, color: AppColors.lightBlue200),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Create Admin Account'),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _buildTextField(
                'Name (Optional)',
                'Enter name',
                Icons.person_outline,
                _nameController,
              ),
              _buildTextField(
                'NIC (Optional)',
                'Enter NIC',
                Icons.badge_outlined,
                _nicController,
              ),
              _buildTextField(
                'Email',
                'Enter admin email',
                Icons.email_outlined,
                _emailController,
              ),
              _buildTextField(
                'Phone (Optional)',
                'Enter phone number',
                Icons.phone_in_talk_outlined,
                _phoneController,
              ),
              _buildTextField(
                'Password',
                'Enter password',
                Icons.lock_outline,
                _passwordController,
                isPassword: true,
              ),
              _buildTextField(
                'Confirm Password',
                'Confirm password',
                Icons.lock_outline,
                _confirmPasswordController,
                isConfirmPassword: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUpAdmin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    disabledBackgroundColor: AppColors.textDisabled,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontFamily: 'UNSamantha',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pushNamed('/signup'),
                child: const Text('Not an admin? Create a user account.'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
