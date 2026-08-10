import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/survey.dart';

class SurveyRepository {
  SurveyRepository(this._db);
  final FirebaseFirestore _db;

  // Firebase හි 'surveys' නම් collection එකට දත්ත සේව් කිරීම
  Future<void> save(Survey survey) async {
    await _db.collection('surveys').add(survey.toMap());
  }
}
