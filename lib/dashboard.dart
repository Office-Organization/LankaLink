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
  String _fullName = 'පරිශීලක';
  int? _selectedCardIndex;

  // Government-style color palette
  static const Color primaryNavy = Color(0xFF0B1E3D);      // Deep navy
  static const Color accentGold = Color(0xFFC6A962);       // Muted gold
  static const Color cardBg = Color(0xFFF4F7FC);           // Light grey-blue
  static const Color confirmColor = Color(0xFF1E3A6B);     // Rich blue
  static const Color textDark = Color(0xFF1A1A1A);

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
    if (hour < 12) return 'සුභ උදෑසනක්';
    if (hour < 16) return 'සුභ දහවලක්';
    return 'සුභ සන්ධ්‍යාවක්';
  }

  void _handleConfirm() {
    if (_selectedCardIndex == null) return;
    if (_selectedCardIndex == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyDetailsScreen()));
    } else if (_selectedCardIndex == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const GNDetailsScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 2,
        titleSpacing: 0,
        title: Row(
          children: const [
            SizedBox(width: 12),
            Icon(Icons.account_balance, color: accentGold, size: 28),
            SizedBox(width: 12),
            Text(
              'LankaLink Dashboard',
              style: TextStyle(
                fontFamily: 'UN-Imanee', // මෙතන අකුරු මුහුණත නිවැරදිව සකසා ඇත
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: () => _logout(context),
              tooltip: 'ඉවත් වන්න',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting header with gold accent line
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getGreeting()}, $_fullName!',
                    style: const TextStyle(
                      fontFamily: 'UN-Imanee',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 2,
                    width: 60,
                    decoration: BoxDecoration(
                      color: accentGold,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),

            // Main content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    // Selectable cards with government-style cards
                    _buildGovSelectableCard(
                      index: 0,
                      title: 'පවුල් තොරතුරු',
                      subtitle: 'පවුලේ සාමාජිකයින් පිළිබඳ විස්තර',
                      icon: Icons.family_restroom,
                      accent: const Color(0xFFD4843A),  // Warm orange
                    ),
                    const SizedBox(height: 20),
                    _buildGovSelectableCard(
                      index: 1,
                      title: 'ග්‍රාම නිලධාරී වසමට අදාල තොරතුරු',
                      subtitle: 'නිලධාරී වසම් තොරතුරු හා සේවාවන්',
                      icon: Icons.location_city,
                      accent: const Color(0xFF2E7D32),  // Official green
                    ),
                    const SizedBox(height: 40),

                    // Confirm button with government-style gradient
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: _selectedCardIndex != null ? _handleConfirm : null,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: _selectedCardIndex != null
                                ? const LinearGradient(
                                    colors: [confirmColor, Color(0xFFC2185B)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : LinearGradient(
                                    colors: [Colors.grey.shade400, Colors.grey.shade400],
                                  ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedCardIndex != null
                                ? [
                                    BoxShadow(
                                      color: confirmColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [],
                          ),
                          child: const Center(
                            child: Text(
                              'පටන් ගන්න',
                              style: TextStyle(
                                fontFamily: 'UN-Sandhyanee',
                                fontSize: 22,
                                color: Color.fromARGB(255, 244, 234, 234),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGovSelectableCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
  }) {
    final bool isSelected = _selectedCardIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedCardIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accent : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accent.withOpacity(0.12)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon with subtle background
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: accent),
            ),
            const SizedBox(width: 18),
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'UN-Imanee',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'UN-Imanee',
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            // Custom radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accent : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? accent : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}