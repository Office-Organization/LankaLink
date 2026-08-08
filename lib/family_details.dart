import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'basi_details.dart'; // ඔබේ ඊළඟ පිටුව

class FamilyDetailsScreen extends StatefulWidget {
  const FamilyDetailsScreen({super.key});

  @override
  State<FamilyDetailsScreen> createState() => _FamilyDetailsScreenState();
}

class _FamilyDetailsScreenState extends State<FamilyDetailsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  // --- Search and Form Controllers ---
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _membersController = TextEditingController();
  final TextEditingController _aswesumaTotalController = TextEditingController();
  final TextEditingController _specialNeedsCountController = TextEditingController();
  final TextEditingController _specialNeedsAmountController = TextEditingController();

  bool _isLoading = false;
  bool _hasAswesuma = false;
  
  // --- State variables for Master Data ---
  String _householderNic = '';  
  String _householderName = ''; 
  String _householderGender = '';

  // --- 🔥 නවීකරණය කරන ලද Search Function (2 පියවරකින් දත්ත ලබා ගැනීම) ---
  Future<void> _searchFamilyByHouseNumber() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('කරුණාකර ගෘහ අංකයක් ඇතුලත් කරන්න.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // --- පියවර 1: Voters_2024 වෙතින් එම ගෘහ අංකයට අදාළ සියලුම සාමාජිකයින් ලබා ගැනීම ---
      final querySnapshot = await FirebaseFirestore.instance
          .collection('voters_2024')
          .where('House_Number', isEqualTo: _searchController.text.trim())
          .get();

      if (querySnapshot.docs.isEmpty && mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('මෙම ගෘහ අංකයට අදාළ දත්ත හමු නොවීය.'), backgroundColor: Colors.red),
        );
        return;
      }

      // ගෘහයේ සිටින සියලුම නම් ලබා ගැනීම (List to String)
      List<String> familyNames = querySnapshot.docs.map((doc) => doc['Name'] as String).toList();
      
      // ගෘහ මූලිකයා ලෙස පළමු document එකෙන් දත්ත ගැනීම
      final firstDoc = querySnapshot.docs.first;
      final data = firstDoc.data();
      String foundHouseNumber = data['House_Number'] ?? '';
      String foundHouseholderNic = data['NIC'] ?? '';
      String foundHouseholderName = data['Name'] ?? 'Unknown';
      String foundHouseholderGender = data['Gender'] ?? 'Male';

      // --- පියවර 2: Survey_Responses වෙතින් දැනටමත් ඇති අස්වැසුම් දත්ත ලබා ගැනීම ---
      String surveyDocId = '${foundHouseNumber}_$foundHouseholderNic';
      final surveyDoc = await FirebaseFirestore.instance
          .collection('survey_responses')
          .doc(surveyDocId)
          .get();

      if (mounted) {
        setState(() {
          // Master Data populate කිරීම
          _houseNumberController.text = foundHouseNumber;
          _householderNic = foundHouseholderNic;
          _householderName = foundHouseholderName;
          _householderGender = foundHouseholderGender;
          
          // සියලුම සාමාජිකයින්ගේ නම් කොමාවෙන් වෙන් කර පිරවීම
          _membersController.text = familyNames.join(', '); 

          // Survey Data populate කිරීම (දත්ත තිබේ නම් පිරවීම, නැත්නම් Default)
          if (surveyDoc.exists) {
            final surveyData = surveyDoc.data()!;
            final aswesuma = surveyData['aswesuma'] as Map<String, dynamic>? ?? {};
            _hasAswesuma = aswesuma['hasAswesuma'] as bool? ?? false;
            _aswesumaTotalController.text = aswesuma['totalAmount']?.toString() ?? '0.00';
            _specialNeedsCountController.text = aswesuma['specialNeedsCount']?.toString() ?? '0';
            _specialNeedsAmountController.text = aswesuma['specialNeedsAmount']?.toString() ?? '0.00';
          } else {
            _hasAswesuma = false;
            _aswesumaTotalController.text = '0.00';
            _specialNeedsCountController.text = '0';
            _specialNeedsAmountController.text = '0.00';
          }
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('පවුලේ සාමාජිකයින් සහ පවතින සමීක්ෂණ දත්ත සාර්ථකව පූරණය කරන ලදී!'), backgroundColor: Colors.green),
        );
      }

    } catch (e) {
      debugPrint('Error searching data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('දත්ත සෙවීමේදී අදෝෂයක් සිදු විය.')), 
        );
      }
    }
  }

  // --- 🔥 Save Function: New Collection 'survey_responses' වෙත Save කිරීම ---
  Future<void> _saveToSurveyCollection() async {
    setState(() => _isLoading = true);
    try {
      List<String> membersList = _membersController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      String documentId = '${_houseNumberController.text}_$_householderNic';

      Map<String, dynamic> surveyData = {
        'houseNumber': _houseNumberController.text.trim(),
        'householder': {
          'nic': _householderNic,
          'fullName': _householderName,
          'gender': _householderGender,
        },
        'familyMembersNames': membersList,
        'aswesuma': {
          'hasAswesuma': _hasAswesuma,
          'totalAmount': _aswesumaTotalController.text.trim(),
          'specialNeedsCount': int.tryParse(_specialNeedsCountController.text.trim()) ?? 0,
          'specialNeedsAmount': _specialNeedsAmountController.text.trim(),
        },
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': user?.uid ?? 'unknown',
        'surveyStatus': 'step1_completed'
      };

      await FirebaseFirestore.instance
          .collection('survey_responses')
          .doc(documentId)
          .set(surveyData, SetOptions(merge: true));

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('පවුලේ මූලික සමීක්ෂණ දත්ත සාර්ථකව සුරකින ලදී!'), backgroundColor: Colors.green),
        );

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BasicDetailsScreen(
              surveyDocId: documentId,
              houseNumber: _houseNumberController.text.trim(),
              householderNic: _householderNic,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving survey data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('දත්ත සුරැකීමේදී දෝෂයක් සිදු විය.')),
        );
      }
    }
  }

  // --- ඊළඟ පිටුවට යාම ---
  void _goToNextPage() async {
    if (_householderNic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('පළමුව ගෘහ අංකය සොයාගෙන දත්ත ලබාගන්න.')),
      );
      return;
    }
    await _saveToSurveyCollection();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _houseNumberController.dispose();
    _membersController.dispose();
    _aswesumaTotalController.dispose();
    _specialNeedsCountController.dispose();
    _specialNeedsAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.lightBlue),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'පවුල් තොරතුරු',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'UN-Imanee', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'ගෘහ අංකය ඇතුලත් කරන්න (Search)',
                            prefixIcon: const Icon(Icons.home, color: Color(0xFFC2185B)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                          onFieldSubmitted: (_) => _searchFamilyByHouseNumber(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC2185B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 2,
                          ),
                          onPressed: _isLoading ? null : _searchFamilyByHouseNumber,
                          child: const Text('සොයන්න', style: TextStyle(fontFamily: 'UN-Imanee', fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _houseNumberController,
                  decoration: InputDecoration(
                    labelText: 'ගෘහ මූලික අංකය',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabled: false,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('පවුල් සාමාජිකයන්', style: TextStyle(fontFamily: 'UN-Imanee', fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _membersController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'නම් කොමාවෙන් වෙන් කර ලියන්න (උදා: මහින්ද, නිමල්)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('අස්වැසුම', style: TextStyle(fontFamily: 'UN-Imanee', fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          Switch(
                            value: _hasAswesuma,
                            activeColor: const Color(0xFFC2185B),
                            onChanged: (val) => setState(() => _hasAswesuma = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _aswesumaTotalController,
                        decoration: const InputDecoration(labelText: 'අස්වැසුම් මුළු මුදල (රුපියල්)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      const Text('විශේෂ අවශ්‍යතා සහිත සාමාජිකයන්', style: TextStyle(fontFamily: 'UN-Imanee', fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _specialNeedsCountController, decoration: const InputDecoration(labelText: 'ගණන', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                          const SizedBox(width: 16),
                          Expanded(child: TextFormField(controller: _specialNeedsAmountController, decoration: const InputDecoration(labelText: 'මුදල (රුපියල්)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: SizedBox(
                    width: 250,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC2185B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      onPressed: _isLoading ? null : _goToNextPage,
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('ඊළඟ පිටුවට', style: TextStyle(fontFamily: 'UN-Imanee', fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}