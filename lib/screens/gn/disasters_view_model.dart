import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DisastersViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoadingUser = true;
  bool get isLoadingUser => _isLoadingUser;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Active editing document ID
  String? editingDocId;

  // Logged-in User Profile & Location Data
  String? userId;
  String? userNic;
  String? userName;
  String? userEmail;
  String? userPhone;
  String? district;
  String? localAuthority;
  String? gnDivision;

  // 1. Disaster Types
  String? selectedDisasterType;
  final List<String> disasterTypes = [
    'ගංවතුර (Floods)',
    'නාය යෑම් / පස් කඳු කඩා වැටීම් (Landslides)',
    'දැඩි සුළං / කුණාටු (High Winds)',
    'නියඟය / පානීය ජල හිඟය (Drought)',
    'මුහුදු ඛාදනය / උදම් රළ (Coastal Erosion)',
    'වන සත්ත්ව හානි / අලි ගැටුම් (Wildlife Conflict)',
    'අනෙකුත් (Other)',
  ];

  // 2. Risk Level
  String? selectedRiskLevel;
  final List<String> riskLevels = [
    'අධික අවදානම් (High Risk)',
    'මධ්‍යම අවදානම් (Moderate Risk)',
    'අඩු අවදානම් (Low Risk)',
  ];

  // 3. Frequency of Disaster
  String? selectedFrequency;
  final List<String> frequencies = [
    'වාර්ෂිකව / වැසි සමයේදී (Annually / Monsoon)',
    'වසර කිහිපයකට වරක් (Periodic / Every few years)',
    'කලාතුරකින් (Rare / Occasional)',
  ];

  // Map Coordinates
  String? selectedLocationCoordinates;

  DisastersViewModel() {
    _loadCurrentUserProfile();
  }

  /// Real-time stream of all disaster records entered for this GN division
  Stream<QuerySnapshot<Map<String, dynamic>>>? get gnDisastersStream {
    if (gnDivision == null || gnDivision!.isEmpty) return null;
    return _firestore
        .collection('disasters_data')
        .where('gn_division', isEqualTo: gnDivision)
        .snapshots();
  }

  /// Fetches the logged-in user profile from Firestore
  Future<void> _loadCurrentUserProfile() async {
    _isLoadingUser = true;
    notifyListeners();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        userId = currentUser.uid;
        userEmail = currentUser.email;

        final DocumentSnapshot<Map<String, dynamic>> userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          userNic = (data['nic'] ?? '').toString();
          userName = (data['name'] ?? data['fullName'] ?? '').toString();
          userPhone = (data['phone'] ?? '').toString();
          district = (data['district'] ?? 'Matara').toString();
          localAuthority = (data['local_authority'] ?? '').toString();
          gnDivision = (data['gn_division'] ?? '').toString();
        }
      }
    } catch (e) {
      debugPrint("Error loading user profile: $e");
    } finally {
      _isLoadingUser = false;
      notifyListeners();
    }
  }

  void updateDisasterType(String? value) {
    selectedDisasterType = value;
    notifyListeners();
  }

  void updateRiskLevel(String? value) {
    selectedRiskLevel = value;
    notifyListeners();
  }

  void updateFrequency(String? value) {
    selectedFrequency = value;
    notifyListeners();
  }

  void setLocationCoordinates(String? coordinates) {
    selectedLocationCoordinates = coordinates;
    notifyListeners();
  }

  void setEditingDocId(String? id) {
    editingDocId = id;
    notifyListeners();
  }

  void clearEditing() {
    editingDocId = null;
    selectedDisasterType = null;
    selectedRiskLevel = null;
    selectedFrequency = null;
    selectedLocationCoordinates = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Checks duplicates and saves/updates data in Cloud Firestore.
  Future<bool> finishAndSave({
    required String affectedAreaName,
    required String affectedFamiliesCount,
    required String affectedHousesCount,
    required String mitigationNeeds,
    required String safeEvacuationLocation,
  }) async {
    _errorMessage = null;

    if (_isLoadingUser) {
      _errorMessage = 'පරිශීලක තොරතුරු පූරණය වෙමින් පවතී. කරුණාකර රැඳී සිටින්න.';
      notifyListeners();
      return false;
    }

    if (userId == null || userNic == null || userNic!.isEmpty) {
      _errorMessage = 'පරිශීලක ගිණුම හඳුනාගත නොහැක. කරුණාකර නැවත ලොග් වන්න.';
      notifyListeners();
      return false;
    }

    if (gnDivision == null || gnDivision!.isEmpty) {
      _errorMessage = 'ඔබගේ ගිණුමට ග්‍රාම නිලධාරී වසමක් අනුයුක්ත කර නොමැත.';
      notifyListeners();
      return false;
    }

    if (selectedDisasterType == null || selectedDisasterType!.isEmpty) {
      _errorMessage = 'කරුණාකර ආපදා වර්ගය තෝරන්න.';
      notifyListeners();
      return false;
    }

    if (affectedAreaName.isEmpty) {
      _errorMessage = 'කරුණාකර පීඩාවට පත්වන ප්‍රදේශයේ නම ඇතුළත් කරන්න.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    notifyListeners();

    try {
      final String disNorm = selectedDisasterType!.toLowerCase().trim();
      final String areaNorm = affectedAreaName.toLowerCase().trim();

      // --- DUPLICATE CHECK (For new entries or different documents) ---
      final existingQuery = await _firestore
          .collection('disasters_data')
          .where('gn_division', isEqualTo: gnDivision)
          .where('disaster_information.disaster_type_normalized',
              isEqualTo: disNorm)
          .where('disaster_information.affected_area_normalized',
              isEqualTo: areaNorm)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        final foundDocId = existingQuery.docs.first.id;
        if (editingDocId == null || editingDocId != foundDocId) {
          _errorMessage =
              'දෝෂයකි: "$affectedAreaName" ප්‍රදේශයේ "$selectedDisasterType" ආපදා තොරතුරු "$gnDivision" වසම තුළ දැනටමත් ලියාපදිංචි කර ඇත.';
          _isSaving = false;
          notifyListeners();
          return false;
        }
      }

      final currentTimestamp = DateTime.now().toIso8601String();

      final Map<String, dynamic> dataToSave = {
        "collector_uid": userId,
        "collector_nic": userNic,
        "collector_name": userName ?? '',
        "collector_email": userEmail ?? '',
        "collector_phone": userPhone ?? '',
        "district": district ?? 'Matara',
        "local_authority": localAuthority ?? '',
        "gn_division": gnDivision ?? '',
        "updated_at": FieldValue.serverTimestamp(),
        "disaster_information": {
          "disaster_type": selectedDisasterType ?? "",
          "disaster_type_normalized": disNorm,
          "affected_area_name": affectedAreaName,
          "affected_area_normalized": areaNorm,
          "risk_level": selectedRiskLevel ?? "",
          "frequency": selectedFrequency ?? "",
          "affected_families_count": affectedFamiliesCount,
          "affected_houses_count": affectedHousesCount,
          "map_coordinates": selectedLocationCoordinates ?? "",
          "mitigation_needs": mitigationNeeds,
          "safe_evacuation_location": safeEvacuationLocation,
        },
      };

      if (editingDocId != null) {
        // UPDATE existing document
        dataToSave["edit_logs"] = FieldValue.arrayUnion([
          {
            "action": "UPDATED",
            "user_uid": userId,
            "user_nic": userNic,
            "user_name": userName ?? '',
            "timestamp": currentTimestamp,
          }
        ]);
        await _firestore
            .collection('disasters_data')
            .doc(editingDocId)
            .update(dataToSave);
      } else {
        // CREATE new document
        dataToSave["created_at_timestamp"] = currentTimestamp;
        dataToSave["created_at"] = FieldValue.serverTimestamp();
        dataToSave["edit_logs"] = [
          {
            "action": "CREATED",
            "user_uid": userId,
            "user_nic": userNic,
            "user_name": userName ?? '',
            "timestamp": currentTimestamp,
          }
        ];
        await _firestore.collection('disasters_data').add(dataToSave);
      }

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'දත්ත සුරැකීමේදී දෝෂයක් මතු විය: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Deletes a record from Firestore
  Future<void> deleteRecord(String docId) async {
    try {
      await _firestore.collection('disasters_data').doc(docId).delete();
      if (editingDocId == docId) {
        clearEditing();
      }
    } catch (e) {
      debugPrint("Error deleting document: $e");
    }
  }
}