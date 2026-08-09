import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_constants.dart';
import '../models/voter.dart';

class VoterRepository {
  VoterRepository(this._db);
  final FirebaseFirestore _db;

  Future<List<Voter>> findByHouse(String houseNumber) async {
    final query = await _db
        .collection(Db.voters)
        .where(Fields.houseNumber, isEqualTo: houseNumber.trim())
        .get();

    return query.docs
        .map((doc) => Voter.fromMap(doc.data()))
        .toList()
      ..sort((a, b) => a.serialNumber.compareTo(b.serialNumber));
  }
}