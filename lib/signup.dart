import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final nic = _nicController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (name.isEmpty ||
        nic.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      setState(() => _message = 'Please fill all fields.');
      return;
    }
    if (password != confirm) {
      setState(() => _message = 'Passwords do not match.');
      return;
    }
    if (password.length < 6) {
      setState(() => _message = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          'nic': nic,
          'email': email,
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await user.sendEmailVerification();
        await FirebaseAuth.instance.signOut();

        setState(() {
          _message =
              'Account created! A verification link has been sent to $email.';
          _isLoading = false;
        });

        _nameController.clear();
        _nicController.clear();
        _emailController.clear();
        _phoneController.clear();
        _passwordController.clear();
        _confirmController.clear();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = _getSignUpErrorMessage(e);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Something went wrong. Try again.';
        _isLoading = false;
      });
    }
  }

  String _getSignUpErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      default:
        return '${e.message}';
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    bool obscureText = false,
    bool isPassword = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: onToggleVisibility,
                    color: Colors.blue.shade200,
                  )
                : Icon(icon, color: Colors.blue.shade200),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: 'Name',
              controller: _nameController,
              icon: Icons.person_outline,
              hint: 'Enter Your Name',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'NIC Number',
              controller: _nicController,
              icon: Icons.credit_card_outlined,
              hint: 'Enter Your NIC',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Email',
              controller: _emailController,
              icon: Icons.email_outlined,
              hint: 'Enter Your Email Adress',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Phone Number',
              controller: _phoneController,
              icon: Icons.phone_outlined,
              hint: 'Enter Your Phone Number',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Password',
              controller: _passwordController,
              icon: Icons.visibility_outlined,
              hint: '***********',
              obscureText: _obscurePassword,
              isPassword: true,
              onToggleVisibility: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Enter Password Again',
              controller: _confirmController,
              icon: Icons.visibility_outlined,
              hint: '***********',
              obscureText: _obscureConfirm,
              isPassword: true,
              onToggleVisibility: () {
                setState(() {
                  _obscureConfirm = !_obscureConfirm;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 3,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already Registered ? '),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Sign in',
                    style: TextStyle(
                      color: Color(0xFF4FC3F7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
