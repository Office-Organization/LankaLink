import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'income_sources_screen.dart';

class HousingDetailsScreen extends StatefulWidget {
  final String surveyDocId;
  final String houseNumber;
  final String householderNic;

  const HousingDetailsScreen({
    super.key,
    required this.surveyDocId,
    required this.houseNumber,
    required this.householderNic,
  });

  @override
  State<HousingDetailsScreen> createState() => _HousingDetailsScreenState();
}

class _HousingDetailsScreenState extends State<HousingDetailsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // --- Form Controllers ---
  final TextEditingController _houseNameController = TextEditingController();
  final TextEditingController _houseTypeController = TextEditingController();

  // --- State Variables ---
  bool _hasOwnership = true;       // නිවාස හිමිකම (ඇත/නැත)
  bool _hasElectricity = true;    // විදුලිය (ඇත/නැත)
  bool _hasWater = true;          // ජලය (ඇත/නැත)
  bool _hasHousingFacilities = true; // නිවාස පහසුකම් (ඇත/නැත)

  String _mobileNetwork = '4G';   // ජංගම දුරකථන ජාලය
  final List<String> _networks = ['3G', '4G', '5G', 'නැත'];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadHousingData();
  }

  // 🔥 Previous Step Data Load (Auto-fill)
  Future<void> _loadHousingData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('survey_responses')
          .doc(widget.surveyDocId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        final housing = data['housingAndLiving'] as Map<String, dynamic>?;

        if (housing != null) {
          setState(() {
            _hasOwnership = housing['houseOwnership'] ?? true;
            _houseNameController.text = housing['houseName'] ?? '';
            _hasElectricity = housing['electricity'] ?? true;
            _hasWater = housing['water'] ?? true;
            _houseTypeController.text = housing['houseType'] ?? '';
            _hasHousingFacilities = housing['housingFacilities'] ?? true;
            _mobileNetwork = housing['mobileNetwork'] ?? '4G';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading housing data: $e');
    }
  }

  @override
  void dispose() {
    _houseNameController.dispose();
    _houseTypeController.dispose();
    super.dispose();
  }

  // 🔥 Save Logic and Navigation to Income Sources Page
  Future<void> _saveHousingDetails() async {
    setState(() => _isSaving = true);

    try {
      DocumentReference surveyRef = FirebaseFirestore.instance
          .collection('survey_responses')
          .doc(widget.surveyDocId);

      // Step 3 Data Structure
      Map<String, dynamic> step3Data = {
        'housingAndLiving': {
          'houseOwnership': _hasOwnership,
          'houseName': _houseNameController.text.trim(),
          'electricity': _hasElectricity,
          'water': _hasWater,
          'houseType': _houseTypeController.text.trim(),
          'housingFacilities': _hasHousingFacilities,
          'mobileNetwork': _mobileNetwork,
        },
        'surveyStatus': 'step3_completed',
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await surveyRef.set(step3Data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('සියලුම රැඳීවිය සහ ජීවිත දත්ත සාර්ථකව සුරකින ලදී!'),
            backgroundColor: Colors.green,
          ),
        );

        // 🚀 LINK TO INCOME SOURCES SCREEN
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IncomeSourcesScreen(
              surveyDocId: widget.surveyDocId,
              houseNumber: widget.houseNumber,
              householderNic: widget.householderNic,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving housing details: $e');
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
        border: Border.all(color: const Color(0xFFC2185B), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          Text(label, style: const TextStyle(fontFamily: 'UN-Imanee', fontSize: 14)),
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
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.lightBlue),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'රැඳීවිය හා ජීවිත',
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

                  // --- Section 1: House Ownership ---
                  _buildLabel('නිවාස හිමිකම'),
                  Row(
                    children: [
                      _buildCheckbox('ඇත', _hasOwnership, () {
                        setState(() => _hasOwnership = true);
                      }),
                      const SizedBox(width: 20),
                      _buildCheckbox('නැත', !_hasOwnership, () {
                        setState(() => _hasOwnership = false);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Section 2: Location / Address ---
                  _buildLabel('ස්ථානය'),
                  _buildTextField(
                    controller: _houseNameController,
                    hintText: 'නිවාර නම / ස්ථානය',
                  ),
                  const SizedBox(height: 16),

                  // --- Section 3: Utilities (Electricity & Water) ---
                  _buildLabel('විදුලිය'),
                  Row(
                    children: [
                      _buildCheckbox('ඇත', _hasElectricity, () {
                        setState(() => _hasElectricity = true);
                      }),
                      const SizedBox(width: 20),
                      _buildCheckbox('නැත', !_hasElectricity, () {
                        setState(() => _hasElectricity = false);
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildLabel('ජලය'),
                  Row(
                    children: [
                      _buildCheckbox('ඇත', _hasWater, () {
                        setState(() => _hasWater = true);
                      }),
                      const SizedBox(width: 20),
                      _buildCheckbox('නැත', !_hasWater, () {
                        setState(() => _hasWater = false);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Section 4: Main Residence / House Type ---
                  _buildLabel('නිවාස වර්ගය (ප්‍රධාන නිවාස වාසස්ථාන)'),
                  _buildTextField(
                    controller: _houseTypeController,
                    hintText: 'ගෙයි වර්ගය / වාසස්ථානය',
                  ),
                  const SizedBox(height: 16),

                  // --- Section 5: Housing Facilities ---
                  _buildLabel('නිවාස පහසුකම්'),
                  Row(
                    children: [
                      _buildCheckbox('ඇත', _hasHousingFacilities, () {
                        setState(() => _hasHousingFacilities = true);
                      }),
                      const SizedBox(width: 20),
                      _buildCheckbox('නැත', !_hasHousingFacilities, () {
                        setState(() => _hasHousingFacilities = false);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Section 6: Mobile Network ---
                  _buildLabel('ජංගම දුරකථන ජාලය'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC2185B)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _mobileNetwork,
                        isExpanded: true,
                        items: _networks.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontFamily: 'UN-Imanee')),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _mobileNetwork = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- Save / Next Page Button ---
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC2185B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveHousingDetails,
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