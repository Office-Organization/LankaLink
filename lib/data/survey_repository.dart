import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/survey.dart';
import '../models/basic_details.dart' as bd; 
import '../models/housing_details.dart';
import '../models/income_details.dart';
import '../models/assets_details.dart';

class SurveyRepository {
  SurveyRepository(this._db);
  
  final FirebaseFirestore _db;
  final String _collection = 'survey_responses';

  // 🟢 UID එක මඟින් users collection එකෙන් නම සෙවීමේ උපකාරක ක්‍රමය
  Future<String> _getUserName(String? uid) async {
    if (uid == null || uid.isEmpty) return 'පද්ධතිය (System)';
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final name = doc.data()!['name'] as String?;
        if (name != null && name.isNotEmpty) {
          return name;
        }
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
    }
    return uid;
  }

  // ==========================================
  // පවුලේ මූලික තොරතුරු සහ සාමාජිකයන් (Survey)
  // ==========================================

  Future<Survey?> getSurveyByHouseNumber(String houseNumber) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Auth Error: Please sign in to access survey data.');
      }

      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      final doc = await _db.collection(_collection).doc(safeHouseNumber).get();
      if (!doc.exists || doc.data() == null) return null;
      
      final data = doc.data()!;
      
      if (data.containsKey('updatedBy')) {
        data['updatedBy'] = await _getUserName(data['updatedBy']?.toString());
      }
      
      return Survey.fromMap(data);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Firebase Permission Error.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveFamilyDetails(String houseNumber, FamilyInfo family) async {
    try {
      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      DocumentReference ref = _db.collection(_collection).doc(safeHouseNumber);
      
      List<Map<String, dynamic>> membersData = family.members
          .map(
            (m) => {
              'id': m.id,
              'nic': m.nic,
              'fullName': m.name,
              'dob': m.birthday.toIso8601String(),
              'gender': m.gender,
              'isAdult': m.isAdult,
              'age': m.age,
            },
          )
          .toList();

      await ref.set({
        'houseNumber': houseNumber,
        'hasAswasuma': family.hasAswasuma,
        'specialNeedsCount': family.specialNeedsCount,
        'specialNeedsAmount': family.specialNeedsAmount,
        'specialNeedDescription': family.specialNeedDescription,
        
        // 🟢 LOCATION DATA ADDED HERE TO SAVE TO FIRESTORE
        'localAuthority': family.localAuthority,
        'gnDivision': family.gnDivision,
        
        'members': membersData,
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // Basic Details
  // ==========================================

  Future<bd.BasicDetails?> getBasicDetails(String houseNumber) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Auth Error.');

      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      final doc = await _db.collection(_collection).doc(safeHouseNumber).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('basicDetails')) {
          final mapData = Map<String, dynamic>.from(data['basicDetails'] as Map);

          final rootUid = data['basicDetailsUpdatedBy']?.toString();
          final nestedUid = mapData['updatedBy']?.toString();
          final finalUid = rootUid ?? nestedUid;

          mapData['updatedBy'] = finalUid != null ? await _getUserName(finalUid) : null;
          mapData['updatedAt'] = data['basicDetailsUpdatedAt'] ?? mapData['updatedAt'];

          return bd.BasicDetails.fromMap(mapData);
        } else {
          final survey = Survey.fromMap(data);
          final adults = survey.family.members.where((m) => m.isAdult).toList();

          return bd.BasicDetails(
            houseNumber: houseNumber,
            headName: adults.isNotEmpty ? adults.first.name : '',
            nic: adults.isNotEmpty ? adults.first.nic : '',
            headGender: adults.isNotEmpty ? adults.first.gender : 'පුරුෂ',
            members: survey.family.members.map((m) => bd.FamilyMember(
              id: m.id, fullName: m.name, nic: m.nic, dob: m.birthday.toIso8601String(),
              age: m.age, gender: m.gender, isAdult: m.isAdult,
            )).toList(),
          );
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveBasicDetails(String houseNumber, bd.BasicDetails details) async {
    try {
      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      DocumentReference ref = _db.collection(_collection).doc(safeHouseNumber);
      
      final uid = FirebaseAuth.instance.currentUser?.uid;
      
      Map<String, dynamic> detailsMap = details.toMap();
      detailsMap['updatedBy'] = uid;
      detailsMap['updatedAt'] = DateTime.now().toIso8601String();

      await ref.set({
        'basicDetails': detailsMap,
        'basicDetailsUpdatedBy': uid,
        'basicDetailsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // Housing Details
  // ==========================================

  Future<HousingDetails?> getHousingDetails(String houseNumber) async {
    try {
      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      final doc = await _db.collection(_collection).doc(safeHouseNumber).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('housingDetails')) {
          final mapData = Map<String, dynamic>.from(data['housingDetails'] as Map);

          final rootUid = data['housingDetailsUpdatedBy']?.toString();
          final nestedUid = mapData['updatedBy']?.toString();
          final finalUid = rootUid ?? nestedUid;

          mapData['updatedBy'] = finalUid != null ? await _getUserName(finalUid) : null;
          mapData['updatedAt'] = data['housingDetailsUpdatedAt'] ?? mapData['updatedAt'];

          return HousingDetails.fromMap(mapData);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveHousingDetails(String houseNumber, HousingDetails details) async {
    try {
      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      DocumentReference ref = _db.collection(_collection).doc(safeHouseNumber);
      
      final uid = FirebaseAuth.instance.currentUser?.uid;
      
      Map<String, dynamic> detailsMap = details.toMap();
      detailsMap['updatedBy'] = uid;
      detailsMap['updatedAt'] = DateTime.now().toIso8601String();

      await ref.set({
        'housingDetails': detailsMap,
        'housingDetailsUpdatedBy': uid,
        'housingDetailsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // Income Details
  // ==========================================

  Future<IncomeDetails?> getIncomeDetails(String houseNumber) async {
    try {
      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      final doc = await _db.collection(_collection).doc(safeHouseNumber).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('incomeDetails')) {
          final mapData = Map<String, dynamic>.from(data['incomeDetails'] as Map);

          final rootUid = data['incomeDetailsUpdatedBy']?.toString();
          final nestedUid = mapData['updatedBy']?.toString();
          final finalUid = rootUid ?? nestedUid;

          mapData['updatedBy'] = finalUid != null ? await _getUserName(finalUid) : null;
          mapData['updatedAt'] = data['incomeDetailsUpdatedAt'] ?? mapData['updatedAt'];

          return IncomeDetails.fromMap(mapData);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveIncomeDetails(String houseNumber, IncomeDetails details) async {
    try {
      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      DocumentReference ref = _db.collection(_collection).doc(safeHouseNumber);
      
      final uid = FirebaseAuth.instance.currentUser?.uid;

      Map<String, dynamic> detailsMap = details.toMap();
      detailsMap['updatedBy'] = uid;
      detailsMap['updatedAt'] = DateTime.now().toIso8601String();

      await ref.set({
        'incomeDetails': detailsMap,
        'incomeDetailsUpdatedBy': uid,
        'incomeDetailsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // Assets Details (නිශ්චල හා චංචල දේපල)
  // ==========================================

  Future<AssetsDetails?> getAssetsDetails(String houseNumber) async {
    try {
      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      final doc = await _db.collection(_collection).doc(safeHouseNumber).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('assetsDetails')) {
          final mapData = Map<String, dynamic>.from(data['assetsDetails'] as Map);

          final rootUid = data['assetsDetailsUpdatedBy']?.toString();
          final nestedUid = mapData['updatedBy']?.toString();
          final finalUid = rootUid ?? nestedUid;

          mapData['updatedBy'] = finalUid != null ? await _getUserName(finalUid) : null;
          mapData['updatedAt'] = data['assetsDetailsUpdatedAt'] ?? mapData['updatedAt'];

          return AssetsDetails.fromMap(mapData);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveAssetsDetails(String houseNumber, AssetsDetails details) async {
    try {
      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      DocumentReference ref = _db.collection(_collection).doc(safeHouseNumber);
      
      final uid = FirebaseAuth.instance.currentUser?.uid;

      Map<String, dynamic> detailsMap = details.toMap();
      detailsMap['updatedBy'] = uid;
      detailsMap['updatedAt'] = DateTime.now().toIso8601String();

      await ref.set({
        'assetsDetails': detailsMap,
        'assetsDetailsUpdatedBy': uid,
        'assetsDetailsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }
}