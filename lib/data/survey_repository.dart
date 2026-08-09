import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_constants.dart';
import '../models/survey.dart';

class SurveyRepository {
  SurveyRepository(this._db, this._auth);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<Survey?> find(String id) async {
    final doc = await _db.collection(Db.surveys).doc(id).get();
    if (!doc.exists) return null;
    return Survey.fromMap(doc.id, doc.data()!);
  }

  Future<void> save(Survey survey) async {
    final data = survey.toMap();
    data['lastUpdated'] = FieldValue.serverTimestamp();
    data['updatedBy'] = _auth.currentUser?.uid ?? 'unknown';

    await _db.collection(Db.surveys).doc(survey.id).set(data, SetOptions(merge: true));
  }
}