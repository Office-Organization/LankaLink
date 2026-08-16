import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_constants.dart';

// ඡන්ද දායකයාගේ ආකෘතිය
class AppVoter {
  final String name;
  final String nic;
  final String gender;

  AppVoter({required this.name, required this.nic, required this.gender});

  factory AppVoter.fromMap(Map<String, dynamic> map) => AppVoter(
    name: map['Name'] as String? ?? map['fullName'] as String? ?? '',
    nic: map['NIC'] as String? ?? map['nic'] as String? ?? '',
    gender: map['Gender'] as String? ?? map['gender'] as String? ?? 'පුරුෂ',
  );
}

class VoterRepository {
  VoterRepository(this._db);
  final FirebaseFirestore _db;

  // House_Number එකට අදාළ දත්ත ලබාගැනීම
  Future<List<AppVoter>> findByHouse(String houseNumber) async {
    try {
      // Check user authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Auth Error: Please sign in to access voter data.');
      }

      final snap = await _db
          .collection(Db.voters)
          .where('House_Number', isEqualTo: houseNumber.trim())
          .get();

      return snap.docs.map((doc) => AppVoter.fromMap(doc.data())).toList();
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
}
