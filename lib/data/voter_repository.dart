import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_constants.dart';
import '../models/voter.dart';

class VoterRepository {
  VoterRepository(this._db);
  final FirebaseFirestore _db;

  // House_Number එකට අදාළ සියලුම සාමාජිකයන් ලබාගැනීම
  Future<List<AppVoter>> findByHouse(String houseNumber) async {
    final snap = await _db
        .collection(Db.voters)
        .where('House_Number', isEqualTo: houseNumber.trim())
        .get();

    return snap.docs
        .map((doc) => AppVoter.fromMap(doc.id, doc.data()))
        .toList();
  }
}
