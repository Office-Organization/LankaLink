import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lankalink/models/app_user.dart';
import '../../core/app_exception.dart';
import '../../data/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._auth);
  final AuthRepository _auth; // Not used directly, but good practice to keep

  bool isLoading = false;
  String? error;
  AppUser? user;

  Future<bool> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      error = 'කරුණාකර ඊමේල් ලිපිනය සහ මුරපදය ඇතුළත් කරන්න.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    error = null;
    user = null;
    notifyListeners();

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw AppException('Login failed, user not found.');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        throw AppException('No user record found. Access denied.');
      }

      user = AppUser.fromMap(firebaseUser.uid, userDoc.data()!);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        error = 'ඔබ ඇතුළත් කළ ඊමේල් ලිපිනය හෝ මුරපදය වැරදියි.';
      } else {
        error = 'දෝෂයක් මතු විය: ${e.message}';
      }
      return false;
    } catch (e) {
      error = 'ලොග් වීමේදී දෝෂයක් මතු විය.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
