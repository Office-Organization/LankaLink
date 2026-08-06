import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'family_details.dart';
import 'GN_details.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String _fullName = 'පරිශීලක'; // Default to "User" in Sinhala

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _fullName = doc.data()?['fullName'] ?? 'පරිශීලක';
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'සුභ උදෑසනක්'; // Good morning
    } else if (hour < 16) {
      return 'සුභ දහවලක්'; // Good afternoon
    } else {
      return 'සුභ සන්ධ්‍යාවක්'; // Good evening
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: () => _logout(context),
            tooltip: 'ඉවත් වන්න (Logout)',
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Profile Image & Details ---
              const CircleAvatar(
                radius: 45,
                backgroundColor: Color(0xFFF3F4F6),
                child: Icon(Icons.person, size: 55, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                '${_getGreeting()}, $_fullName',
                style: const TextStyle(fontSize: 18, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              
              // --- Large Welcome Text from Image ---
              const Text(
                'ආයුබෝවන්',
                style: TextStyle(
                  fontSize: 34, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 50),

              // --- Grey Navigation Buttons ---
              _buildGreyButton(
                context,
                title: 'පවුල් තොරතුරු',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FamilyDetailsScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildGreyButton(
                context,
                title: 'ග්‍රාම නිලධාරී වසමට\nඅදාල තොරතුරු',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GNDetailsScreen()),
                  );
                },
              ),
              
              const Spacer(),
              
              // --- Red Start Button ---
              SizedBox(
                width: 220, 
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4F33), // Red/Orange color from image
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    // TODO: Define start button action
                  },
                  child: const Text(
                    'පටන් ගන්න',
                    style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Custom widget to recreate the exact grey button style in the image
  Widget _buildGreyButton(BuildContext context, {required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB), // Light grey matching the image
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}