import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InfrastructureViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoadingUser = true;
  bool get isLoadingUser => _isLoadingUser;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // If editing an existing document
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

  // Road Variables
  String? selectedRoadType;
  final List<String> roadTypes = ['කාපට්', 'කැටගල්', 'කොන්ක්‍රීට්'];

  // Bridge Variables
  String? selectedBridgeType;
  final List<String> bridgeTypes = ['බෝක්කු', 'සපත්තු පාලම', 'යකඩ පාලම'];

  InfrastructureViewModel() {
    _loadCurrentUserProfile();
  }

  /// Real-time stream of all infrastructure records entered for this GN division
  Stream<QuerySnapshot<Map<String, dynamic>>>? get gnInfrastructureStream {
    if (gnDivision == null || gnDivision!.isEmpty) return null;
    return _firestore
        .collection('infrastructure_data')
        .where('gn_division', isEqualTo: gnDivision)
        .snapshots();
  }

  /// Fetches the logged in user's profile and assigned location details from Firestore
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

  void updateRoadType(String? type) {
    selectedRoadType = type;
    notifyListeners();
  }

  void updateBridgeType(String? type) {
    selectedBridgeType = type;
    notifyListeners();
  }

  void setEditingDocId(String? id) {
    editingDocId = id;
    notifyListeners();
  }

  void clearEditing() {
    editingDocId = null;
    selectedRoadType = null;
    selectedBridgeType = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Checks duplicates and saves/updates data in Cloud Firestore.
  Future<bool> saveDataAndProceed({
    required String roadName,
    required String roadDistance,
    required String roadBeneficiaries,
    required String bridgeName,
    required String bridgeCondition,
    required String bridgeBeneficiaries,
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

    if (roadName.isEmpty && bridgeName.isEmpty) {
      _errorMessage = 'කරුණාකර මාර්ගයේ හෝ පාලමේ නම ඇතුළත් කරන්න.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    notifyListeners();

    try {
      final String roadNorm = roadName.toLowerCase().trim();
      final String bridgeNorm = bridgeName.toLowerCase().trim();

      // --- DUPLICATE CHECKS (Only for NEW entries or different documents) ---
      if (roadNorm.isNotEmpty) {
        final existingRoadQuery = await _firestore
            .collection('infrastructure_data')
            .where('gn_division', isEqualTo: gnDivision)
            .where('roads_infrastructure.road_name_normalized',
                isEqualTo: roadNorm)
            .limit(1)
            .get();

        if (existingRoadQuery.docs.isNotEmpty) {
          final foundDocId = existingRoadQuery.docs.first.id;
          if (editingDocId == null || editingDocId != foundDocId) {
            _errorMessage =
                'දෝෂයකි: "$roadName" මාර්ගය "$gnDivision" වසම තුළ දැනටමත් ලියාපදිංචි කර ඇත.';
            _isSaving = false;
            notifyListeners();
            return false;
          }
        }
      }

      if (bridgeNorm.isNotEmpty) {
        final existingBridgeQuery = await _firestore
            .collection('infrastructure_data')
            .where('gn_division', isEqualTo: gnDivision)
            .where('bridges_infrastructure.bridge_name_normalized',
                isEqualTo: bridgeNorm)
            .limit(1)
            .get();

        if (existingBridgeQuery.docs.isNotEmpty) {
          final foundDocId = existingBridgeQuery.docs.first.id;
          if (editingDocId == null || editingDocId != foundDocId) {
            _errorMessage =
                'දෝෂයකි: "$bridgeName" පාලම/බෝක්කුව "$gnDivision" වසම තුළ දැනටමත් ලියාපදිංචි කර ඇත.';
            _isSaving = false;
            notifyListeners();
            return false;
          }
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
        "roads_infrastructure": {
          "road_name": roadName,
          "road_name_normalized": roadNorm,
          "road_type": selectedRoadType ?? "",
          "development_distance": roadDistance,
          "beneficiaries_count": roadBeneficiaries,
        },
        "bridges_infrastructure": {
          "bridge_name": bridgeName,
          "bridge_name_normalized": bridgeNorm,
          "bridge_type": selectedBridgeType ?? "",
          "current_condition": bridgeCondition,
          "beneficiaries_count": bridgeBeneficiaries,
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
            .collection('infrastructure_data')
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
        await _firestore.collection('infrastructure_data').add(dataToSave);
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
      await _firestore.collection('infrastructure_data').doc(docId).delete();
      if (editingDocId == docId) {
        clearEditing();
      }
    } catch (e) {
      debugPrint("Error deleting document: $e");
    }
  }
}