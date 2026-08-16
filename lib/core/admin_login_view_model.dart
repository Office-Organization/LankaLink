import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lankalink/models/app_user.dart';

class AdminLoginViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  /// Attempts to log in a user with admin privileges.
  ///
  /// Returns `true` if login is successful and the user is an admin.
  /// Returns `false` and sets an error message otherwise.
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    if (email.isEmpty || password.isEmpty) {
      _setError('Email and password cannot be empty.');
      _setLoading(false);
      return false;
    }

    try {
      // 1. Sign in with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null)
        throw Exception('Login failed, user not found.');

      // 2. Fetch user data from Firestore to check their role
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        _setError('No user record found. Access denied.');
        _setLoading(false);
        return false;
      }

      // 3. Check the user's role
      final appUser = AppUser.fromMap(firebaseUser.uid, userDoc.data()!);
      if (appUser.isAdmin) {
        _setLoading(false);
        return true;
      } else {
        await _auth.signOut();
        _setError('You do not have admin privileges.');
        _setLoading(false);
        return false;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        _setError('Invalid email or password.');
      } else {
        _setError('An unknown error occurred: ${e.message}');
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred: $e');
      _setLoading(false);
      return false;
    }
  }
}
