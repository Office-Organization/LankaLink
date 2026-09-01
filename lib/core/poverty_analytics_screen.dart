import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PovertyAnalyticsScreen extends StatefulWidget {
  const PovertyAnalyticsScreen({super.key});

  @override
  State<PovertyAnalyticsScreen> createState() => _PovertyAnalyticsScreenState();
}

class _PovertyAnalyticsScreenState extends State<PovertyAnalyticsScreen> {
  bool _isDownloading = false;

  /// Fetches data and generates the PDF for Female-Headed Families
  Future<void> _generateFemaleHeadedFamiliesPDF() async {
    setState(() => _isDownloading = true);

    try {
      // 1. Fetch survey responses
      final snapshot = await FirebaseFirestore.instance.collection('survey_responses').get();
      
      List<List<String>> tableData = [];

      // 2. Filter locally for female-headed families
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final members = data['members'] as List<dynamic>? ?? [];
        final basicDetails = data['basicDetails'] as Map<String, dynamic>? ?? {};
        
        if (members.isNotEmpty) {
          final headMember = members[0] as Map<String, dynamic>;
          
          // Check if the primary member is Female
          if (headMember['gender'] == 'ස්ත්‍රී') {
            final headName = headMember['fullName']?.toString() ?? basicDetails['headName']?.toString() ?? 'N/A';
            final houseNumber = data['houseNumber']?.toString() ?? basicDetails['houseNumber']?.toString() ?? 'N/A';
            final phone = basicDetails['phone']?.toString() ?? '-';
            
            // Checking both root level and basicDetails level for income as a fallback
            final income = data['familyIncome']?.toString() ?? basicDetails['familyIncome']?.toString() ?? '-';

            // Extract children (from index 1 onwards, where isAdult is false or age < 18)
            List<String> childNames = [];
            List<String> childGenders = [];
            List<String> childAges = [];
            
            for (int i = 1; i < members.length; i++) {
              final member = members[i] as Map<String, dynamic>;
              final age = member['age'] is num ? (member['age'] as num).toInt() : null;
              
              if (member['isAdult'] == false || (age != null && age < 18)) {
                childNames.add(member['fullName']?.toString() ?? '-');
                childGenders.add(member['gender']?.toString() ?? '-');
                childAges.add(age?.toString() ?? '-');
              }
            }

            final hasSchoolChildren = childNames.isNotEmpty ? 'ඔව්' : 'නැත';
            final namesStr = childNames.join('\n');
            final gendersStr = childGenders.join('\n');
            final agesStr = childAges.join('\n');

            tableData.add([
              headName,
              houseNumber,
              phone,
              income,
              hasSchoolChildren,
              namesStr,
              gendersStr,
              agesStr,
            ]);
          }
        }
      }

      // 3. Generate PDF Document
      final pdf = pw.Document();
      
      // Load Sinhala Font (UN-Ganganee.ttf)
      final fontData = await rootBundle.load('assets/fonts/UN-Ganganee.ttf');
      final sinhalaFont = pw.Font.ttf(fontData);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return [
              pw.Text('1 ඇමුණුම් අංක 01', style: pw.TextStyle(font: sinhalaFont, fontSize: 12)),
              pw.Text('කාන්තා මූලික පවුල්', style: pw.TextStyle(font: sinhalaFont, fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                cellStyle: pw.TextStyle(font: sinhalaFont, fontSize: 10),
                headerStyle: pw.TextStyle(font: sinhalaFont, fontSize: 11, fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                cellAlignment: pw.Alignment.centerLeft,
                headers: [
                  'නම',
                  'ලිපිනය',
                  'දුරකතන අංකය',
                  'පවුලේ ආදායම',
                  'පාසල් යන වයසේ\nළමයින් සිටීද?',
                  'ළමයින්ගේ නම්',
                  'ස්ත්‍රී/පුරුෂ බව',
                  'වයස'
                ],
                data: tableData,
              ),
            ];
          },
        ),
      );

      // 4. Share/Download the PDF directly!
      final Uint8List pdfBytes = await pdf.save();
      
      await Printing.sharePdf(
        bytes: pdfBytes, 
        filename: 'Female_Headed_Families.pdf'
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Color(0xFF10B981), content: Text('PDF generated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

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
      body: _isDownloading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildExportCard(
                  title: 'කාන්තා මූලික පවුල්',
                  subtitle: 'Female-headed families data',
                  onTap: _generateFemaleHeadedFamiliesPDF,
                ),
                _buildExportCard(
                  title: 'විශේෂ අවශ්‍යතා සහිත පවුල්',
                  subtitle: 'Families with special needs',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon')),
                    );
                  }, 
                ),
                _buildExportCard(
                  title: 'අස්වැසුම ප්‍රතිලාභින',
                  subtitle: 'Aswasuma beneficiaries (Poor, Extreme Poor, etc.)',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon')),
                    );
                  }, 
                ),
              ],
            ),
    );
  }

  Widget _buildExportCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
            icon: const Icon(Icons.download_rounded, color: Color(0xFF7C3AED), size: 22),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }
}