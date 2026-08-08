import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncomeSourcesScreen extends StatefulWidget {
  final String surveyDocId;
  final String houseNumber;
  final String householderNic;

  const IncomeSourcesScreen({
    super.key,
    required this.surveyDocId,
    required this.houseNumber,
    required this.householderNic,
  });

  @override
  State<IncomeSourcesScreen> createState() => _IncomeSourcesScreenState();
}

class _IncomeSourcesScreenState extends State<IncomeSourcesScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // --- Form Controllers ---
  final TextEditingController _animalCountController = TextEditingController();

  // --- State Variables (Default Values) ---
  String _mainIncome = 'ඇත';
  String _additionalIncome = 'ඇත';
  String _job = 'රජයේ';
  String _tourism = 'පහසුකම් සැපයීම';
  String _agriculture = 'වී';
  String _animalHusbandry = 'කුකුළන්';
  String _fishingIndustry = 'මිරිදිය';

  // --- Dropdown Lists ---
  final List<String> _yesNoList = ['ඇත', 'නැත'];
  final List<String> _jobList = ['රජයේ', 'පුද්ගලික අංශයේ', 'අර්ධ රාජ්‍ය', 'විදෙස්', 'නැත'];
  final List<String> _tourismList = ['සේවා සැපයීම', 'පහසුකම් සැපයීම', 'වෙනත්', 'නැත'];
  final List<String> _agricultureList = ['තේ', 'වී', 'රබර්', 'පොල්', 'වෙනත්', 'නැත'];
  final List<String> _animalList = ['ඌරන්', 'කුකුළන්', 'හරකුන්', 'එළුවන්', 'වෙනත්', 'නැත'];
  final List<String> _fishingList = ['කරදිය', 'මිරිදිය', 'සුරතල් මසුන්', 'නැත'];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadIncomeData();
  }

  // 🔥 Previous Data Load (Auto-fill)
  Future<void> _loadIncomeData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('survey_responses')
          .doc(widget.surveyDocId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        final income = data['incomeSources'] as Map<String, dynamic>?;

        if (income != null) {
          setState(() {
            _mainIncome = income['mainIncome'] ?? 'ඇත';
            _additionalIncome = income['additionalIncome'] ?? 'ඇත';
            _job = income['job'] ?? 'රජයේ';
            _tourism = income['tourism'] ?? 'පහසුකම් සැපයීම';
            _agriculture = income['agriculture'] ?? 'වී';
            _animalHusbandry = income['animalHusbandry'] ?? 'කුකුළන්';
            _animalCountController.text = income['animalCount'] ?? '';
            _fishingIndustry = income['fishingIndustry'] ?? 'මිරිදිය';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading income data: $e');
    }
  }

  @override
  void dispose() {
    _animalCountController.dispose();
    super.dispose();
  }

  // 🔥 Save Logic and Navigate to Next Page
  Future<void> _saveAndContinue() async {
    setState(() => _isSaving = true);

    try {
      DocumentReference surveyRef = FirebaseFirestore.instance
          .collection('survey_responses')
          .doc(widget.surveyDocId);

      // Data Structure for Income Sources
      Map<String, dynamic> stepData = {
        'incomeSources': {
          'mainIncome': _mainIncome,
          'additionalIncome': _additionalIncome,
          'job': _job,
          'tourism': _tourism,
          'agriculture': _agriculture,
          'animalHusbandry': _animalHusbandry,
          'animalCount': _animalCountController.text.trim(),
          'fishingIndustry': _fishingIndustry,
        },
        'surveyStatus': 'income_completed',
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await surveyRef.set(stepData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ආදායම් මාර්ග දත්ත සාර්ථකව සුරකින ලදී!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to the next page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NextScreen(surveyDocId: widget.surveyDocId),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving income details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('දත්ත සුරැකීමේ දෝෂයක් සිදු විය.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- UI Helper Methods ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 12.0),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'UN-Imanee',
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // Ensure current value exists in the list to prevent errors
    final safeValue = items.contains(value) ? value : items.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.lightBlue, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val, style: const TextStyle(fontFamily: 'UN-Imanee')),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.lightBlue, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.lightBlue, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF03A9F4)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'ආදායම් මාර්ග',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'UN-Imanee',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balancing space for icon
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Section 1: Main Income ---
                  _buildLabel('ප්‍රධාන ආදායම් මාර්ග'),
                  _buildDropdown(
                    value: _mainIncome,
                    items: _yesNoList,
                    onChanged: (val) => setState(() => _mainIncome = val!),
                  ),

                  // --- Section 2: Additional Income ---
                  _buildLabel('අමතර ආදායම් මාර්ග'),
                  _buildDropdown(
                    value: _additionalIncome,
                    items: _yesNoList,
                    onChanged: (val) => setState(() => _additionalIncome = val!),
                  ),

                  // --- Section 3: Job ---
                  _buildLabel('රැකියාව'),
                  _buildDropdown(
                    value: _job,
                    items: _jobList,
                    onChanged: (val) => setState(() => _job = val!),
                  ),

                  // --- Section 4: Tourism ---
                  _buildLabel('සංචාරක'),
                  _buildDropdown(
                    value: _tourism,
                    items: _tourismList,
                    onChanged: (val) => setState(() => _tourism = val!),
                  ),

                  // --- Section 5: Agriculture ---
                  _buildLabel('කෘෂිකාර්මික'),
                  _buildDropdown(
                    value: _agriculture,
                    items: _agricultureList,
                    onChanged: (val) => setState(() => _agriculture = val!),
                  ),

                  // --- Section 6: Animal Husbandry ---
                  _buildLabel('සත්ත්ව කර්මාන්තය'),
                  _buildDropdown(
                    value: _animalHusbandry,
                    items: _animalList,
                    onChanged: (val) => setState(() => _animalHusbandry = val!),
                  ),

                  // --- Section 7: Animal Count (Text Field) ---
                  _buildLabel('සතුන් ගණන'),
                  _buildTextField(
                    controller: _animalCountController,
                    hintText: 'සතුන් ගණන ඇතුලත් කරන්න',
                    keyboardType: TextInputType.number,
                  ),

                  // --- Section 8: Fishing Industry ---
                  _buildLabel('ධීවර කර්මාන්තය'),
                  _buildDropdown(
                    value: _fishingIndustry,
                    items: _fishingList,
                    onChanged: (val) => setState(() => _fishingIndustry = val!),
                  ),
                  
                  const SizedBox(height: 40),

                  // --- Next Page / Save Button ---
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC2185B), // Matching UI color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveAndContinue,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white),
                              )
                            : const Text(
                                'ඊළඟ පිටුවට',
                                style: TextStyle(
                                  fontFamily: 'UN-Imanee',
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Placeholder for the Next Screen ---
class NextScreen extends StatelessWidget {
  final String surveyDocId;
  const NextScreen({super.key, required this.surveyDocId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ඊළඟ පිටුව')),
      body: Center(
        child: Text('Next Page logic for Doc ID: $surveyDocId'),
      ),
    );
  }
}