import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import '../../widgets/app_screen.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'අනුමැතිය එනතෙක් රැඳී සිටින්න',
      showBack: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_empty, size: 80, color: Colors.amber),
          const SizedBox(height: 20),
          const Text(
            'ඔබේ ගිණුම තවමත් සක්‍රීය කර නැත.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'කරුණාකර පරිපාලක අනුමැතිය ලැබෙන තෙක් රැඳී සිටින්න.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // Option to sign out and try again later
              // (sign out logic would be in AuthRepository, but we can call it here via provider)
              // For simplicity, we'll just pop to root
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('ආපසු පිවිසුම් පිටුවට'),
          ),
        ],
      ),
    );
  }
}