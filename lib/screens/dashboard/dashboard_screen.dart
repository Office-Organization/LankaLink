import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_button.dart';
import 'dashboard_view_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(AppStrings.dashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              await context.read<AuthRepository>().signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting (simplified, could be improved)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'සුභ උදෑසනක්, පරිශීලක!',
                    style: const TextStyle(
                      fontFamily: 'UN-Imanee',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 2,
                    width: 60,
                    color: AppColors.gold,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    _buildSelectableCard(
                      context,
                      index: 0,
                      title: AppStrings.familyDetails,
                      subtitle: 'පවුලේ සාමාජිකයින් පිළිබඳ විස්තර',
                      icon: Icons.family_restroom,
                      accent: const Color(0xFFD4843A),
                    ),
                    const SizedBox(height: 20),
                    _buildSelectableCard(
                      context,
                      index: 1,
                      title: 'ග්‍රාම නිලධාරී වසමට අදාල තොරතුරු',
                      subtitle: 'නිලධාරී වසම් තොරතුරු හා සේවාවන්',
                      icon: Icons.location_city,
                      accent: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 40),
                    AppButton(
                      label: AppStrings.continueText,
                      onPressed: vm.selectedCardIndex != null
                          ? () => _handleConfirm(context)
                          : null,
                      width: double.infinity,
                      height: 54,
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

  Widget _buildSelectableCard(
    BuildContext context, {
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
  }) {
    final vm = context.watch<DashboardViewModel>();
    final isSelected = vm.selectedCardIndex == index;

    return GestureDetector(
      onTap: () => vm.selectCard(index),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: accent),
            ),
            const SizedBox(width: 18),
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
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'UN-Imanee',
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
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

  void _handleConfirm(BuildContext context) {
    final index = context.read<DashboardViewModel>().selectedCardIndex;
    if (index == 0) {
      Navigator.pushNamed(context, Routes.survey);
    } else if (index == 1) {
      Navigator.pushNamed(context, Routes.gnDetails);
    }
  }
}