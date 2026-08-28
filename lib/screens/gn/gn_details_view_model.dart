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

  // Real Dashboard Stats
  int totalProjects = 0;
  int totalBeneficiaries = 0;
  int disasterZones = 0;

  // Unified list to hold all recent submissions for the summary UI
  List<Map<String, dynamic>> recentSubmissions = [];

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
      if (user == null) return; 

      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        currentDistrict = data['district']?.toString() ?? 'Unknown District';
        currentLocalAuthority = data['local_authority']?.toString() ?? 'Unknown Authority';
        currentGnDivision = data['gn_division']?.toString() ?? 'Unknown GN Division';
        
        // Fetch real data for stats and summary
        await _fetchRealDashboardStats();
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

        currentDistrict = newDistrict;
        currentLocalAuthority = newLocalAuthority;
        currentGnDivision = newGnDivision;
        
        // Fetch new stats for the updated location
        await _fetchRealDashboardStats();
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

  // Fetch Local Authorities
  Future<List<Map<String, dynamic>>> fetchAvailableLocalAuthorities() async {
    try {
      final snapshot = await _firestore.collection('local_authorities').get();
      return snapshot.docs.map((doc) {
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
      return [];
    }
  }

  // --- LOGIC: Fetch Real Data and Compile Submissions Summary ---
  Future<void> _fetchRealDashboardStats() async {
    if (currentGnDivision == null || currentGnDivision!.isEmpty) return;

    int tempProjects = 0;
    int tempBeneficiaries = 0;
    int tempDisasters = 0;
    List<Map<String, dynamic>> tempSubmissions = [];

    try {
      // 1. Fetch Agriculture Data
      final agriSnap = await _firestore.collection('agriculture_data')
          .where('gn_division', isEqualTo: currentGnDivision)
          .get();
      tempProjects += agriSnap.docs.length;
      
      for (var doc in agriSnap.docs) {
        final data = doc.data();
        final agri = data['agriculture_infrastructure'] as Map? ?? {};
        final countStr = agri['beneficiaries_count']?.toString() ?? '0';
        tempBeneficiaries += int.tryParse(countStr) ?? 0;
        
        tempSubmissions.add({
          'docId': doc.id,
          'title': agri['location_name']?.toString() ?? 'ස්ථානයක් නැත',
          'subtitle': agri['development_category']?.toString() ?? 'කෘෂිකර්මාන්තය',
          'type': 'agriculture',
          'typeLabel': 'Agriculture (කෘෂිකර්මාන්තය)',
          'icon': Icons.eco_rounded,
          'color': Colors.green,
          'timestamp': data['created_at_timestamp']?.toString() ?? '',
          'rawData': data,
        });
      }

      // 2. Fetch Daily Facilities Data
      final facilitySnap = await _firestore.collection('daily_facilities_data')
          .where('gn_division', isEqualTo: currentGnDivision)
          .get();
      tempProjects += facilitySnap.docs.length;
      
      for (var doc in facilitySnap.docs) {
        final data = doc.data();
        final fac = data['daily_facilities'] as Map? ?? {};
        final countStr = fac['beneficiaries_count']?.toString() ?? '0';
        tempBeneficiaries += int.tryParse(countStr) ?? 0;

        tempSubmissions.add({
          'docId': doc.id,
          'title': fac['facility_type']?.toString() ?? 'පහසුකමක් නැත',
          'subtitle': 'රජයේ ඉඩමක්: ${fac['has_government_land']?.toString() ?? "-"}',
          'type': 'daily_facilities',
          'typeLabel': 'Daily Facilities (එදිනෙදා පහසුකම්)',
          'icon': Icons.local_convenience_store_rounded,
          'color': Colors.teal,
          'timestamp': data['created_at_timestamp']?.toString() ?? '',
          'rawData': data,
        });
      }

      // 3. Fetch Drainage Data
      final drainageSnap = await _firestore.collection('drainage_data')
          .where('gn_division', isEqualTo: currentGnDivision)
          .get();
      tempProjects += drainageSnap.docs.length;
      
      for (var doc in drainageSnap.docs) {
        final data = doc.data();
        final drain = data['drainage_system'] as Map? ?? {};
        final countStr = drain['beneficiaries_count']?.toString() ?? '0';
        tempBeneficiaries += int.tryParse(countStr) ?? 0;

        tempSubmissions.add({
          'docId': doc.id,
          'title': drain['location_name']?.toString() ?? 'ස්ථානයක් නැත',
          'subtitle': 'තත්ත්වය: ${drain['current_condition']?.toString() ?? "-"}',
          'type': 'drainage',
          'typeLabel': 'Drainage System (ජලාපවහන)',
          'icon': Icons.water_drop_outlined,
          'color': Colors.blueAccent,
          'timestamp': data['created_at_timestamp']?.toString() ?? '',
          'rawData': data,
        });
      }

      // 4. Fetch Disasters Data
      final disasterSnap = await _firestore.collection('disasters_data')
          .where('gn_division', isEqualTo: currentGnDivision)
          .get();
      tempDisasters += disasterSnap.docs.length;
      
      for (var doc in disasterSnap.docs) {
        final data = doc.data();
        final dis = data['disaster_information'] as Map? ?? {};
        
        tempSubmissions.add({
          'docId': doc.id,
          'title': dis['affected_area_name']?.toString() ?? 'ප්‍රදේශයක් නැත',
          'subtitle': dis['disaster_type']?.toString() ?? 'ආපදාවකි',
          'type': 'disasters',
          'typeLabel': 'Disasters (ආපදා)',
          'icon': Icons.flood_outlined,
          'color': Colors.redAccent,
          'timestamp': data['created_at_timestamp']?.toString() ?? '',
          'rawData': data,
        });
      }

      // Sort recent submissions descending based on ISO timestamp string
      tempSubmissions.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      // Update State variables
      totalProjects = tempProjects;
      totalBeneficiaries = tempBeneficiaries;
      disasterZones = tempDisasters;
      
      // Limit to 20 most recent for the UI summary
      recentSubmissions = tempSubmissions.take(20).toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching real dashboard stats: $e');
    }
  }
}