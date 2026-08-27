import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminLocationManagerScreen extends StatefulWidget {
  const AdminLocationManagerScreen({super.key});

  @override
  State<AdminLocationManagerScreen> createState() =>
      _AdminLocationManagerScreenState();
}

class _AdminLocationManagerScreenState
    extends State<AdminLocationManagerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSeeding = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Predefined default seed data
  final List<Map<String, dynamic>> _seedDataset = [
    {
      'district_en': 'Matara',
      'district_si': 'මාතර',
      'name_en': 'Matara Municipal Council',
      'name_si': 'මාතර මහ නගර සභාව',
      'gn_divisions': [
        {'si': 'කොටුවේගොඩ (416)', 'en': 'Kotewegoda (416)'},
        {'si': 'නූපේ (416A)', 'en': 'Nupe (416A)'},
        {'si': 'ඉසදීන් නගරය (416B)', 'en': 'Isadeen Town (416B)'},
        {'si': 'උයන්වත්ත (415)', 'en': 'Uyanwatta (415)'},
        {'si': 'උයන්වත්ත උතුර (415A)', 'en': 'Uyanwatta North (415A)'},
        {'si': 'උයන්වත්ත දකුණ (415B)', 'en': 'Uyanwatta South (415B)'},
        {'si': 'පොල්හේන (417)', 'en': 'Polhena (417)'},
        {'si': 'වල්ගම (418)', 'en': 'Walgama (418)'},
        {'si': 'වල්ගම උතුර (418A)', 'en': 'Walgama North (418A)'},
        {'si': 'වල්ගම මැද (418B)', 'en': 'Walgama Meda (418B)'},
        {'si': 'වල්ගම දකුණ (418C)', 'en': 'Walgama South (418C)'},
        {'si': 'වෙලේගොඩ නැගෙනහිර (419A)', 'en': 'Welegoda East (419A)'},
        {'si': 'වෙලේගොඩ බටහිර (419B)', 'en': 'Welegoda West (419B)'},
        {'si': 'හිත්බැටිය නැගෙනහිර (420A)', 'en': 'Hiththetiya East (420A)'},
        {'si': 'හිත්බැටිය මධ්‍යම (420B)', 'en': 'Hiththetiya Central (420B)'},
        {'si': 'හිත්බැටිය බටහිර (420C)', 'en': 'Hiththetiya West (420C)'},
        {'si': 'සුදර්ශී පෙදෙස (420D)', 'en': 'Sudarshi Place (420D)'},
        {'si': 'වල්පල නැගෙනහිර (414A)', 'en': 'Walpala East (414A)'},
        {'si': 'වල්පල බටහිර (414B)', 'en': 'Walpala West (414B)'},
        {'si': 'වැලිවේරිය නැගෙනහිර (413A)', 'en': 'Weliweriya East (413A)'},
        {'si': 'වැලිවේරිය බටහිර (413B)', 'en': 'Weliweriya West (413B)'},
        {'si': 'තුඩාව (412)', 'en': 'Tudawa (412)'},
        {'si': 'මැද්දවත්ත (423)', 'en': 'Meddawatta (423)'},
      ],
    },
    {
      'district_en': 'Matara',
      'district_si': 'මාතර',
      'name_en': 'Weligama Urban Council',
      'name_si': 'වැලිගම නගර සභාව',
      'gn_divisions': [
        {'si': 'මහ වීදිය (382)', 'en': 'Maha Weediya (382)'},
        {'si': 'පරණකඩේ (382A)', 'en': 'Paranakade (382A)'},
        {'si': 'හෙට්ටිවීදිය (382B)', 'en': 'Hettiweediya (382B)'},
        {'si': 'ගල්බොක්ක නැගෙනහිර (385)', 'en': 'Galbokka East (385)'},
        {'si': 'අලුත් වීදිය (385A)', 'en': 'Aluthweediya (385A)'},
        {'si': 'ගල්බොක්ක බටහිර (385B)', 'en': 'Galbokka West (385B)'},
        {'si': 'වල්ලිවල බටහිර (386A)', 'en': 'Walliwala West (386A)'},
        {'si': 'වල්ලිවල නැගෙනහිර (386B)', 'en': 'Walliwala East (386B)'},
        {'si': 'කප්පරතොට දකුණ (386C)', 'en': 'Kapparathota South (386C)'},
        {'si': 'කප්පරතොට උතුර (386D)', 'en': 'Kapparathota North (386D)'},
        {'si': 'පැලෑන නැගෙනහිර (387)', 'en': 'Pelena East (387)'},
        {'si': 'පැලෑන බටහිර (387A)', 'en': 'Pelena West (387A)'},
        {'si': 'කොහුණුගමුව (389)', 'en': 'Kohunugamuwa (389)'},
      ],
    },
    {
      'district_en': 'Matara',
      'district_si': 'මාතර',
      'name_en': 'Matara Pradeshiya Sabha',
      'name_si': 'මාතර ප්‍රාදේශීය සභාව',
      'gn_divisions': [
        {'si': 'කැකණදුර (420)', 'en': 'Kekanadura (420)'},
        {'si': 'තලල්ල උතුර (421A)', 'en': 'Talalla North (421A)'},
        {'si': 'තලල්ල දකුණ (421B)', 'en': 'Talalla South (421B)'},
        {'si': 'නාඩියගහවත්ත (422)', 'en': 'Nadiyagahawatta (422)'},
        {'si': 'දියගහ (424)', 'en': 'Diyagaha (424)'},
        {'si': 'මකවිට (425)', 'en': 'Makavita (425)'},
        {'si': 'කොකාවල (426)', 'en': 'Kokawala (426)'},
        {'si': 'කුඹල්ගම (427)', 'en': 'Kubalgama (427)'},
        {'si': 'වෙහෙරහේන (428)', 'en': 'Weherahena (428)'},
        {'si': 'ගන්දර (429)', 'en': 'Gandara (429)'},
      ],
    },
    {
      'district_en': 'Matara',
      'district_si': 'මාතර',
      'name_en': 'Weligama Pradeshiya Sabha',
      'name_si': 'වැලිගම ප්‍රාදේශීය සභාව',
      'gn_divisions': [
        {'si': 'මිරිස්ස දකුණ (391)', 'en': 'Mirissa South (391)'},
        {'si': 'මිරිස්ස උතුර (392)', 'en': 'Mirissa North (392)'},
        {'si': 'කඹුරුගමුව උතුර (408)', 'en': 'Kamburugamuwa North (408)'},
        {'si': 'කඹුරුගමුව දකුණ (409)', 'en': 'Kamburugamuwa South (409)'},
        {'si': 'දෙණිපිටිය උතුර (395)', 'en': 'Denipitiya North (395)'},
        {'si': 'දෙණිපිටිය දකුණ (396)', 'en': 'Denipitiya South (396)'},
        {'si': 'වැලිපිටිය (398)', 'en': 'Welipitiya (398)'},
        {'si': 'පැලෑන උතුර (388)', 'en': 'Pelena North (388)'},
        {'si': 'මිද්දෙණිය (399)', 'en': 'Middeniya (399)'},
      ],
    },
    {
      'district_en': 'Matara',
      'district_si': 'මාතර',
      'name_en': 'Akuressa Pradeshiya Sabha',
      'name_si': 'අකුරැස්ස ප්‍රාදේශීය සභාව',
      'gn_divisions': [
        {'si': 'අකුරැස්ස (430)', 'en': 'Akuressa (430)'},
        {'si': 'මලිදූව (431)', 'en': 'Maliduwa (431)'},
        {'si': 'ඉඹුල්ගොඩ (432)', 'en': 'Imbulgoda (432)'},
        {'si': 'පොරඹ (433)', 'en': 'Poramba (433)'},
        {'si': 'හේනේගම බටහිර (434)', 'en': 'Henegama West (434)'},
        {'si': 'මිනීපෙගොඩ (435)', 'en': 'Minipegoda (435)'},
        {'si': 'මාරඹ (436)', 'en': 'Maramba (436)'},
        {'si': 'තලාගහගම (437)', 'en': 'Thalahagama (437)'},
        {'si': 'උරුමුත්ත (438)', 'en': 'Urumutta (438)'},
        {'si': 'හුලන්දාව (439)', 'en': 'Hulandawa (439)'},
        {'si': 'ලේනම (440)', 'en': 'Lenama (440)'},
        {'si': 'බෝපගොඩ (441)', 'en': 'Bopagoda (441)'},
      ],
    },
    {
      'district_en': 'Matara',
      'district_si': 'මාතර',
      'name_en': 'Athuraliya Pradeshiya Sabha',
      'name_si': 'අතුරලිය ප්‍රාදේශීය සභාව',
      'gn_divisions': [
        {'si': 'අතුරලිය (520)', 'en': 'Athuraliya (520)'},
        {'si': 'විල්පිට (521)', 'en': 'Wilpita (521)'},
        {'si': 'බාලකාවල (522)', 'en': 'Balakawala (522)'},
        {'si': 'පරදූව (523)', 'en': 'Paraduwa (523)'},
        {'si': 'ඇල්ගිරිය (524)', 'en': 'Elgiriya (524)'},
        {'si': 'මාරගොඩ (525)', 'en': 'Maragoda (525)'},
      ],
    },
    {
      'district_en': 'Matara',
      'district_si': 'මාතර',
      'name_en': 'Devinuwara Pradeshiya Sabha',
      'name_si': 'දෙවිනුවර ප්‍රාදේශීය සභාව',
      'gn_divisions': [
        {'si': 'දෙවිනුවර උතුර (480)', 'en': 'Devinuwara North (480)'},
        {'si': 'දෙවිනුවර දකුණ (481)', 'en': 'Devinuwara South (481)'},
        {'si': 'දෙවිනුවර නුගේගොඩ (482)', 'en': 'Devinuwara Nugegoda (482)'},
        {'si': 'සිංහාසන (483)', 'en': 'Sinhasana (483)'},
        {'si': 'කපුගම මධ්‍යම (484)', 'en': 'Kapugama Central (484)'},
        {'si': 'කපුගම උතුර (485)', 'en': 'Kapugama North (485)'},
        {'si': 'කොට්ටගොඩ (486)', 'en': 'Kottagoda (486)'},
        {'si': 'තල්පාවිල (487)', 'en': 'Thalpawila (487)'},
      ],
    },
    {
      'district_en': 'Matara',
      'district_si': 'මාතර',
      'name_en': 'Dickwella Pradeshiya Sabha',
      'name_si': 'දික්වැල්ල ප්‍රාදේශීය සභාව',
      'gn_divisions': [
        {'si': 'දික්වැල්ල උතුර (450)', 'en': 'Dickwella North (450)'},
        {'si': 'දික්වැල්ල දකුණ (451)', 'en': 'Dickwella South (451)'},
        {'si': 'පෙහෙබිය (452)', 'en': 'Pehebiya (452)'},
        {'si': 'බතිගම උතුර (453)', 'en': 'Batigama North (453)'},
        {'si': 'බතිගම දකුණ (454)', 'en': 'Batigama South (454)'},
        {'si': 'වලස්ගල බටහිර (455)', 'en': 'Walasgala West (455)'},
        {'si': 'වලස්ගල නැගෙනහිර (456)', 'en': 'Walasgala East (456)'},
        {'si': 'බෙලිහින්න (457)', 'en': 'Belihinna (457)'},
        {'si': 'රාදම්පොල (458)', 'en': 'Radampola (458)'},
        {'si': 'වෙහෙල්ල (459)', 'en': 'Wehella (459)'},
        {'si': 'උරුගමුව (460)', 'en': 'Urugamuwa (460)'},
      ],
    },
    {
      'district_en': 'Matara',
      'district_si': 'මාතර',
      'name_en': 'Hakmana Pradeshiya Sabha',
      'name_si': 'හක්මන ප්‍රාදේශීය සභාව',
      'gn_divisions': [
        {'si': 'හක්මන (470)', 'en': 'Hakmana (470)'},
        {'si': 'දෙනගම (471)', 'en': 'Denagama (471)'},
        {'si': 'ලැල්පේ (472)', 'en': 'Lalpe (472)'},
        {'si': 'හෙට්ටියාවල (473)', 'en': 'Hettiyawala (473)'},
        {'si': 'යටියන (474)', 'en': 'Yatiyana (474)'},
        {'si': 'මීඇල්ල (475)', 'en': 'Miella (475)'},
        {'si': 'කොළඹගේආර (476)', 'en': 'Kolambageara (476)'},
      ],
    },
    {
      'district_en': 'Matara',
      'district_si': 'මාතර',
      'name_en': 'Kamburupitiya Pradeshiya Sabha',
      'name_si': 'කඹුරුපිටිය ප්‍රාදේශීය සභාව',
      'gn_divisions': [
        {'si': 'කඹුරුපිටිය (490)', 'en': 'Kamburupitiya (490)'},
        {'si': 'අකුරුගොඩ (491)', 'en': 'Akurugoda (491)'},
        {'si': 'හොරගොඩ (492)', 'en': 'Horagoda (492)'},
        {'si': 'කිරිමැටිමුල්ල (493)', 'en': 'Kirimetimulla (493)'},
        {'si': 'මාපලාන (494)', 'en': 'Mapalana (494)'},
        {'si': 'තඹලගම (495)', 'en': 'Thambalagama (495)'},
      ],
    },
    {
      'district_en': 'Matara',
      'district_si': 'මාතර',
      'name_en': 'Kirinda Puhulwella Pradeshiya Sabha',
      'name_si': 'කිරින්ද පුහුල්වැල්ල ප්‍රාදේශීය සභාව',
      'gn_divisions': [
        {'si': 'කිරින්ද (530)', 'en': 'Kirinda (530)'},
        {'si': 'පුහුල්වැල්ල (531)', 'en': 'Puhulwella (531)'},
        {'si': 'බටුවිට (532)', 'en': 'Batuvita (532)'},
        {'si': 'විද්‍යානිකේත (533)', 'en': 'Vidyaniketha (533)'},
      ],
    },
    {
      'district_en': 'Matara',
      'district_si': 'මාතර',
      'name_en': 'Kotapola Pradeshiya Sabha',
      'name_si': 'කොටපොල ප්‍රාදේශීය සභාව',
      'gn_divisions': [
        {'si': 'කොටපොල (540)', 'en': 'Kotapola (540)'},
        {'si': 'දෙනියාය (541)', 'en': 'Deniyaya (541)'},
        {'si': 'මොරවක (542)', 'en': 'Morawaka (542)'},
        {'si': 'කොළවෙනිගම (543)', 'en': 'Kolawenigama (543)'},
      ],
    },
    {
      'district_en': 'Matara',
      'district_si': 'මාතර',
      'name_en': 'Malimbada Pradeshiya Sabha',
      'name_si': 'මාලිම්බඩ ප්‍රාදේශීය සභාව',
      'gn_divisions': [
        {'si': 'මාලිම්බඩ උතුර (510)', 'en': 'Malimbada North (510)'},
        {'si': 'මාලිම්බඩ දකුණ (511)', 'en': 'Malimbada South (511)'},
        {'si': 'තෙලිජ්ජවිල (512)', 'en': 'Thelijjawila (512)'},
        {'si': 'සුල්තානාගොඩ (513)', 'en': 'Sulthanagoda (513)'},
        {'si': 'කෙටන්විල (514)', 'en': 'Ketanwila (514)'},
      ],
    },
    {
      'district_en': 'Matara',
      'district_si': 'මාතර',
      'name_en': 'Pasgoda Pradeshiya Sabha',
      'name_si': 'පස්ගොඩ ප්‍රාදේශීය සභාව',
      'gn_divisions': [
        {'si': 'පස්ගොඩ (550)', 'en': 'Pasgoda (550)'},
        {'si': 'රොටුඹ (552)', 'en': 'Rotumba (552)'},
        {'si': 'බෙංගමුව (553)', 'en': 'Bengamuwa (553)'},
      ],
    },
    {
      'district_en': 'Matara',
      'district_si': 'මාතර',
      'name_en': 'Pitabeddara Pradeshiya Sabha',
      'name_si': 'පිටබැද්දර ප්‍රාදේශීය සභාව',
      'gn_divisions': [
        {'si': 'පිටබැද්දර (560)', 'en': 'Pitabeddara (560)'},
        {'si': 'කලුවල (561)', 'en': 'Kaluwala (561)'},
        {'si': 'සියඹලාගොඩ (562)', 'en': 'Siyambalagoda (562)'},
        {'si': 'ඇලකන්ද (563)', 'en': 'Elakanda (563)'},
      ],
    },
    {
      'district_en': 'Matara',
      'district_si': 'මාතර',
      'name_en': 'Thihagoda Pradeshiya Sabha',
      'name_si': 'තිහගොඩ ප්‍රාදේශීය සභාව',
      'gn_divisions': [
        {'si': 'තිහගොඩ (500)', 'en': 'Thihagoda (500)'},
        {'si': 'කපුවත්ත (501)', 'en': 'Kapuwatta (501)'},
        {'si': 'නායිම්බල (502)', 'en': 'Naimbala (502)'},
        {'si': 'පාලටුව (503)', 'en': 'Palatuwa (503)'},
        {'si': 'යටියන නැගෙනහිර (504)', 'en': 'Yatiyana East (504)'},
      ],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Seed Database Action ---
  Future<void> _seedDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feed / Seed Data to Database?'),
        content: const Text(
          'This will feed all 16 Matara Local Authorities and their Grama Niladhari divisions into Firestore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSeeding = true);

    try {
      final batch = _firestore.batch();
      for (final item in _seedDataset) {
        final String docId = (item['name_en'] as String)
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '_');
        final docRef = _firestore.collection('local_authorities').doc(docId);
        batch.set(docRef, {
          ...item,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text(
              'Successfully fed 16 Local Authorities and GN divisions to Firestore!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to feed data: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  // --- Add New Local Authority Modal ---
  void _showAddLocalAuthorityDialog() {
    final nameEnController = TextEditingController();
    final nameSiController = TextEditingController();
    final districtEnController = TextEditingController(text: 'Matara');
    final districtSiController = TextEditingController(text: 'මාතර');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance, color: Color(0xFF1E88E5)),
                SizedBox(width: 8),
                Text(
                  'Add New Local Authority',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameEnController,
              decoration: InputDecoration(
                labelText: 'Local Authority Name (English)',
                hintText: 'e.g. Akuressa Pradeshiya Sabha',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameSiController,
              decoration: InputDecoration(
                labelText: 'Local Authority Name (Sinhala)',
                hintText: 'e.g. අකුරැස්ස ප්‍රාදේශීය සභාව',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: districtEnController,
                    decoration: InputDecoration(
                      labelText: 'District (English)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: districtSiController,
                    decoration: InputDecoration(
                      labelText: 'District (Sinhala)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final en = nameEnController.text.trim();
                  final si = nameSiController.text.trim();
                  final dEn = districtEnController.text.trim();
                  final dSi = districtSiController.text.trim();

                  if (en.isEmpty || si.isEmpty || dEn.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all required fields'),
                      ),
                    );
                    return;
                  }

                  final docId =
                      en.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
                  await _firestore
                      .collection('local_authorities')
                      .doc(docId)
                      .set({
                    'name_en': en,
                    'name_si': si,
                    'district_en': dEn,
                    'district_si': dSi,
                    'gn_divisions': [],
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF10B981),
                        content: Text('Local Authority added successfully!'),
                      ),
                    );
                  }
                },
                child: const Text('Save Local Authority'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DEDICATED GENERAL FEED GN DIVISION DIALOG ---
  void _showFeedGNDivisionDialog({String? preselectedDocId}) async {
    // Fetch all existing local authorities for dropdown selection
    final snapshot = await _firestore.collection('local_authorities').get();
    final List<Map<String, String>> authorities = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name_en': (data['name_en'] ?? doc.id).toString(),
        'name_si': (data['name_si'] ?? '').toString(),
      };
    }).toList();

    if (authorities.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please add or seed Local Authorities first before adding GN Divisions.',
            ),
          ),
        );
      }
      return;
    }

    String selectedDocId = preselectedDocId ?? authorities.first['id']!;
    final gnNameSiController = TextEditingController();
    final gnNameEnController = TextEditingController();
    final gnCodeController = TextEditingController();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: Color(0xFF1E88E5)),
                    SizedBox(width: 8),
                    Text(
                      'Feed / Add GN Division',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Local Authority Dropdown Selector
                DropdownButtonFormField<String>(
                  value: selectedDocId,
                  decoration: InputDecoration(
                    labelText: 'Select Local Authority',
                    prefixIcon: const Icon(Icons.account_balance,
                        color: Color(0xFF1E88E5), size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: authorities.map((auth) {
                    final si = auth['name_si']!;
                    final en = auth['name_en']!;
                    final display = si.isNotEmpty ? '$si ($en)' : en;
                    return DropdownMenuItem(
                      value: auth['id'],
                      child: Text(
                        display,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedDocId = val);
                    }
                  },
                ),

                const SizedBox(height: 12),

                // GN Division Name in Sinhala
                TextField(
                  controller: gnNameSiController,
                  decoration: InputDecoration(
                    labelText: 'GN Division Name (Sinhala)',
                    hintText: 'e.g. කොටුවේගොඩ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // GN Division Name in English
                TextField(
                  controller: gnNameEnController,
                  decoration: InputDecoration(
                    labelText: 'GN Division Name (English)',
                    hintText: 'e.g. Kotewegoda',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // GN Division Code / Number
                TextField(
                  controller: gnCodeController,
                  decoration: InputDecoration(
                    labelText: 'GN Division Number / Code (Optional)',
                    hintText: 'e.g. 416 or 416A',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final rawSi = gnNameSiController.text.trim();
                      final rawEn = gnNameEnController.text.trim();
                      final code = gnCodeController.text.trim();

                      if (rawSi.isEmpty || rawEn.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter both Sinhala and English GN Division names',
                            ),
                          ),
                        );
                        return;
                      }

                      // Format with code if provided: e.g. "Kotewegoda (416)"
                      final finalSi = code.isNotEmpty ? '$rawSi ($code)' : rawSi;
                      final finalEn = code.isNotEmpty ? '$rawEn ($code)' : rawEn;

                      await _firestore
                          .collection('local_authorities')
                          .doc(selectedDocId)
                          .update({
                        'gn_divisions': FieldValue.arrayUnion([
                          {'en': finalEn, 'si': finalSi}
                        ]),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text(
                              'GN Division "$finalSi" added successfully!',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Save & Feed GN Division'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Delete GN Division ---
  Future<void> _deleteGNDivision(
      String docId, Map<String, dynamic> gnItem) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete GN Division?'),
        content: Text('Remove "${gnItem['en']}" from database?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _firestore.collection('local_authorities').doc(docId).update({
      'gn_divisions': FieldValue.arrayRemove([gnItem]),
    });
  }

  // --- Delete Entire Local Authority ---
  Future<void> _deleteLocalAuthority(String docId, String nameEn) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Local Authority?'),
        content: Text(
          'Are you sure you want to delete "$nameEn" and all of its GN divisions permanently?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _firestore.collection('local_authorities').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Manage Signup Dropdown Data',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Top Action Header / Quick Seeder Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Database Feeder (Cloud Firestore)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Feed Local Authorities & GN Divisions to DB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFE0F2FE),
                            foregroundColor: const Color(0xFF0284C7),
                          ),
                          onPressed: _showAddLocalAuthorityDialog,
                          icon: const Icon(Icons.account_balance),
                          tooltip: 'Add Local Authority',
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFDCFCE7),
                            foregroundColor: const Color(0xFF15803D),
                          ),
                          onPressed: () => _showFeedGNDivisionDialog(),
                          icon: const Icon(Icons.add_location_alt_rounded),
                          tooltip: 'Feed / Add GN Division',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick Action Buttons Row
                Row(
                  children: [
                    // One-click Feed/Seed Button
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSeeding ? null : _seedDatabase,
                        icon: _isSeeding
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: Text(
                          _isSeeding ? 'Feeding Data...' : 'Feed Matara Data (16 LAs)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dedicated Feed GN Division Button
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF15803D)),
                          foregroundColor: const Color(0xFF15803D),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _showFeedGNDivisionDialog(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          '+ Feed GN Div',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search Local Authorities or GN divisions...',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF1E88E5), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),

          // Stream List of Local Authorities & GN Divisions
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('local_authorities').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading data: ${snapshot.error}'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.layers_clear_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No Local Authorities in Database yet.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap "Feed Matara Data" or "+ Feed GN Div" above.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Filter by search query
                final filteredDocs = docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data();
                  final en = (data['name_en'] ?? '').toString().toLowerCase();
                  final si = (data['name_si'] ?? '').toString().toLowerCase();
                  final q = _searchQuery.toLowerCase();

                  if (en.contains(q) || si.contains(q)) return true;

                  final List gnList = data['gn_divisions'] ?? [];
                  for (final item in gnList) {
                    if (item is Map) {
                      final itemEn =
                          (item['en'] ?? '').toString().toLowerCase();
                      final itemSi =
                          (item['si'] ?? '').toString().toLowerCase();
                      if (itemEn.contains(q) || itemSi.contains(q)) return true;
                    }
                  }
                  return false;
                }).toList();

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data();
                    final nameEn = (data['name_en'] ?? '').toString();
                    final nameSi = (data['name_si'] ?? '').toString();
                    final district = (data['district_en'] ?? '').toString();
                    final List gnDivisions = data['gn_divisions'] ?? [];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE0F2FE),
                          child: const Icon(Icons.account_balance,
                              color: Color(0xFF0284C7), size: 20),
                        ),
                        title: Text(
                          nameSi.isNotEmpty ? '$nameSi ($nameEn)' : nameEn,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Text(
                          'District: $district • ${gnDivisions.length} GN Divisions',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 20),
                          tooltip: 'Delete Local Authority',
                          onPressed: () =>
                              _deleteLocalAuthority(doc.id, nameEn),
                        ),
                        children: [
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'GN Divisions (${gnDivisions.length}):',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _showFeedGNDivisionDialog(
                                          preselectedDocId: doc.id),
                                      icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                                      label: const Text('Add GN Division',
                                          style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (gnDivisions.isEmpty)
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      'No GN divisions yet. Tap "Add GN Division" above.',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: gnDivisions.map((gn) {
                                      final gnMap =
                                          Map<String, dynamic>.from(gn as Map);
                                      final gnSi = gnMap['si'] ?? '';
                                      final gnEn = gnMap['en'] ?? '';
                                      return Chip(
                                        backgroundColor:
                                            const Color(0xFFF1F5F9),
                                        label: Text(
                                          '$gnSi\n$gnEn',
                                          style: const TextStyle(
                                              fontSize: 11, height: 1.2),
                                        ),
                                        deleteIcon: const Icon(
                                            Icons.close_rounded,
                                            size: 14),
                                        onDeleted: () =>
                                            _deleteGNDivision(doc.id, gnMap),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}