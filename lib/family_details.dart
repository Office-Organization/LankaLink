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
  String? _currentDocumentId; // Firestore හි ඇති document ID එක

  // --- 🔥 FIX: Search Function with Correct Collection & Field Name ---
  Future<void> _searchFamilyByHouseNumber() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('කරුණාකර ගෘහ අංකයක් ඇතුලත් කරන්න.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔥 වෙනස 1: Collection එක 'voters_2024' ලෙස වෙනස් කර ඇත (ඔබේ DB එකට ගැලපීමට)
      // 🔥 වෙනස 2: Field එක 'House_Number' ලෙස නිවැරදි කර ඇත (ඔබේ DB එකේ ඇති නම)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('voters_2024')
          .where('House_Number', isEqualTo: _searchController.text.trim())
          .get();

      if (querySnapshot.docs.isNotEmpty && mounted) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        _currentDocumentId = doc.id;

        setState(() {
          // දත්ත පිරවීම (DB එකේ ඇති Field නම් අනුව)
          _houseNumberController.text = data['House_Number'] ?? '';
          
          // Members පිරවීම (ඔබේ DB එකේ 'members' ෆීල්ඩ් එකක් නැත්නම් මෙය 'Name' වලින් පිරවිය හැක)
          // උදාහරණයක් ලෙස මම 'Name' එක 'members' ලෙස පෙන්වමි
          _membersController.text = data['Name'] ?? 'No members found'; 
          
          _hasAswesuma = false; // DB එකේ මේක තියෙන එකක් නම් අදාල ෆීල්ඩ් එක දාන්න
          _aswesumaTotalController.text = '0.00'; 
          _specialNeedsCountController.text = '0';
          _specialNeedsAmountController.text = '0.00';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('දත්ත සාර්ථකව සොයා ගන්නා ලදී!'), backgroundColor: Colors.green),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('මෙම ගෘහ අංකයට අදාළ දත්ත හමු නොවීය.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error searching data: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('දත්ත සෙවීමේදී අදෝෂයක් සිදු විය.')), 
      );
    }
  }

  // පළමු පිටුවේ දත්ත Save/GUpdate කිරීම
  Future<void> _updateFamilyDetails() async {
    if (_currentDocumentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('පළමුව දත්ත සොයාගෙන සුරකින්න.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Members string එක list එකක් ලෙසට හරවා ගැනීම
      List<String> membersList = _membersController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Update කිරීම
      await FirebaseFirestore.instance
          .collection('voters_2024')
          .doc(_currentDocumentId)
          .update({
        'House_Number': _houseNumberController.text.trim(),
        'Name': membersList.isNotEmpty ? membersList.join(', ') : '', // Simply updating Name
        // ඔබට අවශ්‍ය නම් මෙතනට අදාල ෆීල්ඩ් එකතු කරගන්න
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('දත්ත සාර්ථකව යාවත්කාලීන කරන ලදී!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error updating data: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('දත්ත සුරැකීමේදී අදෝෂයක් සිදු විය.')),
      );
    }
  }

  // ඊළඟ පිටුවට යාමට පෙර ක්‍රියාවලිය
  void _goToNextPage() async {
    if (_currentDocumentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('පළමුව ගෘහ අංකය සොයාගෙන දත්ත ලබාගන්න.')),
      );
      return;
    }

    await _updateFamilyDetails();

    // 2. Primary Keys (House Number සහ NIC List) ඊළඟ පිටුවට යැවීම
    // *මෙතන NIC ලබා ගැනීමට ඔබේ DB එකෙන් NIC එක ඇද ගත හැක*
    List<String> nicsList = []; 
    
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BasicDetailsScreen(
          houseNumber: _houseNumberController.text.trim(),
          nics: nicsList,
        ),
      ),
    );
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
                // --- Back Button and Header ---
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
                        style: TextStyle(
                          fontFamily: 'UN-Imanee',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Search Filter ---
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'ගෘහ අංකය ඇතුලත් කරන්න (Search)',
                            prefixIcon: const Icon(Icons.home, color: Color(0xFFFF4F33)),
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
                            backgroundColor: const Color(0xFFFF4F33),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 2,
                          ),
                          onPressed: _isLoading ? null : _searchFamilyByHouseNumber,
                          child: const Text(
                            'සොයන්න',
                            style: TextStyle(fontFamily: 'UN-Imanee', fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // --- ගෘහ මූලික අංකය ---
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

                // --- Card 1: Family Members ---
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
                      const Text(
                        'පවුල් සාමාජිකයන්', 
                        style: TextStyle(fontFamily: 'UN-Imanee', fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _membersController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'නම් කොමාවෙන් වෙන් කර ලියන්න (උදා: මහින්ද, නිමල්)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value!.isEmpty ? 'අවම වශයෙන් එක් සාමාජිකයෙකු අවශ්‍යයි' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- Card 2: Aswesuma Details ---
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
                          const Text(
                            'අස්වැසුම',
                            style: TextStyle(fontFamily: 'UN-Imanee', fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 16),
                          Switch(
                            value: _hasAswesuma,
                            activeColor: const Color(0xFFFF4F33),
                            onChanged: (val) => setState(() => _hasAswesuma = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _aswesumaTotalController,
                        decoration: const InputDecoration(
                          labelText: 'අස්වැසුම් මුළු මුදල (රුපියල්)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'විශේෂ අවශ්‍යතා සහිත සාමාජිකයන්',
                        style: TextStyle(fontFamily: 'UN-Imanee', fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _specialNeedsCountController,
                              decoration: const InputDecoration(labelText: 'ගණන', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _specialNeedsAmountController,
                              decoration: const InputDecoration(labelText: 'මුදල (රුපියල්)', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- Bottom Info Card ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ඔබ සොයාගත් දත්ත මෙම පිටුවේ සංස්කරණය කර "ඊළඟ පිටුවට" යන බොත්තම එබූ විට ස්වයංක්‍රීයව සුරැකේ.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'UN-Imanee', fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 30),

                // --- Next Page Button ---
                Center(
                  child: SizedBox(
                    width: 250,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4F33),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      onPressed: _isLoading ? null : _goToNextPage,
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text(
                              'ඊළඟ පිටුවට', 
                              style: TextStyle(fontFamily: 'UN-Imanee', fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
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