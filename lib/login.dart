import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup.dart';
import 'forgot_password.dart';
import 'dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nicController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nicController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final nic = _nicController.text.trim();
    final password = _passwordController.text.trim();

    if (nic.isEmpty || password.isEmpty) {
      setState(() => _message = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      // 1. Find user account by NIC
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('nic', isEqualTo: nic)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (!mounted) return;
        setState(() {
          _message = 'No account found with this NIC number.';
          _isLoading = false;
        });
        return;
      }

      final userData = querySnapshot.docs.first.data();
      final email = userData['email'] as String?;
      final String uid = querySnapshot.docs.first.id;

      if (email == null || email.isEmpty) {
        if (!mounted) return;
        setState(() {
          _message = 'Invalid email dynamic record for this NIC.';
          _isLoading = false;
        });
        return;
      }

      // 2. Sign in with Firebase Auth using retrieved email and password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Verify status in Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() {
          _message = 'User profile data does not exist.';
          _isLoading = false;
        });
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'inactive';

      if (status != 'active') {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() {
          _message = 'Your account is pending activation. Please contact administrator.';
          _isLoading = false;
        });
        return;
      }

      // 4. Success: Redirect to Dashboard Screen
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _message = _getErrorMessage(e);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Login failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for this NIC.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.map_outlined, size: 110, color: Color(0xFFC2185B)),
                    const SizedBox(height: 20),
                    const Text(
                      'Log In Now',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Please login to continue using the app',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Enter Your NIC',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nicController,
                decoration: InputDecoration(
                  hintText: '200302001961',
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  suffixIcon: const Icon(Icons.credit_card, color: Color(0xFFC2185B)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Enter Your Password',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '***************',
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    color: const Color(0xFFC2185B),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text(
                    'Forgot Password ?',
                    style: TextStyle(color: Colors.black, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC2185B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Center(
                    child: Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(color: Color(0xFFC2185B), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}