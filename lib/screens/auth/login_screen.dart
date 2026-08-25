import 'package:flutter/material.dart';
import 'package:lankalink/screens/auth/login_view_model.dart';
import 'package:provider/provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // සිංහලෙන් Pop-up Alert Dialog පෙන්වීම
  void _showErrorPopup({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    bool showSignupOption = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 42),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'UNSamantha',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'UNGanganee',
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (showSignupOption) ...[
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'ලියාපදිංචි වන්න',
                    style: TextStyle(
                      fontFamily: 'UNSamantha',
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text(
                  'වසන්න',
                  style: TextStyle(
                    fontFamily: 'UNSamantha',
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text(
                    'හරි',
                    style: TextStyle(
                      fontFamily: 'UNSamantha',
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loginUser() async {
    final vm = context.read<LoginViewModel>();
    final success = await vm.login(
      _loginIdController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (!success) {
      switch (vm.errorType) {
        case LoginErrorType.notActive:
          _showErrorPopup(
            title: 'ගිණුම සක්‍රිය කර නැත',
            message: 'ඔබගේ ගිණුම තවමත් සක්‍රිය කර නොමැත. පරිපාලක (Admin) අනුමැතිය ලැබෙන තෙක් කරුණාකර රැඳී සිටින්න.',
            icon: Icons.hourglass_top_rounded,
            iconColor: Colors.orange,
          );
          break;

        case LoginErrorType.deactivated:
          _showErrorPopup(
            title: 'ගිණුම අක්‍රිය කර ඇත',
            message: 'ඔබගේ ගිණුම අක්‍රිය (Deactivate) කර ඇත. වැඩිදුර තොරතුරු සඳහා කරුණාකර පරිපාලක (Admin) අමතන්න.',
            icon: Icons.block_flipped,
            iconColor: Colors.redAccent,
          );
          break;

        case LoginErrorType.noAccount:
          _showErrorPopup(
            title: 'ගිණුමක් හමු නොවීය',
            message: 'මෙම තොරතුරු සඳහා ගිණුමක් ලියාපදිංචි කර නොමැත. කරුණාකර පළමුව ලියාපදිංචි වන්න.',
            icon: Icons.person_off_outlined,
            iconColor: Colors.blueAccent,
            showSignupOption: true,
          );
          break;

        case LoginErrorType.invalidCredentials:
          _showErrorPopup(
            title: 'තොරතුරු වැරදියි',
            message: 'ඇතුළත් කළ මුරපදය වැරදියි. කරුණාකර නැවත උත්සාහ කරන්න.',
            icon: Icons.lock_outline_rounded,
            iconColor: Colors.red,
          );
          break;

        default:
          if (vm.error != null) {
            _showErrorPopup(
              title: 'දෝෂයක් මතු විය',
              message: vm.error!,
              icon: Icons.error_outline_rounded,
              iconColor: Colors.red,
            );
          }
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Text(
                'දැන්ම ලොග් වන්න',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'යෙදුම භාවිත කිරීමට කරුණාකර ලොග් වන්න',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'UNGanganee',
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 60),
              const Text(
                'ඊමේල් ලිපිනය හෝ ජාතික හැඳුනුම්පත් අංකය',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _loginIdController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Email / NIC',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  suffixIcon: Icon(
                    Icons.person_outline,
                    color: Colors.blue.shade300,
                  ),
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
              const SizedBox(height: 20),
              const Text(
                'ඔබගේ මුරපදය ඇතුලත් කරන්න',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'මුරපදය',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.blue.shade300,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
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
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'මුරපදය අමතකද?',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ),
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
                  onPressed: vm.isLoading ? null : _loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  child: vm.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ලොග් වන්න',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'UNSamantha',
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
                    'ගිණුමක් නැද්ද? ',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'ලියාපදිංචි වන්න',
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}