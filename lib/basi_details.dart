import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BasicDetailsScreen extends StatefulWidget {
  final String houseNumber;
  final List<String> nics;

  const BasicDetailsScreen({
    super.key,
    required this.houseNumber,
    required this.nics,
  });

  @override
  State<BasicDetailsScreen> createState() => _BasicDetailsScreenState();
}

class _BasicDetailsScreenState extends State<BasicDetailsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // --- Form Controllers ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // --- State Variables for Form Selections ---
  String _householderGender = 'Male';
  String _selectedNationality = 'සිංහල';
  String _samurdhiStatus = 'Yes';
  bool _isSaving = false;

  final List<String> _nationalities = ['සිංහල', 'දෙමළ', 'මුස්ලිම්'];

  // --- Children List State ---
  // Each child will be stored as a Map: {nic, name, school, dob, gender, attendsSchool, specialNeeds, assistance}
  List<Map<String, String>> _childrenList = [];

  @override
  void dispose() {
    _nameController.dispose();
    _nicController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- Firestore Save Logic (Batch Write) ---
  Future<void> _saveAllDetails() async {
    if (_nicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('කරුණාකර ගෘහ මූලිකයාගේ ජා.හැ.අංකය (NIC) ඇතුලත් කරන්න.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. Save Householder to 'citizen_details' (or change collection name as needed)
      String docId = "${widget.houseNumber}_${_nicController.text.trim()}";
      DocumentReference householderRef = FirebaseFirestore.instance
          .collection('citizen_details') // Different collection
          .doc(docId);

      batch.set(householderRef, {
        'houseNumber': widget.houseNumber,
        'nic': _nicController.text.trim(),
        'fullName': _nameController.text.trim(),
        'dob': _dobController.text.trim(),
        'gender': _householderGender,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'nationality': _selectedNationality,
        'isHouseholder': true,
        'samurdhiStatus': _samurdhiStatus == 'Yes',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Save Children to the same collection
      for (var child in _childrenList) {
        // Use child NIC as primary key alongside house number
        String childDocId = "${widget.houseNumber}_${child['nic']}";
        DocumentReference childRef = FirebaseFirestore.instance
            .collection('citizen_details')
            .doc(childDocId);

        batch.set(childRef, {
          'houseNumber': widget.houseNumber,
          'nic': child['nic'],
          'fullName': child['name'],
          'dob': child['dob'],
          'gender': child['gender'],
          'school': child['school'],
          'attendsSchool': child['attendsSchool'],
          'specialNeeds': child['specialNeeds'],
          'isHouseholder': false,
          'isChild': true,
          'assistance': child['assistance'], // From the assistance dialog
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('සියලුම දත්ත සාර්ථකව සුරකින ලදී!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Or navigate to the next actual page
      }
    } catch (e) {
      debugPrint('Error saving details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('දත්ත සුරැකීමේ අදෝෂයක් සිදු විය.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                          'මූලික තොරතුරු',
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

                  // --- Householder Number (Read Only) ---
                  _buildLabel('ගෘහ මූලික අංකය'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.houseNumber,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Householder NIC ---
                  _buildLabel('ගෘහ මූලිකයාගේ ජා.හැ.අංකය (NIC)'),
                  _buildTextField(controller: _nicController),

                  // --- Householder Gender ---
                  _buildLabel('ගෘහ මූලිකත්වය'),
                  Row(
                    children: [
                      _buildCheckbox('පිරිමි', _householderGender == 'Male', () {
                        setState(() => _householderGender = 'Male');
                      }),
                      const SizedBox(width: 20),
                      _buildCheckbox('කාන්තා', _householderGender == 'Female', () {
                        setState(() => _householderGender = 'Female');
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Text Fields ---
                  _buildLabel('ගෘහ මූලිකයාගේ නම'),
                  _buildTextField(controller: _nameController),
                  
                  _buildLabel('උපන්දිනය'),
                  _buildTextField(controller: _dobController, hintText: 'mm/dd/yyyy'),
                  
                  _buildLabel('දුරකථන අංකය'),
                  _buildTextField(controller: _phoneController),
                  
                  _buildLabel('ඊ මේල්'),
                  _buildTextField(controller: _emailController),

                  // --- Nationality Dropdown ---
                  _buildLabel('ජාතිය'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.lightBlue),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedNationality,
                        isExpanded: true,
                        items: _nationalities.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontFamily: 'UN-Imanee')),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedNationality = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Children Details Section ---
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'වයස අවුරුදු (18) ට අඩු දරුවන් පිළිබඳ විස්තර',
                        style: TextStyle(fontFamily: 'UN-Imanee', fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      children: [
                        // Show added children
                        if (_childrenList.isNotEmpty)
                          ...List.generate(_childrenList.length, (index) {
                            final child = _childrenList[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${index + 1}. ${child['name']} (${child['nic']})',
                                      style: const TextStyle(fontFamily: 'UN-Imanee', fontSize: 15),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _childrenList.removeAt(index);
                                      });
                                    },
                                  )
                                ],
                              ),
                            );
                          })
                        else
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              'ළමුන් තවමත් එකතු කර නැත.',
                              style: TextStyle(fontFamily: 'UN-Imanee', fontStyle: FontStyle.italic),
                            ),
                          ),

                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4F33),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _showAddChildDialog(context),
                          child: const Text(
                            'දරුවෙක් එකතු කරන්න',
                            style: TextStyle(fontFamily: 'UN-Imanee', color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Samurdhi Status ---
                  _buildLabel('සමෘද්ධි සහනාධාරය හිමි කර ඇත්ද නැද්ද'),
                  Row(
                    children: [
                      _buildCheckbox('ඔව්', _samurdhiStatus == 'Yes', () {
                        setState(() => _samurdhiStatus = 'Yes');
                      }),
                      const SizedBox(width: 20),
                      _buildCheckbox('නැත', _samurdhiStatus == 'No', () {
                        setState(() => _samurdhiStatus = 'No');
                      }),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- Save & Next Page Button ---
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4F33),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSaving ? null : _saveAllDetails,
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                            : const Text(
                                'සුරකින්න සහ ඊළඟට', // Save and Next
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

  // --- Helper UI Methods ---

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

  Widget _buildTextField({required TextEditingController controller, String? hintText}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
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

  // --- Child Popup Dialog ---
  void _showAddChildDialog(BuildContext context) {
    final TextEditingController childNameCtrl = TextEditingController();
    final TextEditingController childNicCtrl = TextEditingController();
    final TextEditingController childDobCtrl = TextEditingController();
    final TextEditingController childSchoolCtrl = TextEditingController();
    String childGender = 'පිරිමි';
    bool childAttendsSchool = true;
    bool childSpecialNeeds = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('NIC අංකය (අනිවාර්ය)'), // Required for PK
                _buildTextField(controller: childNicCtrl),

                _buildLabel('නම'),
                _buildTextField(controller: childNameCtrl),

                _buildLabel('උපන්දිනය'),
                _buildTextField(controller: childDobCtrl, hintText: 'mm/dd/yyyy'),
                
                _buildLabel('ස්ත්‍රී පුරුෂ භාවය'),
                Row(
                  children: [
                    _buildCheckbox('පිරිමි', childGender == 'පිරිමි', () => childGender = 'පිරිමි'),
                    const SizedBox(width: 16),
                    _buildCheckbox('ගැහැණු', childGender == 'ගැහැණු', () => childGender = 'ගැහැණු'),
                  ],
                ),
                
                _buildLabel('පාසල්'),
                Row(
                  children: [
                    _buildCheckbox('යන', childAttendsSchool, () => childAttendsSchool = !childAttendsSchool),
                    const SizedBox(width: 16),
                    _buildCheckbox('නොයන', !childAttendsSchool, () => childAttendsSchool = !childAttendsSchool),
                  ],
                ),
                if (childAttendsSchool) ...[
                   _buildLabel('පාසලේ නම'),
                   _buildTextField(controller: childSchoolCtrl),
                ],
                
                _buildLabel('විශේෂ අවශ්‍යතා සහිත අයෙක්ද'),
                Row(
                  children: [
                    _buildCheckbox('ඔව්', childSpecialNeeds, () => childSpecialNeeds = !childSpecialNeeds),
                    const SizedBox(width: 16),
                    _buildCheckbox('නැත', !childSpecialNeeds, () => childSpecialNeeds = !childSpecialNeeds),
                  ],
                ),
                const SizedBox(height: 24),
                
                Center(
                  child: SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (childNameCtrl.text.isNotEmpty && childNicCtrl.text.isNotEmpty) {
                          setState(() {
                            _childrenList.add({
                              'nic': childNicCtrl.text.trim(),
                              'name': childNameCtrl.text.trim(),
                              'dob': childDobCtrl.text.trim(),
                              'gender': childGender,
                              'school': childSchoolCtrl.text.trim(),
                              'attendsSchool': childAttendsSchool.toString(),
                              'specialNeeds': childSpecialNeeds.toString(),
                              'assistance': 'None', // Default if not filled in 2nd popup
                            });
                          });
                          Navigator.pop(context);
                          // Optional: Open Assistance Dialog immediately
                          // _showAssistanceDialog(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('නම සහ NIC අංකය අවශ්‍ය වේ!')),
                          );
                        }
                      },
                      child: const Text('හරි', style: TextStyle(fontFamily: 'UN-Imanee', color: Colors.white, fontSize: 18)),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}