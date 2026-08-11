import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // දත්ත ලබාගැනීමට අවශ්‍ය Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false; // Loading තත්වය පෙන්වීමට

  // Firebase වෙත දත්ත යැවීමේ Function එක
  Future<void> _signUpUser() async {
    String name = _nameController.text.trim();
    String nic = _nicController.text.trim();
    String email = _emailController.text.trim();
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // 1. දත්ත සියල්ල පුරවා ඇත්දැයි පරීක්ෂා කිරීම
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

    // 2. මුරපද දෙකම සමාන දැයි පරීක්ෂා කිරීම
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ඔබ ඇතුළත් කළ මුරපදයන් නොගැලපේ.')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Loading ආරම්භ කිරීම
    });

    try {
      // 3. Firebase Authentication හරහා ගිණුම සෑදීම
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 4. Firestore Database එකට අමතර දත්ත (නම, NIC, Phone) සේව් කිරීම
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'name': name,
            'nic': nic,
            'email': email,
            'phone': phone,
            'createdAt': DateTime.now(),
          });

      // 5. සාර්ථක වූ පසු පණිවිඩයක් පෙන්වා Login තිරයට යාම
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ලියාපදිංචිය සාර්ථකයි! දැන් Login වන්න.'),
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      // Firebase වලින් එන දෝෂ (උදා: Email එක දැනටමත් භාවිතා කර ඇත්නම්) පෙන්වීම
      String errorMessage = 'දෝෂයක් මතු විය.';
      if (e.code == 'weak-password') {
        errorMessage = 'මුරපදය ඉතා දුර්වලයි (අවම අකුරු/ඉලක්කම් 6ක් අවශ්‍යයි).';
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Loading අවසන් කිරීම
        });
      }
    }
  }

  // නැවත නැවත භාවිත කළ හැකි (Reusable) Text Field එකක් සෑදීම
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
          style: GoogleFonts.poppins(
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
              Text(
                'Signup',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),

              _buildTextField(
                'Name',
                'Enter Your Name',
                Icons.person_outline,
                _nameController,
              ),
              _buildTextField(
                'NIC Number',
                'Enter Your NIC',
                Icons.badge_outlined,
                _nicController,
              ),
              _buildTextField(
                'Email',
                'Enter Your Email Adress',
                Icons.email_outlined,
                _emailController,
              ),
              _buildTextField(
                'Phone Number',
                'Enter Your Phone Number',
                Icons.phone_in_talk_outlined,
                _phoneController,
              ),
              _buildTextField(
                'Password',
                '**************',
                Icons.lock_outline,
                _passwordController,
                isPassword: true,
              ),
              _buildTextField(
                'Enter Password Again',
                '**************',
                Icons.lock_outline,
                _confirmPasswordController,
                isConfirmPassword: true,
              ),

              const SizedBox(height: 24),

              // Sign Up Button එක
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
                  onPressed: _isLoading
                      ? null
                      : _signUpUser, // Loading වන විට Button එක ඔබන්න බැරි කිරීම
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    disabledBackgroundColor:
                        Colors.grey.shade400, // Disable වූ විට වර්ණය
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
                      : Text(
                          'Sign Up',
                          style: GoogleFonts.poppins(
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
                  Text(
                    'Already Registered ? ',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Sign in',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
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
