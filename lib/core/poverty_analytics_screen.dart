import 'package:flutter/material.dart';
import 'female_headed_summary_screen.dart';
import 'special_needs_summary_screen.dart';
import 'aswasuma_summary_screen.dart'; // අලුත් පිටුව Import කරගන්න

class PovertyAnalyticsScreen extends StatelessWidget {
  const PovertyAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Data Analysis & Exports',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExportCard(
            context: context,
            title: 'කාන්තා මූලික පවුල්',
            subtitle: 'Female-headed families data',
            targetScreen: const FemaleHeadedSummaryScreen(),
          ),
          _buildExportCard(
            context: context,
            title: 'විශේෂ අවශ්‍යතා සහිත පවුල්',
            subtitle: 'Families with special needs',
            targetScreen: const SpecialNeedsSummaryScreen(), 
          ),
          _buildExportCard(
            context: context,
            title: 'අස්වැසුම ප්‍රතිලාභින',
            subtitle: 'Aswasuma beneficiaries (Poor, Extreme Poor, etc.)',
            // අලුත් පිටුවට මෙතැනින් Link කර ඇත
            targetScreen: const AswasumaSummaryScreen(), 
          ),
          _buildExportCard(
            context: context,
            title: 'ආදායම් මාර්ගයක් නොමැති පවුල්',
            subtitle: 'Families without an income source',
            targetScreen: null, 
          ),
          _buildExportCard(
            context: context,
            title: 'කෘෂිකර්මික / ධීවර පවුල්',
            subtitle: 'Agriculture & Fisheries families',
            targetScreen: null, 
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    Widget? targetScreen,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.table_chart_outlined, color: Color(0xFF7C3AED)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B)),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ),
        trailing: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF3E8FF),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF7C3AED), size: 18),
            onPressed: () {
              if (targetScreen != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => targetScreen),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming Soon...')),
                );
              }
            },
          ),
        ),
        onTap: () {
          if (targetScreen != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => targetScreen),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coming Soon...')),
            );
          }
        },
      ),
    );
  }
}