import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GnDetailsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  bool isSaving = false;

  // Current User Location Data
  String? currentDistrict;
  String? currentLocalAuthority;
  String? currentGnDivision;

  // Dashboard Stats (Simulated for UI purposes)
  int totalProjects = 0;
  int totalBeneficiaries = 0;
  int disasterZones = 0;

  GnDetailsViewModel() {
    _initData();
  }

  Future<void> _initData() async {
    isLoading = true;
    notifyListeners();

    await fetchCurrentUserLocation();

    isLoading = false;
    notifyListeners();
  }

  // Fetch location from 'users' collection
  Future<void> fetchCurrentUserLocation() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return; // Ensure user is logged in

      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        currentDistrict = data['district']?.toString() ?? 'Unknown District';
        currentLocalAuthority = data['local_authority']?.toString() ?? 'Unknown Authority';
        currentGnDivision = data['gn_division']?.toString() ?? 'Unknown GN Division';
        
        _generateMockStatsBasedOnLocation();
      }
    } catch (e) {
      debugPrint('Error fetching user location: $e');
    }
  }

  // Update location in 'users' collection
  Future<bool> updateUserLocation(String newDistrict, String newLocalAuthority, String newGnDivision) async {
    isSaving = true;
    notifyListeners();

    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'district': newDistrict,
          'local_authority': newLocalAuthority,
          'gn_division': newGnDivision,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update local state
        currentDistrict = newDistrict;
        currentLocalAuthority = newLocalAuthority;
        currentGnDivision = newGnDivision;
        
        _generateMockStatsBasedOnLocation();
      }
      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating user location: $e');
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch Local Authorities for the dropdown from 'local_authorities' collection
  Future<List<Map<String, dynamic>>> fetchAvailableLocalAuthorities() async {
    try {
      final snapshot = await _firestore.collection('local_authorities').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name_en': data['name_en'] ?? '',
          'district_en': data['district_en'] ?? 'Matara',
          'gn_divisions': data['gn_divisions'] ?? [],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching local authorities: $e');
      return [];
    }
  }

  // Simulating dashboard data changing based on location
  void _generateMockStatsBasedOnLocation() {
    if (currentGnDivision != null) {
      totalProjects = (currentGnDivision!.length % 5) + 5;
      totalBeneficiaries = (currentGnDivision!.length * 150) + 1000;
      disasterZones = (currentGnDivision!.length % 3) + 1;
    }
  }
}