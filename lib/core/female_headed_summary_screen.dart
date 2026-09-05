import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FemaleHeadedSummaryScreen extends StatefulWidget {
  const FemaleHeadedSummaryScreen({super.key});

  @override
  State<FemaleHeadedSummaryScreen> createState() => _FemaleHeadedSummaryScreenState();
}

class _FemaleHeadedSummaryScreenState extends State<FemaleHeadedSummaryScreen> {
  bool _isLoading = true;
  bool _isDownloading = false;
  final GlobalKey _pdfTableKey = GlobalKey();
  
  List<Map<String, dynamic>> _allRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  
  final TextEditingController _searchController = TextEditingController();
  String _selectedGN = "සියලුම GN වසම්";
  List<String> _gnList = ["සියලුම GN වසම්"];

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

  Future<void> _fetchData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('survey_responses').get();
      List<Map<String, dynamic>> extracted = [];
      Set<String> gnSet = {"සියලුම GN වසම්"};

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
            final gnDivision = data['gnDivision']?.toString() ?? basicDetails['gn_division']?.toString() ?? basicDetails['gnDivision']?.toString() ?? 'නොදනී';
            
            if (gnDivision != 'නොදනී' && gnDivision.isNotEmpty) {
              gnSet.add(gnDivision);
            }

            final aswasuma = data['hasAswasuma'] == true ? 'ඔව්' : 'නැත';
            
            final housingDetails = data['housingDetails'] as Map<String, dynamic>? ?? {};
            final hNature = housingDetails['nature']?.toString() ?? '-';
            final hWater = housingDetails['water']?.toString() ?? '-';
            final hElec = housingDetails['electricity']?.toString() ?? '-';
            final housingStr = 'ස්වභාවය: $hNature\nජලය: $hWater\nවිදුලිය: $hElec';

            final incomeDetails = data['incomeDetails'] as Map<String, dynamic>? ?? {};
            
            final mainIncome = incomeDetails['mainIncome']?.toString() ?? '-';
            final extraIncome = incomeDetails['extraIncome']?.toString() ?? '-';
            
            final jobType = incomeDetails['jobType']?.toString() ?? '-';
            final jobPosition = incomeDetails['jobPosition']?.toString() ?? '-';
            final jobInstitute = incomeDetails['jobInstitute']?.toString() ?? '-';
            
            String jobStr = '-';
            if (jobType != '-' && jobType.isNotEmpty) {
              jobStr = 'ක්ෂේත්‍රය: $jobType';
              if (jobPosition.isNotEmpty && jobPosition != '-') jobStr += '\nතනතුර: $jobPosition';
              if (jobInstitute.isNotEmpty && jobInstitute != '-') jobStr += '\nආයතනය: $jobInstitute';
            }

            final tourismType = incomeDetails['tourismType']?.toString() ?? '-';
            final tourismOther = incomeDetails['tourismOther']?.toString() ?? '';
            final tourismStr = tourismType != '-' && tourismType.isNotEmpty ? (tourismType == 'වෙනත්' ? 'සංචාරක: $tourismOther' : 'සංචාරක: $tourismType') : '-';

            final agricultureType = incomeDetails['agricultureType']?.toString() ?? '-';
            final agriOther = incomeDetails['agricultureOther']?.toString() ?? '';
            final agriStr = agricultureType != '-' && agricultureType.isNotEmpty ? (agricultureType == 'වෙනත්' ? 'කෘෂි: $agriOther' : 'කෘෂි: $agricultureType') : '-';

            final animalType = incomeDetails['animalHusbandryType']?.toString() ?? '-';
            final animalCount = incomeDetails['animalCount']?.toString() ?? '';
            final animalOther = incomeDetails['animalHusbandryOther']?.toString() ?? '';
            String animalStr = '-';
            if (animalType != '-' && animalType.isNotEmpty) {
              animalStr = animalType == 'වෙනත්' ? 'සත්ත්ව: $animalOther' : 'සත්ත්ව: $animalType';
              if (animalCount.isNotEmpty && animalCount != '-') animalStr += ' (සංඛ්‍යාව: $animalCount)';
            }

            final fishingType = incomeDetails['fishingType']?.toString() ?? '-';
            final fishingStr = fishingType != '-' && fishingType.isNotEmpty ? 'ධීවර: $fishingType' : '-';

            List<String> fullIncomeSummary = [];
            if (mainIncome != '-' && mainIncome.isNotEmpty) fullIncomeSummary.add('ප්‍රධාන ආදායම: $mainIncome');
            if (extraIncome != '-' && extraIncome.isNotEmpty) fullIncomeSummary.add('අමතර ආදායම: $extraIncome');
            if (jobStr != '-') fullIncomeSummary.add(jobStr);
            if (tourismStr != '-') fullIncomeSummary.add(tourismStr);
            if (agriStr != '-') fullIncomeSummary.add(agriStr);
            if (animalStr != '-') fullIncomeSummary.add(animalStr);
            if (fishingStr != '-') fullIncomeSummary.add(fishingStr);

            final finalIncomeStr = fullIncomeSummary.isNotEmpty ? fullIncomeSummary.join('\n') : '-';

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
              'houseNumber': houseNumber,
              'phone': phone,
              'finalIncomeStr': finalIncomeStr,
              'gn': gnDivision,
              'aswasuma': aswasuma,
              'housingStr': housingStr,
              'hasSchoolChildren': childNames.isNotEmpty ? 'ඔව්' : 'නැත',
              'childNames': childNames.isNotEmpty ? childNames.join(', ') : '-',
              'childGenders': childGenders.isNotEmpty ? childGenders.join(', ') : '-',
              'childAges': childAges.isNotEmpty ? childAges.join(', ') : '-',
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _allRecords = extracted;
          _gnList = gnSet.toList();
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> temp = _allRecords;
    final query = _searchController.text.trim().toLowerCase();
    
    temp = temp.where((record) {
      if (_selectedGN != "සියලුම GN වසම්" && record['gn'] != _selectedGN) {
        return false;
      }
      
      if (query.isNotEmpty) {
        final name = record['name'].toString().toLowerCase();
        final houseNo = record['houseNumber'].toString().toLowerCase();
        if (!name.contains(query) && !houseNo.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    setState(() {
      _filteredRecords = temp;
    });
  }

  Future<void> _generatePDF() async {
    if (_filteredRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to generate PDF.')),
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
            return pw.Center(
              child: pw.Image(imageProvider),
            );
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Female_Headed_Families_Detailed.pdf',
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
          'කාන්තා මූලික පවුල් - සවිස්තරාත්මක',
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
                  child: Column(
                    children: [
                      // Dropdown for GN
                      Container(
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
                      const SizedBox(height: 12),
                      // Search field
                      TextField(
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
                    ],
                  ),
                ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
                    : _filteredRecords.isEmpty
                        ? const Center(child: Text('ගැලපෙන දත්ත කිසිවක් හමු නොවීය.', style: TextStyle(color: Colors.grey)))
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
                                        'සම්පූර්ණ වාර්තා ගණන:',
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
                                      _buildSummaryRow(Icons.location_on_outlined, 'GN වසම:', record['gn']),
                                      _buildSummaryRow(Icons.home_outlined, 'ගෘහ මූලික අංකය:', record['houseNumber']),
                                      _buildSummaryRow(Icons.phone_outlined, 'දුරකථනය:', record['phone']),
                                      _buildSummaryRow(Icons.work_outline, 'ආදායම් මාර්ග සහ රැකියාව:', record['finalIncomeStr'].replaceAll('\n', ' | ')),
                                      _buildSummaryRow(Icons.monetization_on_outlined, 'අස්වැසුම:', record['aswasuma']),
                                      _buildSummaryRow(Icons.maps_home_work_outlined, 'නිවාස තත්ත්වය:', record['housingStr'].replaceAll('\n', ', ')),
                                      _buildSummaryRow(Icons.child_care_outlined, 'ළමයින් සිටීද?:', record['hasSchoolChildren']),
                                      if (record['childNames'] != '-')
                                        _buildSummaryRow(Icons.people_outline, 'ළමයින්:', record['childNames']),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),

          // PDF Table
          if (_filteredRecords.isNotEmpty)
            Positioned(
              left: -99999,
              child: RepaintBoundary(
                key: _pdfTableKey,
                child: Container(
                  width: 1500,
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '1 ඇමුණුම් අංක 01 - GN: $_selectedGN',
                        style: const TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'AbhayaLibre'),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'කාන්තා මූලික පවුල් - සවිස්තරාත්මක ආදායම් සහ වෙනත් දත්ත',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'AbhayaLibre'),
                      ),
                      const SizedBox(height: 12),
                      Table(
                        border: TableBorder.all(color: Colors.black, width: 0.8),
                        columnWidths: const {
                          0: FlexColumnWidth(2.0),
                          1: FlexColumnWidth(1.0),
                          2: FlexColumnWidth(1.2),
                          3: FlexColumnWidth(2.5),
                          4: FlexColumnWidth(0.8),
                          5: FlexColumnWidth(1.8),
                          6: FlexColumnWidth(1.2),
                          7: FlexColumnWidth(1.8),
                          8: FlexColumnWidth(1.0),
                          9: FlexColumnWidth(0.8),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                            children: [
                              _buildTableHeaderCell('නම'),
                              _buildTableHeaderCell('ගෘහ මූලික අංකය'),
                              _buildTableHeaderCell('දුරකතන අංකය'),
                              _buildTableHeaderCell('ආදායම් මාර්ග සහ රැකියාව'),
                              _buildTableHeaderCell('අස්වැසුම'),
                              _buildTableHeaderCell('නිවාස පහසුකම්'),
                              _buildTableHeaderCell('පාසල් යන වයසේ\nළමයින් සිටීද?'),
                              _buildTableHeaderCell('ළමයින්ගේ නම්'),
                              _buildTableHeaderCell('ස්ත්‍රී/පුරුෂ බව'),
                              _buildTableHeaderCell('වයස'),
                            ],
                          ),
                          ..._filteredRecords.map((row) {
                            return TableRow(
                              children: [
                                _buildTableCell(row['name']!),
                                _buildTableCell(row['houseNumber']!),
                                _buildTableCell(row['phone']!),
                                _buildTableCell(row['finalIncomeStr']!),
                                _buildTableCell(row['aswasuma']!),
                                _buildTableCell(row['housingStr']!),
                                _buildTableCell(row['hasSchoolChildren']!),
                                _buildTableCell(row['childNames']!.replaceAll(', ', '\n')),
                                _buildTableCell(row['childGenders']!.replaceAll(', ', '\n')),
                                _buildTableCell(row['childAges']!.replaceAll(', ', '\n')),
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
            width: 140,
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