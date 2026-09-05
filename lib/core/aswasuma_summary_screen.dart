import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'member_detail_screen.dart'; 

class AswasumaSummaryScreen extends StatefulWidget {
  const AswasumaSummaryScreen({super.key});

  @override
  State<AswasumaSummaryScreen> createState() => _AswasumaSummaryScreenState();
}

class _AswasumaSummaryScreenState extends State<AswasumaSummaryScreen> {
  bool _isLoading = true;
  bool _isDownloading = false;
  final GlobalKey _pdfTableKey = GlobalKey();

  // Master lists
  List<Map<String, dynamic>> _allPoorRecords = [];
  List<Map<String, dynamic>> _allExtremePoorRecords = [];
  List<Map<String, dynamic>> _allAtRiskRecords = [];
  List<Map<String, dynamic>> _allTransitionalRecords = [];

  // Filtered lists
  List<Map<String, dynamic>> _poorRecords = [];
  List<Map<String, dynamic>> _extremePoorRecords = [];
  List<Map<String, dynamic>> _atRiskRecords = [];
  List<Map<String, dynamic>> _transitionalRecords = [];

  String _selectedGN = "සියලුම GN වසම්";
  List<String> _gnList = ["සියලුම GN වසම්"];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('survey_responses').get();
      
      List<Map<String, dynamic>> tempPoor = [];
      List<Map<String, dynamic>> tempExtreme = [];
      List<Map<String, dynamic>> tempAtRisk = [];
      List<Map<String, dynamic>> tempTransitional = [];
      Set<String> gnSet = {"සියලුම GN වසම්"};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final basicDetails = data['basicDetails'] as Map<String, dynamic>? ?? {};
        
        if (data['hasAswasuma'] == true || basicDetails['hasAswasuma'] == true) {
          
          final members = data['members'] as List<dynamic>? ?? [];
          final headName = basicDetails['headName']?.toString() ?? '-';
          final phone = basicDetails['phone']?.toString() ?? '-';
          final familySize = members.length.toString();
          final income = data['familyIncome']?.toString() ?? basicDetails['familyIncome']?.toString() ?? '-';
          final aidAmount = data['aswasumaAmount']?.toString() ?? basicDetails['aswasumaAmount']?.toString() ?? '-';
          
          final assetsDetails = data['assetsDetails'] as Map<String, dynamic>? ?? {};
          final uncultivatedLand = assetsDetails['uncultivatedLand']?.toString() ?? data['uncultivatedLand']?.toString() ?? 'නැත';
          
          final category = data['aswasumaCategory']?.toString() ?? basicDetails['aswasumaCategory']?.toString() ?? 'දුප්පත්';
          
          final gnDivision = data['gnDivision']?.toString() ?? basicDetails['gn_division']?.toString() ?? basicDetails['gnDivision']?.toString() ?? 'නොදනී';
          if (gnDivision != 'නොදනී' && gnDivision.isNotEmpty) {
            gnSet.add(gnDivision);
          }

          final recordData = {
            'name': headName,
            'phone': phone,
            'familySize': familySize,
            'income': income,
            'aidAmount': aidAmount,
            'uncultivatedLand': uncultivatedLand,
            'gn': gnDivision,
            'rawData': data, 
          };

          if (category.contains('අන්ත')) {
            tempExtreme.add(recordData);
          } else if (category.contains('අවදානම්')) {
            tempAtRisk.add(recordData);
          } else if (category.contains('සංක්‍රාන්තික')) {
            tempTransitional.add(recordData);
          } else {
            tempPoor.add(recordData);
          }
        }
      }

      if (mounted) {
        setState(() {
          _allPoorRecords = tempPoor;
          _allExtremePoorRecords = tempExtreme;
          _allAtRiskRecords = tempAtRisk;
          _allTransitionalRecords = tempTransitional;
          _gnList = gnSet.toList();
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      if (_selectedGN == "සියලුම GN වසම්") {
        _poorRecords = List.from(_allPoorRecords);
        _extremePoorRecords = List.from(_allExtremePoorRecords);
        _atRiskRecords = List.from(_allAtRiskRecords);
        _transitionalRecords = List.from(_allTransitionalRecords);
      } else {
        _poorRecords = _allPoorRecords.where((r) => r['gn'] == _selectedGN).toList();
        _extremePoorRecords = _allExtremePoorRecords.where((r) => r['gn'] == _selectedGN).toList();
        _atRiskRecords = _allAtRiskRecords.where((r) => r['gn'] == _selectedGN).toList();
        _transitionalRecords = _allTransitionalRecords.where((r) => r['gn'] == _selectedGN).toList();
      }
    });
  }

  Future<void> _generatePDF() async {
    final totalRecords = _poorRecords.length + _extremePoorRecords.length + _atRiskRecords.length + _transitionalRecords.length;
    if (totalRecords == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF එක සෑදීමට දත්ත නොමැත.')),
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 300));
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
            return pw.Center(child: pw.Image(imageProvider));
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      await Printing.sharePdf(bytes: pdfBytes, filename: 'Aswasuma_Beneficiaries.pdf');

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')));
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
        title: const Text('අස්වැසුම ප්‍රතිලාභීන්', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        actions: [
          if (!_isLoading)
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
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
              : Column(
                  children: [
                    // Dynamic GN Division Dropdown
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedGN,
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF7C3AED)),
                            items: _gnList.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    color: value == "සියලුම GN වසම්" ? Colors.grey.shade700 : Colors.black87,
                                    fontWeight: value == "සියලුම GN වසම්" ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedGN = newValue!;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildUiSection('දුප්පත්', _poorRecords, Colors.blue),
                            _buildUiSection('අන්ත දුප්පත්', _extremePoorRecords, Colors.red),
                            _buildUiSection('අවදානම් සහගත පවුල්', _atRiskRecords, Colors.orange),
                            _buildUiSection('සංක්‍රාන්තික පවුල්', _transitionalRecords, Colors.purple),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

          // PDF Tables (Hidden)
          Positioned(
            left: -99999,
            child: RepaintBoundary(
              key: _pdfTableKey,
              child: Container(
                width: 1200, 
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('3 අස්වැසුම ප්‍රතිලාභින ගණන (ඇමුණුම් අංක 3) - GN: $_selectedGN', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'AbhayaLibre')),
                    const SizedBox(height: 20),
                    _buildPdfTableSection('දුප්පත්', _poorRecords),
                    const SizedBox(height: 24),
                    _buildPdfTableSection('අන්ත දුප්පත්', _extremePoorRecords),
                    const SizedBox(height: 24),
                    _buildPdfTableSection('අවදානම් සහගත පවුල්', _atRiskRecords),
                    const SizedBox(height: 24),
                    _buildPdfTableSection('සංක්‍රාන්තික පවුල්', _transitionalRecords),
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

  Widget _buildUiSection(String title, List<Map<String, dynamic>> records, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(width: 4, height: 20, color: color),
              const SizedBox(width: 8),
              Text('$title (${records.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
        ),
        if (records.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 12),
            child: Text('මෙම කාණ්ඩය සඳහා දත්ත නොමැත.', style: TextStyle(color: Colors.grey)),
          ),
        ...records.map((record) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              clipBehavior: Clip.antiAlias, 
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MemberDetailScreen(data: record['rawData']),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(record['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('සාමාජිකයින්: ${record['familySize']} | ආදායම: ${record['income']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                      Text(record['aidAmount'], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            )),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildPdfTableSection(String title, List<Map<String, dynamic>> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'AbhayaLibre')),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.black, width: 0.8),
          columnWidths: const {
            0: FlexColumnWidth(2.0),
            1: FlexColumnWidth(1.2),
            2: FlexColumnWidth(1.4),
            3: FlexColumnWidth(1.4),
            4: FlexColumnWidth(1.4),
            5: FlexColumnWidth(2.0),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
              children: [
                _buildTableHeaderCell('නම'),
                _buildTableHeaderCell('දුරකතන අංකය'),
                _buildTableHeaderCell('පවුලේ සාමාජිකයින්\nප්‍රමාණය'),
                _buildTableHeaderCell('පවුලේ ආදායම'),
                _buildTableHeaderCell('රජයේ ආධාරයෙ\nවටිනා කම'),
                _buildTableHeaderCell('වගා නොකරන ලද ඉඩම්\nතිබේද / ප්‍රමාණය (අක්/රූඩ්/පර්)'),
              ],
            ),
            if (records.isEmpty)
              TableRow(
                children: [
                  _buildTableCell('-'), _buildTableCell('-'), _buildTableCell('-'),
                  _buildTableCell('-'), _buildTableCell('-'), _buildTableCell('-'),
                ],
              ),
            ...records.map((row) {
              return TableRow(
                children: [
                  _buildTableCell(row['name']!),
                  _buildTableCell(row['phone']!),
                  _buildTableCell(row['familySize']!),
                  _buildTableCell(row['income']!),
                  _buildTableCell(row['aidAmount']!),
                  _buildTableCell(row['uncultivatedLand']!),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Center(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black, fontFamily: 'AbhayaLibre'))),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black, fontFamily: 'AbhayaLibre')),
    );
  }
}