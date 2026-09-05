import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'gn_summary_view_model.dart'; 

class GNSummaryReportScreen extends StatelessWidget {
  const GNSummaryReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GNSummaryViewModel(),
      child: const _GNSummaryReportView(),
    );
  }
}

class _GNSummaryReportView extends StatefulWidget {
  const _GNSummaryReportView();

  @override
  State<_GNSummaryReportView> createState() => _GNSummaryReportViewState();
}

class _GNSummaryReportViewState extends State<_GNSummaryReportView> {
  bool _isDownloading = false;
  final GlobalKey _pdfTableKey = GlobalKey(); 

  Future<void> _downloadPDF(GNSummaryViewModel vm) async {
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
          pageFormat: PdfPageFormat.a4, 
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(imageProvider));
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      await Printing.sharePdf(bytes: pdfBytes, filename: '${vm.selectedGN}_Summary_Report.pdf');

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
    final vm = context.watch<GNSummaryViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        title: const Text('GN Division Data Explorer', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Stack(
        children: [
          vm.isLoadingGNs
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select GN Division to Generate Full Report',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  hint: const Text('Select GN Division'),
                                  value: vm.selectedGN,
                                  isExpanded: true,
                                  items: vm.gnDivisions.map((gn) => DropdownMenuItem(value: gn, child: Text(gn))).toList(),
                                  onChanged: (val) {
                                    if (val != null) vm.generateReport(val);
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: vm.selectedGN == null || vm.isGenerating 
                                ? null 
                                : () => vm.generateReport(vm.selectedGN!),
                            icon: vm.isGenerating 
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.analytics_rounded),
                            label: Text(vm.isGenerating ? 'Loading...' : 'Refresh'),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      if (vm.reportData.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'සාරාංශ තොරතුරු (Summary Data)',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50), fontFamily: 'UNSamantha'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isDownloading ? null : () => _downloadPDF(vm),
                              icon: _isDownloading 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706)))
                                : const Icon(Icons.download_rounded),
                              label: Text(_isDownloading ? 'Processing...' : 'Download PDF', style: const TextStyle(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFD97706), side: const BorderSide(color: Color(0xFFD97706))),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildSummaryCards(vm),
                        
                        const SizedBox(height: 24),
                        const Divider(thickness: 2),
                        const SizedBox(height: 12),
                        
                        const Text(
                          'සවිස්තරාත්මක පවුල් තොරතුරු (Family Detailed Data)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50), fontFamily: 'UNSamantha'),
                        ),
                        const SizedBox(height: 16),

                        _buildFilterSection(context, vm),
                        const SizedBox(height: 16),

                        Expanded(
                          child: vm.displayedFamilies.isEmpty 
                            ? const Center(child: Text('ගැලපෙන දත්ත කිසිවක් හමු නොවීය.'))
                            : ListView.builder(
                                itemCount: vm.displayedFamilies.length,
                                itemBuilder: (context, index) {
                                  return _buildFamilyCard(vm.displayedFamilies[index]);
                                },
                              ),
                        ),
                      ] else if (!vm.isGenerating && vm.selectedGN != null) ...[
                        const Expanded(
                          child: Center(
                            child: Text('No data found for this GN Division.', style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),

          if (vm.reportData.isNotEmpty)
            Positioned(
              left: -99999, 
              child: RepaintBoundary(
                key: _pdfTableKey,
                child: Container(
                  width: 900, 
                  color: Colors.white,
                  padding: const EdgeInsets.all(40),
                  child: _buildPdfReportLayout(vm),
                ),
              ),
            ),
            
          if (_isDownloading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
            ),
        ],
      ),
    );
  }

  Widget _buildPdfReportLayout(GNSummaryViewModel vm) {
    final d = vm.reportData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('ප්‍රජා ශක්ති දිළිඳු බව තුරන් කිරීමේ ජාතික ව්‍යාපාරය', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'AbhayaLibre')),
        const SizedBox(height: 6),
        const Text('ග්‍රාම නිලධාරී වසම් මට්ටමින් තොරතුරු ලබා ගැනීම', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'AbhayaLibre')),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ප්‍රාදේශීය ලේකම් කොට්ඨාශය: ..........................', style: TextStyle(fontSize: 16, color: Colors.black, fontFamily: 'AbhayaLibre')),
            Text('ග්‍රාම නිලධාරී වසම: ${vm.selectedGN}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'AbhayaLibre')),
          ],
        ),
        const SizedBox(height: 16),
        Container(height: 2, color: Colors.black),
        const SizedBox(height: 24),

        Table(
          border: TableBorder.all(color: Colors.black, width: 1.0),
          columnWidths: const {
            0: FlexColumnWidth(3.0),
            1: FlexColumnWidth(2.0),
          },
          children: [
            _buildTableRow('1. මුළු පවුල් ගණන', d['totalFamilies']?.toString() ?? '0'),
            _buildTableRow('     • මුළු ජනගහනය', d['totalPopulation']?.toString() ?? '0'),
            _buildTableRow('     • ස්ත්‍රී / පුරුෂ', 'ස්ත්‍රී: ${d['totalFemale']} | පුරුෂ: ${d['totalMale']}'),
            _buildTableRow('     • ජාතිය', 'සිංහල: ${d['sinhala']} | දමිළ: ${d['tamil']} | මුස්ලිම්: ${d['muslim']}'),
            _buildTableRow('2. කාන්තා මූලික පවුල් ගණන', d['femaleHeaded']?.toString() ?? '0'),
            _buildTableRow('3. විශේෂ අවශ්‍යතා සහිත පවුල් ගණන', d['specialNeeds']?.toString() ?? '0'),
            _buildTableRow('4. අස්වැසුම ප්‍රතිලාභීන් ගණන', d['aswasuma']?.toString() ?? '0'),
            _buildTableRow('5. ආදායම් මාර්ගයක් නොමැති පවුල් ගණන (රජයේ ආධාර ලබන)', d['noIncomeGovtAid']?.toString() ?? '0'),
            _buildTableRow('6. ආදායම් මාර්ගයක් නොමැති පවුල් ගණන (රජයේ ආධාර නොලබන)', d['noIncomeNoGovtAid']?.toString() ?? '0'),
            _buildTableRow('7. වෘත්තීය දැනුමක් සහිත නඟා සිටුවිය යුතු පවුල් ගණන', 'තොරතුරු නොමැත'),
            _buildTableRow('8. ඌන උපයෝජිත සම්පත් සහිත පවුල් ගණන', 'තොරතුරු නොමැත'),
            _buildTableRow('9. වසමට අනන්‍ය වු සංවර්ධනය කළ හැකි කර්මාන්ත', 'තොරතුරු නොමැත'),
            _buildTableRow('10. නිවාස පහසුකම් නොමැති පවුල් ගණන', d['noHousingCount']?.toString() ?? '0'),
            _buildTableRow('11. විදුලිය හා ජල පහසුකම් නොමැති පවුල් ගණන', d['noWaterPowerCount']?.toString() ?? '0'),
            _buildTableRow('12. වතු නිවාස ගණන', 'තොරතුරු නොමැත'),
            _buildTableRow('13. වැවිලි කර්මාන්තයේ නිරත පවුල් ගණන', 'තොරතුරු නොමැත'),
            _buildTableRow('14. සංචාරක කර්මාන්තය නගා සිටුවීම සඳහා ඇති අවස්ථාවන්', 'තොරතුරු නොමැත'),
            _buildTableRow('15. කෘෂිකාර්මික පවුල් ගණන', d['agriFamilies']?.toString() ?? '0'),
            _buildTableRow('16. සංවර්ධනය කළ යුතු වාරි මාර්ග පද්ධති ගණන (ඇළ මාර්ග)', d['canalsCount']?.toString() ?? '0'),
            _buildTableRow('17. සත්ත්ව නිෂ්පාදනයට අදාළ රැකියාවල නිරත පවුල් ගණන', d['animalFamilies']?.toString() ?? '0'),
            _buildTableRow('18. ධීවර ක්ෂේත්‍රයට අදාළ රැකියාවල නිරත පවුල් ගණන', d['fishingFamilies']?.toString() ?? '0'),
            _buildTableRow('19. සංවර්ධනය කළ යුතු වෙනත් රැකියාවල නිරත පවුල් ගණන', 'තොරතුරු නොමැත'),
            _buildTableRow('20. අධ්‍යාපනය (පාසල් නොයන ළමුන් ගණන)', d['dropouts']?.toString() ?? '0'),
            _buildTableRow('21. පාසල් හැර ගිය දරුවන් ගණන', d['dropouts']?.toString() ?? '0'),
            _buildTableRow('22. උසස් අධ්‍යාපනයට යොමු නොවූ වෘත්තිය අධ්‍යාපනයට යොමු කළ හැකි පවුල්', 'තොරතුරු නොමැත'),
            _buildTableRow('23. වසමේ ඇති ප්‍රජා ශාලා ගණන', d['communityHallsCount']?.toString() ?? '0'),
            _buildTableRow('24. පවතින වන සත්ත්ව උවදුරු මොනවාද', 'තොරතුරු නොමැත'),
            _buildTableRow('25. සංවර්ධනය විය යුතු අංශයන් හා යෝජිත විසඳුම්', 'තොරතුරු නොමැත'),
            _buildTableRow('26. වසමේ සංවර්ධනය විය යුතු මාර්ග (කි.මි. ගණන)', d['totalRoadDistance']?.toString() ?? '0'),
            _buildTableRow('27. විශේෂ කර්මාන්තයක් ආරම්භ කිරිමට කැමත්තක් දක්වන පුද්ගලයින්', 'තොරතුරු නොමැත'),
            _buildTableRow('28. සමාජ විරෝධි ක්‍රියාකාරකම් පිළිබඳ තොරතුරු (පවුල් ගණන)', d['antiSocial']?.toString() ?? '0'),
            
            // 🟢 Disasters Info
            _buildTableRow('29. ආපදා තොරතුරු', d['disasterInfo']?.toString() ?? 'තොරතුරු නොමැත'),
          ],
        ),
      ],
    );
  }

  TableRow _buildTableRow(String title, String value) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Text(title, style: const TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'AbhayaLibre'))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Text(value, style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'AbhayaLibre'))),
      ]
    );
  }

  Widget _buildSummaryCards(GNSummaryViewModel vm) {
    final data = vm.reportData;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _summaryBox('මුළු පවුල්', data['totalFamilies']?.toString() ?? '0', Icons.home_rounded, Colors.blue),
          _summaryBox('මුළු ජනගහනය', data['totalPopulation']?.toString() ?? '0', Icons.groups_rounded, Colors.green),
          _summaryBox('ස්ත්‍රී/පුරුෂ', 'ස්: ${data['totalFemale']} | පු: ${data['totalMale']}', Icons.wc_rounded, Colors.purple),
          _summaryBox('නිවාස නොමැති', data['noHousingCount']?.toString() ?? '0', Icons.house_outlined, Colors.brown),
          _summaryBox('විදුලිය/ජලය නැති', data['noWaterPowerCount']?.toString() ?? '0', Icons.water_drop_outlined, Colors.blueGrey),
          _summaryBox('අස්වැසුම ලබන', data['aswasuma']?.toString() ?? '0', Icons.monetization_on_rounded, Colors.orange),
        ],
      ),
    );
  }

  Widget _summaryBox(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontFamily: 'UNGanganee')),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, GNSummaryViewModel vm) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'ගෘහ මූලික අංකය, නම හෝ ජා.හැ.අ...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (val) => vm.applyFilters(val, vm.selectedFilter),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: vm.selectedFilter,
                isExpanded: true,
                style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold, fontFamily: 'UNGanganee'),
                items: vm.filterOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (val) {
                  if (val != null) vm.applyFilters(vm.searchQuery, val);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyCard(Map<String, dynamic> familyData) {
    final basic = familyData['basicDetails'] as Map<String, dynamic>? ?? {};
    final houseNo = familyData['houseNumber'] ?? 'Unknown';
    final headName = basic['headName'] ?? 'No Name';
    final isAswasuma = familyData['hasAswasuma'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ExpansionTile(
        shape: const Border(), 
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isAswasuma ? Colors.orange.shade100 : Colors.blue.shade100,
          child: Text(houseNo.toString(), style: TextStyle(color: isAswasuma ? Colors.orange.shade800 : Colors.blue.shade800, fontWeight: FontWeight.bold)),
        ),
        title: Text(headName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text('NIC: ${basic['nic'] ?? '-'} | ජාතිය: ${basic['nationality'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (basic['hasAntiSocialActivities'] == true)
                  _alertBox('සමාජ විරෝධී ක්‍රියා: ${basic['antiSocialDescription'] ?? 'ඔව්'}'),
                  
                if ((familyData['specialNeedsCount'] ?? 0) > 0)
                  _infoBox('විශේෂ අවශ්‍යතා: පුද්ගලයින් ${familyData['specialNeedsCount']} (රු.${familyData['specialNeedsAmount']}) - ${familyData['specialNeedDescription']}'),

                const SizedBox(height: 12),
                const Text('පවුලේ සාමාජිකයන්ගේ සංවේදී තොරතුරු', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'UNSamantha', color: Colors.blueGrey)),
                const Divider(),
                
                ...(basic['members'] as List<dynamic>? ?? []).map((member) {
                  return _buildMemberDetailCard(member as Map<String, dynamic>);
                }),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMemberDetailCard(Map<String, dynamic> m) {
    final String ageDisplay = m['ageDisplay']?.toString() ?? 'නොදනී';
    final int? calculatedAge = m['calculatedAge'] as int?;
    
    String nicDisplay = (m['nic'] != null && m['nic'].toString().trim().isNotEmpty && m['nic'] != '-') 
        ? m['nic'].toString() 
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(m['fullName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text(m['relationship'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Colors.black87, fontFamily: 'UNGanganee'),
              children: [
                const TextSpan(text: 'වයස: '),
                TextSpan(
                  text: ageDisplay,
                  style: TextStyle(
                    color: calculatedAge == null ? Colors.red.shade700 : Colors.black87,
                    fontWeight: calculatedAge == null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                TextSpan(text: ' | ස්ත්‍රී/පුරුෂ: ${m['gender']} | NIC: $nicDisplay'),
              ],
            ),
          ),
          
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (m['attendsSchool'] == true) _tag('පාසල් යයි', Colors.green),
              if (m['isAdult'] == false && m['attendsSchool'] == false && (calculatedAge ?? 0) > 5) _tag('පාසල් නොයන ළමයෙකි', Colors.red),
              
              if (m['hasSpecialNeeds'] == true) _tag('විශේෂ අවශ්‍යතා', Colors.orange),
              if (m['hasVisualNeed'] == true) _tag('දෘශ්‍යාබාධිත', Colors.orange),
              if (m['hasAudioNeed'] == true) _tag('ශ්‍රවණාබාධිත', Colors.orange),
              
              if (m['receivesGovtAssistance'] == true) _tag('රජයේ ආධාර ලබයි', Colors.blue),
              if ((m['disabilityAllowance'] ?? 0) > 0) _tag('ආබාධිත දීමනාව: රු.${m['disabilityAllowance']}', Colors.teal),
              if ((m['chronicIllnessAllowance'] ?? 0) > 0) _tag('රෝගී දීමනාව: රු.${m['chronicIllnessAllowance']}', Colors.teal),
              
              if (m['hasAntiSocialActivities'] == true) _tag('සමාජ විරෝධී: ${m['antiSocialDescription']}', Colors.red),
            ],
          )
        ],
      ),
    );
  }

  Widget _alertBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.red.shade200)),
      child: Text(text, style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.orange.shade200)),
      child: Text(text, style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _tag(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: color.shade200)),
      child: Text(text, style: TextStyle(fontSize: 10, color: color.shade700, fontWeight: FontWeight.bold)),
    );
  }
}