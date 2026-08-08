import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthDetailsScreen extends StatefulWidget {
  final String surveyDocId;
  final String houseNumber;
  final String householderNic;

  const HealthDetailsScreen({
    super.key,
    required this.surveyDocId,
    required this.houseNumber,
    required this.householderNic,
  });

  @override
  State<HealthDetailsScreen> createState() => _HealthDetailsScreenState();
}

class _HealthDetailsScreenState extends State<HealthDetailsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // --- Form Controllers ---
  final TextEditingController _diseasesController =
      TextEditingController(); // රෝගී
  final TextEditingController _careController =
      TextEditingController(); // සාත්තු
  final TextEditingController _medicalTreatmentController =
      TextEditingController(); // වෛද්‍ය ප්‍රතිකාර
  final TextEditingController _preventionController =
      TextEditingController(); // නිවාරණ
  final TextEditingController _medicalCheckupController =
      TextEditingController(); // වෛද්‍ය පරීක්ෂාව
  final TextEditingController _nutritionController =
      TextEditingController(); // පෝෂණ

  // --- State Variables (Booleans & Strings for Radio/Checkboxes) ---
  bool _hasMainDisability = false; // ප්‍රධාන ආබාධ මාර්ග
  bool _hasOtherDisability = false; // අනෙකුත් ආබාධ මාර්ග

  String _drinks = ''; // බීම (පානය කරන / පානය නොකරන)
  String _milk = ''; // කිරි (බොන / බොන්නේ නැත)
  String _alcohol = ''; // මත්පැන් (පානය කරන / පානය නොකරන)

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  // 🔥 Load previous health data from Firestore (Auto-fill)
  Future<void> _loadHealthData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('survey_responses')
          .doc(widget.surveyDocId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        final health = data['healthAndNutrition'] as Map<String, dynamic>?;

        if (health != null) {
          setState(() {
            _hasMainDisability = health['hasMainDisability'] ?? false;
            _hasOtherDisability = health['otherDisability'] ?? false;
            _diseasesController.text = health['diseases'] ?? '';
            _careController.text = health['careType'] ?? '';
            _medicalTreatmentController.text = health['medicalTreatment'] ?? '';
            _preventionController.text = health['prevention'] ?? '';
            _medicalCheckupController.text = health['medicalCheckup'] ?? '';
            _nutritionController.text = health['nutrition'] ?? '';
            _drinks = health['drinks'] ?? '';
            _milk = health['milk'] ?? '';
            _alcohol = health['alcohol'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading health data: $e');
    }
  }

  @override
  void dispose() {
    _diseasesController.dispose();
    _careController.dispose();
    _medicalTreatmentController.dispose();
    _preventionController.dispose();
    _medicalCheckupController.dispose();
    _nutritionController.dispose();
    super.dispose();
  }

  // 🔥 Save Logic: Clear data struct to 'survey_responses'
  Future<void> _saveHealthDetails() async {
    setState(() => _isSaving = true);

    try {
      DocumentReference surveyRef = FirebaseFirestore.instance
          .collection('survey_responses')
          .doc(widget.surveyDocId);

      // Step 4 දත්ත සකස් කිරීම
      Map<String, dynamic> step4Data = {
        'healthAndNutrition': {
          'hasMainDisability': _hasMainDisability,
          'otherDisability': _hasOtherDisability,
          'diseases': _diseasesController.text.trim(),
          'careType': _careController.text.trim(),
          'medicalTreatment': _medicalTreatmentController.text.trim(),
          'prevention': _preventionController.text.trim(),
          'medicalCheckup': _medicalCheckupController.text.trim(),
          'nutrition': _nutritionController.text.trim(),
          'drinks': _drinks,
          'milk': _milk,
          'alcohol': _alcohol,
        },
        'surveyStatus': 'step4_completed',
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await surveyRef.set(step4Data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('සියලුම සෞඛ්‍ය හා පෝෂණ දත්ත සාර්ථකව සුරකින ලදී!'),
            backgroundColor: Colors.green,
          ),
        );
        // අවසාන පිටුවට හෝ Dashboard එකට ගෙන යාම
        Navigator.popUntil(context, ModalRoute.withName('/'));
      }
    } catch (e) {
      debugPrint('Error saving health details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('දත්ත සුරැකීමේ අදෝෂයක් සිදු විය.'),
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

  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.lightBlue, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(String label, bool isChecked, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontFamily: 'UN-Imanee', fontSize: 14),
          ),
          const SizedBox(width: 8),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87),
              color: isChecked ? Colors.black87 : Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: isChecked
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        ],
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
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.lightBlue,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'සෞඛ්‍ය හා පෝෂණ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'UN-Imanee',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Section 1: Main Disability ---
                  _buildLabel('ප්‍රධාන ආබාධ මාර්ග'),
                  Row(
                    children: [
                      _buildCheckbox('ඇත', _hasMainDisability, () {
                        setState(() => _hasMainDisability = true);
                      }),
                      const SizedBox(width: 20),
                      _buildCheckbox('නැත', !_hasMainDisability, () {
                        setState(() => _hasMainDisability = false);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Section 2: Other Disability ---
                  _buildLabel('අනෙකුත් ආබාධ මාර්ග'),
                  Row(
                    children: [
                      _buildCheckbox('ඇත', _hasOtherDisability, () {
                        setState(() => _hasOtherDisability = true);
                      }),
                      const SizedBox(width: 20),
                      _buildCheckbox('නැත', !_hasOtherDisability, () {
                        setState(() => _hasOtherDisability = false);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Section 3: Diseases ---
                  _buildLabel('රෝගී'),
                  _buildTextField(
                    controller: _diseasesController,
                    hintText: 'රෝගී',
                  ),
                  const SizedBox(height: 16),

                  // --- Section 4: Care Type ---
                  _buildLabel('සාත්තු'),
                  _buildTextField(
                    controller: _careController,
                    hintText: 'පාලනය කිරීම',
                  ),
                  const SizedBox(height: 16),

                  // --- Section 5: Medical Treatment ---
                  _buildLabel('වෛද්‍ය ප්‍රතිකාර'),
                  _buildTextField(
                    controller: _medicalTreatmentController,
                    hintText: 'ඇත',
                  ),
                  const SizedBox(height: 16),

                  // --- Section 6: Prevention ---
                  _buildLabel('නිවාරණ'),
                  _buildTextField(
                    controller: _preventionController,
                    hintText: 'ඇතුලත්',
                  ),
                  const SizedBox(height: 16),

                  // --- Section 7: Medical Checkup ---
                  _buildLabel('වෛද්‍ය පරීක්ෂාව'),
                  _buildTextField(
                    controller: _medicalCheckupController,
                    hintText: 'පාලනය',
                  ),
                  const SizedBox(height: 16),

                  // --- Section 8: Nutrition ---
                  _buildLabel('පෝෂණ'),
                  _buildTextField(
                    controller: _nutritionController,
                    hintText: 'පාලනය',
                  ),
                  const SizedBox(height: 16),

                  // --- Section 9: Drinks (Radio) ---
                  _buildLabel('බීම'),
                  Row(
                    children: [
                      _buildCheckbox('පානය කරන', _drinks == 'පානය කරන', () {
                        setState(() => _drinks = 'පානය කරන');
                      }),
                      const SizedBox(width: 20),
                      _buildCheckbox('පානය නොකරන', _drinks == 'පානය නොකරන', () {
                        setState(() => _drinks = 'පානය නොකරන');
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // --- Section 10: Milk (Radio) ---
                  _buildLabel('කිරි'),
                  Row(
                    children: [
                      _buildCheckbox('බොන', _milk == 'බොන', () {
                        setState(() => _milk = 'බොන');
                      }),
                      const SizedBox(width: 20),
                      _buildCheckbox('බොන්නේ නැත', _milk == 'බොන්නේ නැත', () {
                        setState(() => _milk = 'බොන්නේ නැත');
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // --- Section 11: Alcohol (Radio) ---
                  _buildLabel('මත්පැන්'),
                  Row(
                    children: [
                      _buildCheckbox('පානය කරන', _alcohol == 'පානය කරන', () {
                        setState(() => _alcohol = 'පානය කරන');
                      }),
                      const SizedBox(width: 20),
                      _buildCheckbox(
                        'පානය නොකරන',
                        _alcohol == 'පානය නොකරන',
                        () {
                          setState(() => _alcohol = 'පානය නොකරන');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- Save & Next Button ---
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4F33),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveHealthDetails,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
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
