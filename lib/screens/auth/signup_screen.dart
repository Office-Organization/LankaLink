import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
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

  Future<void> _signUpUser() async {
    String name = _nameController.text.trim();
    String nic = _nicController.text.trim();
    String email = _emailController.text.trim();
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        nic.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('කරුණාකර සියලුම තොරතුරු ඇතුළත් කරන්න.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ඔබ ඇතුළත් කළ මුරපදයන් නොගැලපේ.')),
      );
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
            'name': name,
            'nic': nic,
            'email': email,
            'phone': phone,
            'role': 'data collector',
            'createdAt': DateTime.now(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ලියාපදිංචිය සාර්ථකයි! දැන් Login වන්න.'),
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('FirebaseAuthException during signup: ${e.code}\n$stackTrace');
      String errorMessage = 'දෝෂයක් මතු විය.';
      if (e.code == 'weak-password') {
        errorMessage = 'මුරපදය ඉතා දුර්වලයි (අවම අකුරු/ඉලක්කම් 6ක් අවශ්යයි).';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'මෙම Email ලිපිනය දැනටමත් ලියාපදිංචි කර ඇත.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'ඔබ ඇතුළත් කළ Email ලිපිනය වැරදියි.';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e, stackTrace) {
      debugPrint('Generic error during signup: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ලියාපදිංචි වීමේදී අනපේක්ෂිත දෝෂයක් මතු විය.'),
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
            color: Colors.black87,
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
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.grey.shade100,
            suffixIcon: isPassword || isConfirmPassword
                ? IconButton(
                    icon: Icon(
                      (isPassword ? _obscurePassword : _obscureConfirmPassword)
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.lightBlue,
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
                : Icon(icon, color: Colors.lightBlue.shade200),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ලියාපදිංචි වන්න',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),

              _buildTextField(
                'නම',
                'ඔබගේ නම ඇතුළත් කරන්න',
                Icons.person_outline,
                _nameController,
              ),
              _buildTextField(
                'ජාතික හැඳුනුම්පත් අංකය',
                'ජා.හැ. අංකය ඇතුළත් කරන්න',
                Icons.badge_outlined,
                _nicController,
              ),
              _buildTextField(
                'ඊමේල් ලිපිනය',
                'ඔබගේ ඊමේල් ලිපිනය ඇතුළත් කරන්න',
                Icons.email_outlined,
                _emailController,
              ),
              _buildTextField(
                'දුරකථන අංකය',
                'ඔබගේ දුරකථන අංකය ඇතුළත් කරන්න',
                Icons.phone_in_talk_outlined,
                _phoneController,
              ),
              _buildTextField(
                'මුරපදය',
                'මුරපදය',
                Icons.lock_outline,
                _passwordController,
                isPassword: true,
              ),
              _buildTextField(
                'මුරපදය නැවත ඇතුළත් කරන්න',
                'මුරපදය',
                Icons.lock_outline,
                _confirmPasswordController,
                isConfirmPassword: true,
              ),

              const SizedBox(height: 24),

              Container(
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Colors.lightBlueAccent, Colors.blue],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUpUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ලියාපදිංචි වන්න',
                          style: TextStyle(
                            fontFamily: 'UNSamantha',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ගිණුමක් සාදා තිබේද? ',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'ලොග් වන්න',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'UNSamantha',
                        color: Colors.lightBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}