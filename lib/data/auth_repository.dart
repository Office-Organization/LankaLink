import 'package:flutter/material.dart';
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
  bool get isActive   => user?.canSignIn ?? false;

  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      user = null;
    } else {
      try {
        final doc = await _db.collection(Db.users).doc(firebaseUser.uid).get();
        user = doc.exists ? AppUser.fromMap(doc.id, doc.data()!) : null;
      } catch (e, stackTrace) {
        debugPrint('Failed to fetch user details on auth change: $e\n$stackTrace');
        user = null; // Ensure user is null on error
      }
    }
    isLoading = false;
    notifyListeners(); // AuthGate වෙත යාවත්කාලීන කිරීම් යවයි
  }

  Future<void> signInWithNic(String nic, String password) async {
    try {
      final found = await _db.collection(Db.users)
          .where('nic', isEqualTo: nic.trim()).limit(1).get();

      if (found.docs.isEmpty) throw const AppException(AppStrings.errWrongLogin);

      final email = found.docs.first.data()['email'] as String? ?? '';
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('FirebaseAuthException in signInWithNic: ${e.code}\n$stackTrace');
      throw _translate(e); 
    }
  }

  Future<void> signOut() => _auth.signOut();

  AppException _translate(FirebaseException e) => switch (e.code) {
    'wrong-password' || 'invalid-credential' || 'user-not-found'
        => const AppException(AppStrings.errWrongLogin),
    'network-request-failed' => const AppException(AppStrings.errNoNetwork),
    _ => AppException(e.message ?? AppStrings.errWrongLogin),
  };
}