import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  final GlobalKey _pdfTableKey = GlobalKey();
  List<Map<String, dynamic>> _printableRecords = [];

  Future<void> _generateFemaleHeadedFamiliesPDF() async {
    setState(() => _isDownloading = true);

    try {
      final snapshot = await FirebaseFirestore.instance.collection('survey_responses').get();
      List<Map<String, dynamic>> extracted = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final members = data['members'] as List<dynamic>? ?? [];
        final basicDetails = data['basicDetails'] as Map<String, dynamic>? ?? {};

        if (members.isNotEmpty) {
          final headMember = members[0] as Map<String, dynamic>;

          if (headMember['gender'] == 'ස්ත්‍රී') {
            final headName = headMember['fullName']?.toString() ?? basicDetails['headName']?.toString() ?? '-';
            final houseNumber = data['houseNumber']?.toString() ?? basicDetails['houseNumber']?.toString() ?? '-';
            final phone = basicDetails['phone']?.toString() ?? '-';
            final income = data['familyIncome']?.toString() ?? basicDetails['familyIncome']?.toString() ?? '-';

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

            extracted.add({
              'name': headName,
              'address': houseNumber,
              'phone': phone,
              'income': income,
              'hasSchoolChildren': childNames.isNotEmpty ? 'ඔව්' : 'නැත',
              'childNames': childNames.isNotEmpty ? childNames.join('\n') : '-',
              'childGenders': childGenders.isNotEmpty ? childGenders.join('\n') : '-',
              'childAges': childAges.isNotEmpty ? childAges.join('\n') : '-',
            });
          }
        }
      }

      setState(() {
        _printableRecords = extracted;
      });

      // UI එක render වන තෙක් සුළු මොහොතක් රැඳී සිටීම
      await Future.delayed(const Duration(milliseconds: 300));

      // Table එක Image එකක් ලෙස capture කිරීම
      final boundary = _pdfTableKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Table layout could not be captured.');

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Image conversion failed.');
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final pdf = pw.Document();
      final imageProvider = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(imageProvider),
            );
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Female_Headed_Families.pdf',
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
      body: Stack(
        children: [
          ListView(
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
                onTap: () {},
              ),
              _buildExportCard(
                title: 'අස්වැසුම ප්‍රතිලාභින',
                subtitle: 'Aswasuma beneficiaries (Poor, Extreme Poor, etc.)',
                onTap: () {},
              ),
            ],
          ),

          // PDF එක සඳහා පසුබිමේ render වන Table view එක
          if (_printableRecords.isNotEmpty)
            Positioned(
              left: -99999, // Screen එකෙන් පිටත render කරවීම
              child: RepaintBoundary(
                key: _pdfTableKey,
                child: Container(
                  width: 1100,
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '1 ඇමුණුම් අංක 01',
                        style: TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'AbhayaLibre'),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'කාන්තා මූලික පවුල්',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'AbhayaLibre'),
                      ),
                      const SizedBox(height: 12),
                      Table(
                        border: TableBorder.all(color: Colors.black, width: 0.8),
                        columnWidths: const {
                          0: FlexColumnWidth(2.2),
                          1: FlexColumnWidth(1.0),
                          2: FlexColumnWidth(1.4),
                          3: FlexColumnWidth(1.3),
                          4: FlexColumnWidth(1.6),
                          5: FlexColumnWidth(1.8),
                          6: FlexColumnWidth(1.2),
                          7: FlexColumnWidth(0.8),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                            children: [
                              _buildTableHeaderCell('නම'),
                              _buildTableHeaderCell('ලිපිනය'),
                              _buildTableHeaderCell('දුරකතන අංකය'),
                              _buildTableHeaderCell('පවුලේ ආදායම'),
                              _buildTableHeaderCell('පාසල් යන වයසේ\nළමයින් සිටීද?'),
                              _buildTableHeaderCell('ළමයින්ගේ නම්'),
                              _buildTableHeaderCell('ස්ත්‍රී/පුරුෂ බව'),
                              _buildTableHeaderCell('වයස'),
                            ],
                          ),
                          ..._printableRecords.map((row) {
                            return TableRow(
                              children: [
                                _buildTableCell(row['name']!),
                                _buildTableCell(row['address']!),
                                _buildTableCell(row['phone']!),
                                _buildTableCell(row['income']!),
                                _buildTableCell(row['hasSchoolChildren']!),
                                _buildTableCell(row['childNames']!),
                                _buildTableCell(row['childGenders']!),
                                _buildTableCell(row['childAges']!),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_isDownloading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black, fontFamily: 'AbhayaLibre'),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.black, fontFamily: 'AbhayaLibre'),
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