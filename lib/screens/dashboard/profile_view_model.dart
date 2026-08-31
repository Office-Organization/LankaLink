
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isSaving = false;

  // User Data Fields
  String? userId;
  String? email;
  String? nic;
  String? role;
  
  // Editable fields mapping
  String? name;
  String? phone;
  String? district;
  String? localAuthority;
  String? gnDivision;

  // Dropdown Data
  List<Map<String, dynamic>> authoritiesList = [];
  List<dynamic> currentGNDivisionsList = [];

  // Selected Dropdown Identifiers
  String? selectedAuthorityId;

  ProfileViewModel() {
    _initData();
  }

  Future<void> _initData() async {
    isLoading = true;
    notifyListeners();

    await _fetchLocalAuthorities();
    await _loadUserProfile();

    isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchLocalAuthorities() async {
    try {
      final snapshot = await _firestore.collection('local_authorities').get();
      authoritiesList = snapshot.docs.map((doc) {
        final data = doc.data();
        String formattedId = doc.id.split('_').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');

        return {
          'id': doc.id,
          'name_en': data['name_en'] ?? formattedId,
          'name_si': data['name_si'] ?? '',
          'district_en': data['district_en'] ?? 'Matara',
          'district_si': data['district_si'] ?? 'මාතර',
          'gn_divisions': data['gn_divisions'] ?? [],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching local authorities: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;
      
      userId = user.uid;

      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        
        email = data['email']?.toString();
        nic = data['nic']?.toString();
        role = data['role']?.toString();
        
        name = data['name']?.toString();
        phone = data['phone']?.toString();
        district = data['district']?.toString();
        localAuthority = data['local_authority']?.toString();
        gnDivision = data['gn_division']?.toString();

        // Match the user's saved local authority string to our fetched list to set up dropdowns
        if (localAuthority != null && authoritiesList.isNotEmpty) {
          try {
            final authMap = authoritiesList.firstWhere(
              (element) => element['name_en'] == localAuthority,
              orElse: () => authoritiesList.first,
            );
            
            selectedAuthorityId = authMap['id'];
            currentGNDivisionsList = authMap['gn_divisions'] ?? [];
            
            // Verify gnDivision exists in the list, otherwise nullify
            bool gnExists = currentGNDivisionsList.any((gn) => gn['en'] == gnDivision);
            if (!gnExists) {
              gnDivision = currentGNDivisionsList.isNotEmpty ? currentGNDivisionsList.first['en'] : null;
            }
          } catch (e) {
             debugPrint('Authority match error: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  void onAuthorityChanged(String? newAuthId) {
    if (newAuthId == null) return;
    selectedAuthorityId = newAuthId;
    
    final authMap = authoritiesList.firstWhere((element) => element['id'] == newAuthId);
    localAuthority = authMap['name_en'];
    district = authMap['district_en'];
    currentGNDivisionsList = authMap['gn_divisions'] ?? [];
    gnDivision = currentGNDivisionsList.isNotEmpty ? currentGNDivisionsList.first['en'] : null;
    
    notifyListeners();
  }

  void onGnDivisionChanged(String? newGn) {
    gnDivision = newGn;
    notifyListeners();
  }

  Future<bool> updateProfileData({required String newName, required String newPhone}) async {
    if (userId == null) return false;
    
    isSaving = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(userId).update({
        'name': newName,
        'phone': newPhone,
        'district': district ?? 'Matara',
        'local_authority': localAuthority ?? '',
        'gn_division': gnDivision ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      name = newName;
      phone = newPhone;
      
      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> changePassword(String newPassword) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        return null; // Success
      }
      return 'No user logged in.';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'ආරක්‍ෂිත හේතූන් මත මුරපදය වෙනස් කිරීමට පෙර කරුණාකර ගිණුමෙන් පිටවී (Log out) නැවත පිවිසෙන්න.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}