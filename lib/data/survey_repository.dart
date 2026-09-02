import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/survey.dart';
import '../models/basic_details.dart' as bd; // Alias එකක් යොදා ඇත (නම් පැටලීම වැළැක්වීමට)
import '../models/housing_details.dart';
import '../models/income_details.dart';
import '../models/assets_details.dart';

class SurveyRepository {
  SurveyRepository(this._db);
  
  final FirebaseFirestore _db;
  final String _collection = 'survey_responses';

  // 🟢 UID එක මඟින් users collection එකෙන් නම සෙවීමේ උපකාරක ක්‍රමය (Helper Method)
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
    return uid; // නම සොයා ගැනීමට නොහැකි වුවහොත් මුල් UID එකම පෙන්වයි
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
      
      // UID එක නම මඟින් ප්‍රතිස්ථාපනය කිරීම
      if (data.containsKey('updatedBy')) {
        data['updatedBy'] = await _getUserName(data['updatedBy']?.toString());
      }
      
      return Survey.fromMap(data);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Firebase Permission Error: Make sure Firestore rules allow reads for authenticated users.',
        );
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
        'members': membersData,
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // Basic Details (පවුලේ මූලික තොරතුරු සහ සාමාජිකයන්)
  // ==========================================

  Future<bd.BasicDetails?> getBasicDetails(String houseNumber) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Auth Error: Please sign in to access family data.');
      }

      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      final doc = await _db.collection(_collection).doc(safeHouseNumber).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('basicDetails')) {
          final mapData = Map<String, dynamic>.from(
            data['basicDetails'] as Map,
          );
          
          // BasicDetails සඳහාද UID එක නම මඟින් මාරු කිරීම
          final uid = data['basicDetailsUpdatedBy']?.toString();
          mapData['updatedBy'] = uid != null ? await _getUserName(uid) : null;
          mapData['updatedAt'] = data['basicDetailsUpdatedAt'];

          return bd.BasicDetails.fromMap(mapData);
        } else {
          final survey = Survey.fromMap(data);
          final adults = survey.family.members.where((m) => m.isAdult).toList();
          
          return bd.BasicDetails(
            houseNumber: houseNumber,
            headName: adults.isNotEmpty ? adults.first.name : '',
            nic: adults.isNotEmpty ? adults.first.nic : '',
            headGender: adults.isNotEmpty ? adults.first.gender : 'පුරුෂ',
            members: survey.family.members
                .map(
                  (m) => bd.FamilyMember(
                    id: m.id,
                    fullName: m.name,
                    nic: m.nic,
                    dob: m.birthday.toIso8601String(),
                    age: m.age,
                    gender: m.gender,
                    isAdult: m.isAdult,
                  ),
                )
                .toList(),
          );
        }
      }
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Firebase Permission Error: Make sure you are signed in and have proper access to this data.',
        );
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveBasicDetails(
    String houseNumber,
    bd.BasicDetails details,
  ) async {
    try {
      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      DocumentReference ref = _db.collection(_collection).doc(safeHouseNumber);
      await ref.set({
        'basicDetails': details.toMap(),
        'basicDetailsUpdatedBy': FirebaseAuth.instance.currentUser?.uid,
        'basicDetailsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // Housing Details (නිවාස තොරතුරු)
  // ==========================================

  Future<HousingDetails?> getHousingDetails(String houseNumber) async {
    try {
      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      final doc = await _db.collection(_collection).doc(safeHouseNumber).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('housingDetails')) {
          final mapData = Map<String, dynamic>.from(
            data['housingDetails'] as Map,
          );
          
          // 🔥 නිවාස තොරතුරු සඳහා Update ලොගයේ දත්ත ලබා ගැනීම 
          final uid = data['housingDetailsUpdatedBy']?.toString();
          mapData['updatedBy'] = uid != null ? await _getUserName(uid) : null;
          mapData['updatedAt'] = data['housingDetailsUpdatedAt'];

          return HousingDetails.fromMap(mapData);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveHousingDetails(
    String houseNumber,
    HousingDetails details,
  ) async {
    try {
      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      DocumentReference ref = _db.collection(_collection).doc(safeHouseNumber);
      await ref.set({
        'housingDetails': details.toMap(),
        'housingDetailsUpdatedBy': FirebaseAuth.instance.currentUser?.uid,
        'housingDetailsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // Income Details (ආදායම් තොරතුරු)
  // ==========================================

  Future<IncomeDetails?> getIncomeDetails(String houseNumber) async {
    try {
      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      final doc = await _db.collection(_collection).doc(safeHouseNumber).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('incomeDetails')) {
          final mapData = Map<String, dynamic>.from(
            data['incomeDetails'] as Map,
          );

          // 🔥 ආදායම් තොරතුරු සඳහා Update ලොගයේ දත්ත ලබා ගැනීම
          final uid = data['incomeDetailsUpdatedBy']?.toString();
          mapData['updatedBy'] = uid != null ? await _getUserName(uid) : null;
          mapData['updatedAt'] = data['incomeDetailsUpdatedAt'];

          return IncomeDetails.fromMap(mapData);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveIncomeDetails(
    String houseNumber,
    IncomeDetails details,
  ) async {
    try {
      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      DocumentReference ref = _db.collection(_collection).doc(safeHouseNumber);
      await ref.set({
        'incomeDetails': details.toMap(),
        'incomeDetailsUpdatedBy': FirebaseAuth.instance.currentUser?.uid,
        'incomeDetailsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // Assets Details (වත්කම් තොරතුරු)
  // ==========================================

  Future<AssetsDetails?> getAssetsDetails(String houseNumber) async {
    try {
      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      final doc = await _db.collection(_collection).doc(safeHouseNumber).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('assetsDetails')) {
          final mapData = Map<String, dynamic>.from(
            data['assetsDetails'] as Map,
          );

          // 🔥 වත්කම් තොරතුරු සඳහා Update ලොගයේ දත්ත ලබා ගැනීම
          final uid = data['assetsDetailsUpdatedBy']?.toString();
          mapData['updatedBy'] = uid != null ? await _getUserName(uid) : null;
          mapData['updatedAt'] = data['assetsDetailsUpdatedAt'];

          return AssetsDetails.fromMap(mapData);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveAssetsDetails(
    String houseNumber,
    AssetsDetails details,
  ) async {
    try {
      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      DocumentReference ref = _db.collection(_collection).doc(safeHouseNumber);
      await ref.set({
        'assetsDetails': details.toMap(),
        'assetsDetailsUpdatedBy': FirebaseAuth.instance.currentUser?.uid,
        'assetsDetailsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }
}