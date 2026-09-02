
import 'package:flutter/material.dart';

class MemberDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data; // මුල් පිටුවෙන් එවන සම්පූර්ණ දත්ත (Raw Data)

  const MemberDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // දත්ත වෙන් කරගැනීම
    final basicDetails = data['basicDetails'] as Map<String, dynamic>? ?? {};
    final housingDetails = data['housingDetails'] as Map<String, dynamic>? ?? {};
    final incomeDetails = data['incomeDetails'] as Map<String, dynamic>? ?? {};
    final members = data['members'] as List<dynamic>? ?? [];
    final children = basicDetails['children'] as List<dynamic>? ?? [];

    final headName = basicDetails['headName']?.toString() ?? data['fullName']?.toString() ?? 'නමක් නැත';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: const Text('සම්පූර්ණ තොරතුරු', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // නම පෙන්වන ප්‍රධාන කොටස
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text('ගෘහ මූලික අංකය: ${data['houseNumber'] ?? basicDetails['houseNumber'] ?? '-'}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildSectionTitle('මූලික තොරතුරු'),
            _buildTable([
              ['ජාතිය', basicDetails['nationality']?.toString() ?? '-'],
              ['ජා.හැ. අංකය', basicDetails['nic']?.toString() ?? '-'],
              ['දුරකථන අංකය', basicDetails['phone']?.toString() ?? '-'],
              ['ලිපිනය (GN වසම)', data['gn_division']?.toString() ?? basicDetails['gn_division']?.toString() ?? '-'],
              ['අස්වැසුම ලබනවාද?', data['hasAswasuma'] == true || basicDetails['hasAswasuma'] == true ? 'ඔව්' : 'නැත'],
              ['විශේෂ අවශ්‍යතා දීමනා', data['specialNeedsAmount']?.toString() ?? '0'],
            ]),

            _buildSectionTitle('නිවාස සහ පහසුකම්'),
            _buildTable([
              ['නිවසක් තිබේද?', housingDetails['hasHouse'] == true ? 'ඔව්' : 'නැත'],
              ['නිවසේ ස්වභාවය', housingDetails['nature']?.toString() ?? '-'],
              ['විදුලිය', housingDetails['electricity']?.toString() ?? '-'],
              ['ජල පහසුකම්', housingDetails['water']?.toString() ?? '-'],
              ['වැසිකිළි පහසුකම්', housingDetails['sanitation']?.toString() ?? '-'],
              ['දුරකථන සංඥා (Signal)', housingDetails['signal']?.toString() ?? '-'],
            ]),

            _buildSectionTitle('ආදායම් සහ රැකියා'),
            _buildTable([
              ['ප්‍රධාන ආදායම', incomeDetails['mainIncome']?.toString() ?? '-'],
              ['අමතර ආදායම', incomeDetails['extraIncome']?.toString() ?? '-'],
              ['රැකියාවේ ස්වභාවය', incomeDetails['jobType']?.toString() ?? '-'],
              ['තනතුර', incomeDetails['jobPosition']?.toString() ?? '-'],
              ['ආයතනය', incomeDetails['jobInstitute']?.toString() ?? '-'],
              ['කෘෂිකර්මාන්තය', incomeDetails['agricultureType']?.toString() ?? '-'],
              ['සත්ත්ව පාලනය', incomeDetails['animalHusbandryType']?.toString() ?? '-'],
              ['සතුන් ප්‍රමාණය', incomeDetails['animalCount']?.toString() ?? '-'],
            ]),

            _buildSectionTitle('පවුලේ සාමාජිකයින් (${members.length})'),
            if (members.isEmpty) const Text('සාමාජිකයින් වාර්තා වී නැත', style: TextStyle(color: Colors.grey)),
            ...members.map((m) => _buildTable([
                  ['නම', m['fullName']?.toString() ?? '-'],
                  ['වයස', m['age']?.toString() ?? '-'],
                  ['ස්ත්‍රී/පුරුෂ භාවය', m['gender']?.toString() ?? '-'],
                  ['ජා.හැ. අංකය', m['nic']?.toString() ?? '-'],
                ], isMemberRecord: true)).toList(),

            if (children.isNotEmpty) ...[
              _buildSectionTitle('කුඩා ළමයින්ගේ තොරතුරු (${children.length})'),
              ...children.map((c) => _buildTable([
                    ['ළමයාගේ නම', c['name']?.toString() ?? '-'],
                    ['උපන් දිනය', c['dob']?.toString() ?? '-'],
                    ['පාසල් යනවාද?', c['attendsSchool'] == true ? 'ඔව්' : 'නැත'],
                    ['රජයේ ආධාර ලබනවාද?', c['receivesGovtAssistance'] == true ? 'ඔව්' : 'නැත'],
                  ], isMemberRecord: true)).toList(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
      ),
    );
  }

  Widget _buildTable(List<List<String>> rows, {bool isMemberRecord = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isMemberRecord ? 12 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Table(
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(2.0),
          },
          children: rows.map((row) {
            return TableRow(
              children: [
                Container(
                  color: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    row[0],
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    row[1].isEmpty ? '-' : row[1],
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}