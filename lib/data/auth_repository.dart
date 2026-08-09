import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_constants.dart';
import '../core/app_strings.dart';
import '../core/app_exception.dart';
import '../models/app_user.dart';

class AuthRepository extends ChangeNotifier {
  AuthRepository(this._auth, this._db) {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AppUser? user;
  bool isLoading = true;

  bool get isSignedIn => user != null;
  bool get isActive => user?.canSignIn ?? false;

  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      user = null;
    } else {
      final doc = await _db.collection(Db.users).doc(firebaseUser.uid).get();
      if (doc.exists) {
        user = AppUser.fromMap(doc.id, doc.data()!);
      } else {
        user = null;
      }
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> signInWithNic(String nic, String password) async {
    try {
      final query = await _db
          .collection(Db.users)
          .where(Fields.nic, isEqualTo: nic.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw const AppException(AppStrings.errWrongLogin);
      }

      final email = query.docs.first.data()[Fields.email] as String?;
      if (email == null || email.isEmpty) {
        throw const AppException(AppStrings.errWrongLogin);
      }

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // _onAuthChanged will load the profile
    } on FirebaseAuthException catch (e) {
      throw _translate(e);
    }
  }

  Future<void> signOut() => _auth.signOut();

  AppException _translate(FirebaseException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return const AppException(AppStrings.errWrongLogin);
      case 'network-request-failed':
        return const AppException(AppStrings.errNoNetwork);
      default:
        return AppException(e.message ?? AppStrings.errWrongLogin);
    }
  }
}