import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_button.dart';
import '../../core/app_constants.dart';
import '../../data/auth_repository.dart';
import 'profile_screen.dart'; // Import the new profile screen

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 120,
        leading: TextButton(
          onPressed: () {
            // Guide එකට අනුව AuthRepository හරහා Sign Out වීම
            context.read<AuthRepository>().signOut();
          },
          child: const Text(
            'පිටවීම',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontFamily: 'UNSamantha',
            ),
          ),
        ),
        actions: [
          // --- NEW: Profile Button ---
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            icon: const Icon(Icons.account_circle, color: Colors.blue, size: 32),
            tooltip: 'මගේ ගිණුම (My Profile)',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),

              const Text(
                'ආයුබෝවන්',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const Spacer(flex: 1),

              _MenuButton(
                label: 'පවුල් තොරතුරු',
                onPressed: () {
                  // Route එක හරහා පවුල් තොරතුරු තිරයට යාම
                  Navigator.pushNamed(context, Routes.family);
                },
              ),

              const SizedBox(height: 24),

              _MenuButton(
                label: 'ග්‍රාම නිලධාරී වසමට\nඅදාල තොරතුරු',
                onPressed: () {
                  // Route එක හරහා GN තොරතුරු තිරයට යාම
                  Navigator.pushNamed(context, Routes.gn);
                },
              ),

              const Spacer(flex: 1),

              AppButton(
                label: 'පටන් ගන්න',
                onPressed: () {
                  // පටන් ගැනීමේ ක්‍රියාවලිය
                },
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'UNSamantha',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}