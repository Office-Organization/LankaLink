import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SpecialNeedsSummaryScreen extends StatefulWidget {
  const SpecialNeedsSummaryScreen({super.key});

  @override
  State<SpecialNeedsSummaryScreen> createState() => _SpecialNeedsSummaryScreenState();
}

class _SpecialNeedsSummaryScreenState extends State<SpecialNeedsSummaryScreen> {
  bool _isLoading = true;
  bool _isDownloading = false;
  final GlobalKey _pdfTableKey = GlobalKey();

  List<Map<String, dynamic>> _allRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 1. Firestore එකෙන් විශේෂ අවශ්‍යතා සහිත දත්ත පමණක් Filter කර ලබා ගැනීම
  Future<void> _fetchData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('survey_responses').get();
      List<Map<String, dynamic>> extracted = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final basicDetails = data['basicDetails'] as Map<String, dynamic>? ?? {};
        final members = data['members'] as List<dynamic>? ?? [];

        // විශේෂ අවශ්‍යතා තිබේදැයි පරීක්ෂා කිරීම
        final int specialNeedsCount = (data['specialNeedsCount'] is num)
            ? (data['specialNeedsCount'] as num).toInt()
            : int.tryParse(data['specialNeedsCount']?.toString() ?? '0') ?? 0;
            
        final String specialNeedDesc = data['specialNeedDescription']?.toString().trim() ?? '';
        final double specialNeedsAmount = (data['specialNeedsAmount'] is num)
            ? (data['specialNeedsAmount'] as num).toDouble()
            : double.tryParse(data['specialNeedsAmount']?.toString() ?? '0') ?? 0.0;

        if (specialNeedsCount > 0 || specialNeedDesc.isNotEmpty || specialNeedsAmount > 0) {
          // මූලික විස්තර
          final headMember = members.isNotEmpty ? members[0] as Map<String, dynamic> : null;
          final headName = headMember?['fullName']?.toString() ?? basicDetails['headName']?.toString() ?? '-';
          final houseNumber = data['houseNumber']?.toString() ?? basicDetails['houseNumber']?.toString() ?? '-';
          final phone = basicDetails['phone']?.toString() ?? '-';

          // ආදායම / රැකියාව
          final incomeDetails = data['incomeDetails'] as Map<String, dynamic>? ?? {};
          final jobType = incomeDetails['jobType']?.toString() ?? '';
          final mainIncome = incomeDetails['mainIncome']?.toString() ?? '';
          String incomeStr = '-';
          if (jobType.isNotEmpty && jobType != '-') {
            incomeStr = jobType;
          } else if (mainIncome.isNotEmpty && mainIncome != '-') {
            incomeStr = 'ආදායම: $mainIncome';
          }

          // රජයේ ආධාරයේ ප්‍රභවය
          final govSource = data['govAidSource']?.toString() ?? 
              (basicDetails['receivesGovtAssistance'] == true ? 'මධ්‍යම රජය' : 'පළාත් සභා');

          // වගා නොකරන ලද ඉඩම්
          final assetsDetails = data['assetsDetails'] as Map<String, dynamic>? ?? {};
          final uncultivatedLand = assetsDetails['uncultivatedLand']?.toString() ?? 
              data['uncultivatedLand']?.toString() ?? 'නැත';

          // වෙනත් කරුණු
          final otherRemarks = data['otherRemarks']?.toString() ?? '-';

          extracted.add({
            'name': headName,
            'houseNumber': houseNumber,
            'phone': phone,
            'income': incomeStr,
            'disability': specialNeedDesc.isNotEmpty ? specialNeedDesc : 'ආබාධිත',
            'aidAmount': specialNeedsAmount > 0 ? specialNeedsAmount.toStringAsFixed(0) : '0',
            'govSource': govSource,
            'uncultivatedLand': uncultivatedLand,
            'other': otherRemarks,
          });
        }
      }

      if (mounted) {
        setState(() {
          _allRecords = extracted;
          _filteredRecords = extracted;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('දත්ත ලබා ගැනීමේ දෝෂයකි: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> temp = _allRecords;
    final query = _searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      temp = temp.where((record) {
        final name = record['name'].toString().toLowerCase();
        final houseNo = record['houseNumber'].toString().toLowerCase();
        return name.contains(query) || houseNo.contains(query);
      }).toList();
    }

    setState(() {
      _filteredRecords = temp;
    });
  }

  // 2. PDF එක Generate කිරීම
  Future<void> _generatePDF() async {
    if (_filteredRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF එක සෑදීමට දත්ත නොමැත.')),
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final boundary = _pdfTableKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Table layout capture කිරීමට නොහැකි විය.');

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
        filename: 'Special_Needs_Families.pdf',
      );

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
        title: const Text(
          'විශේෂ අවශ්‍යතා සහිත පවුල්',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        actions: [
          if (!_isLoading && _filteredRecords.isNotEmpty)
            IconButton(
              tooltip: 'Download PDF',
              icon: _isDownloading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_rounded),
              onPressed: _isDownloading ? null : _generatePDF,
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (!_isLoading && _allRecords.isNotEmpty)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: 'නම හෝ ගෘහ මූලික අංකය සොයන්න...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF7C3AED)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
                    : _filteredRecords.isEmpty
                        ? const Center(child: Text('විශේෂ අවශ්‍යතා සහිත පවුල් වාර්තා වී නොමැත.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredRecords.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'වාර්තා වූ පවුල් ගණන:',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3E8FF),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${_filteredRecords.length}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final record = _filteredRecords[index - 1];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record['name'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                      ),
                                      const Divider(height: 20),
                                      _buildSummaryRow(Icons.home_outlined, 'ගෘහ මූලික අංකය:', record['houseNumber']),
                                      _buildSummaryRow(Icons.phone_outlined, 'දුරකථනය:', record['phone']),
                                      _buildSummaryRow(Icons.accessible_forward_rounded, 'ආබාධිත තත්ත්වය:', record['disability']),
                                      _buildSummaryRow(Icons.monetization_on_outlined, 'රජයේ ආධාරය (රු.):', record['aidAmount']),
                                      // "ආධාර ලබාදෙන්නේ" පේළිය ඉවත් කරන ලදි.
                                      _buildSummaryRow(Icons.work_outline, 'ආදායම/රැකියාව:', record['income']),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),

          // 4. PDF එක සඳහා පමණක් Render වන සඟවා ඇති Table එක
          if (_filteredRecords.isNotEmpty)
            Positioned(
              left: -99999,
              child: RepaintBoundary(
                key: _pdfTableKey,
                child: Container(
                  width: 1400,
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '2 විශේෂ අවශ්‍යතා සහිත පවුල් (ඇමුණුම් අංක 2)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'AbhayaLibre'),
                      ),
                      const SizedBox(height: 14),
                      Table(
                        border: TableBorder.all(color: Colors.black, width: 0.8),
                        columnWidths: const {
                          0: FlexColumnWidth(2.0), // නම
                          1: FlexColumnWidth(1.0), // ගෘහ මූලික අංකය / ලිපිනය
                          2: FlexColumnWidth(1.2), // දුරකතන අංකය
                          3: FlexColumnWidth(1.3), // පවුලේ ආදායම
                          4: FlexColumnWidth(1.6), // ආබාධය කුමක්ද යන්න
                          5: FlexColumnWidth(1.4), // රජයේ ආධාරයේ වටිනාකම
                          6: FlexColumnWidth(1.6), // මධ්‍යම රජයේද / පළාත් සභාද
                          7: FlexColumnWidth(1.8), // වගා නොකරන ලද ඉඩම්
                          8: FlexColumnWidth(1.2), // වෙනත්
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                            children: [
                              _buildTableHeaderCell('නම'),
                              _buildTableHeaderCell('ලිපිනය / අංකය'),
                              _buildTableHeaderCell('දුරකතන අංකය'),
                              _buildTableHeaderCell('පවුලේ ආදායම'),
                              _buildTableHeaderCell('ආබාධය කුමක්ද යන්න'),
                              _buildTableHeaderCell('රජයේ ආධාරයෙ\nවටිනා කම (රු.)'),
                              _buildTableHeaderCell('මධ්‍යම රජයේද/\nපළාත් සභාද යන්න'),
                              _buildTableHeaderCell('වගා නොකරන ලද ඉඩම්\nතිබේද / ප්‍රමාණය'),
                              _buildTableHeaderCell('වෙනත්'),
                            ],
                          ),
                          ..._filteredRecords.map((row) {
                            return TableRow(
                              children: [
                                _buildTableCell(row['name']!),
                                _buildTableCell(row['houseNumber']!),
                                _buildTableCell(row['phone']!),
                                _buildTableCell(row['income']!),
                                _buildTableCell(row['disability']!),
                                _buildTableCell(row['aidAmount']!),
                                _buildTableCell(row['govSource']!), // PDF එකේ පමණක් පෙන්වීමට ඉතිරි කර ඇත
                                _buildTableCell(row['uncultivatedLand']!),
                                _buildTableCell(row['other']!),
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

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.black, fontFamily: 'AbhayaLibre'),
      ),
    );
  }
}