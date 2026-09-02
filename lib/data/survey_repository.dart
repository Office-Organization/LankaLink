import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/survey.dart';
import '../models/basic_details.dart' as bd; // 🔥 Alias එකක් යොදා ඇත (නම් පැටලීම වැළැක්වීමට)
import '../models/housing_details.dart';
import '../models/income_details.dart';
import '../models/assets_details.dart';

class SurveyRepository {
  SurveyRepository(this._db);
  
  final FirebaseFirestore _db;
  final String _collection = 'survey_responses';

  Future<Survey?> getSurveyByHouseNumber(String houseNumber) async {
    try {
      // Check user authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Auth Error: Please sign in to access survey data.');
      }

      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      final doc = await _db.collection(_collection).doc(safeHouseNumber).get();
      if (!doc.exists || doc.data() == null) return null;
      
      return Survey.fromMap(doc.data()!);
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

  Future<bd.BasicDetails?> getBasicDetails(String houseNumber) async {
    try {
      // Check user authentication
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
          return bd.BasicDetails.fromMap(mapData);
        } else {
          final survey = Survey.fromMap(data);
          final adults = survey.family.members.where((m) => m.isAdult).toList();
          
          // 🔥 පැරණි children සහ ChildInfo ඉවත් කර members ලිස්ට් එක මෙතනින් සකසා ඇත
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