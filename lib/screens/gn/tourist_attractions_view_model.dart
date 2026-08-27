import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TouristAttractionsViewModel extends ChangeNotifier {
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

  // Map Coordinates
  String? selectedLocationCoordinates;

  TouristAttractionsViewModel() {
    _loadCurrentUserProfile();
  }

  /// Real-time stream of all tourist attraction records entered for this GN division
  Stream<QuerySnapshot<Map<String, dynamic>>>? get gnTouristAttractionsStream {
    if (gnDivision == null || gnDivision!.isEmpty) return null;
    return _firestore
        .collection('tourist_attractions_data')
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
    selectedLocationCoordinates = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Checks duplicates and saves/updates data in Cloud Firestore.
  Future<bool> saveDataAndProceed({
    required String locationName,
    required String developmentNeeds,
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

    if (locationName.isEmpty) {
      _errorMessage = 'කරුණාකර ස්ථානයේ නම ඇතුලත් කරන්න.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    notifyListeners();

    try {
      final String locNorm = locationName.toLowerCase().trim();

      // --- DUPLICATE CHECK (For new entries or different documents) ---
      if (locNorm.isNotEmpty) {
        final existingQuery = await _firestore
            .collection('tourist_attractions_data')
            .where('gn_division', isEqualTo: gnDivision)
            .where('tourist_attraction.location_name_normalized',
                isEqualTo: locNorm)
            .limit(1)
            .get();

        if (existingQuery.docs.isNotEmpty) {
          final foundDocId = existingQuery.docs.first.id;
          if (editingDocId == null || editingDocId != foundDocId) {
            _errorMessage =
                'දෝෂයකි: "$locationName" සංචාරක ස්ථානය "$gnDivision" වසම තුළ දැනටමත් ලියාපදිංචි කර ඇත.';
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
        "tourist_attraction": {
          "location_name": locationName,
          "location_name_normalized": locNorm,
          "map_coordinates": selectedLocationCoordinates ?? "",
          "development_needs": developmentNeeds,
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
            .collection('tourist_attractions_data')
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
        await _firestore.collection('tourist_attractions_data').add(dataToSave);
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
      await _firestore
          .collection('tourist_attractions_data')
          .doc(docId)
          .delete();
      if (editingDocId == docId) {
        clearEditing();
      }
    } catch (e) {
      debugPrint("Error deleting document: $e");
    }
  }
}