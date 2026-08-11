import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/survey.dart';

class SurveyRepository {
  SurveyRepository(this._db);
  final FirebaseFirestore _db;
  final String _collection = 'survey_responses';

  Future<Survey?> getSurveyByHouseNumber(String houseNumber) async {
    try {
      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      final doc = await _db.collection(_collection).doc(safeHouseNumber).get();
      
      if (!doc.exists || doc.data() == null) {
        return null; 
      }
      return Survey.fromMap(doc.data()!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveFamilyDetails(String houseNumber, FamilyInfo family) async {
    try {
      String safeHouseNumber = houseNumber.replaceAll('/', '-');
      DocumentReference ref = _db.collection(_collection).doc(safeHouseNumber);

      List<Map<String, dynamic>> membersData = family.members.map((m) => {
        'id': m.id,
        'nic': m.nic,
        'fullName': m.name,
        'dob': m.birthday.toIso8601String(),
        'gender': m.gender,
        'isAdult': m.isAdult,
        'age': m.age,
      }).toList();

      await ref.set({
        'houseNumber': houseNumber,
        'hasAswasuma': family.hasAswasuma,
        'specialNeedsCount': family.specialNeedsCount,
        'specialNeedsAmount': family.specialNeedsAmount,
        'specialNeedDescription': family.specialNeedDescription, // 🔥 අලුතින් එක් කළ කොටස
        'members': membersData, 
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      rethrow; 
    }
  }
}