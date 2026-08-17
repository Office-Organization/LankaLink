import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lankalink/models/app_user.dart';
import '../../core/app_exception.dart';
import '../../data/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._auth);
  final AuthRepository _auth;

  bool isLoading = false;
  String? error;
  AppUser? user;

  Future<bool> login(String loginId, String password) async {
    if (loginId.isEmpty || password.isEmpty) {
      error = 'Please enter your Email/NIC and Password.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    error = null;
    user = null;
    notifyListeners();

    try {
      String loginEmail = loginId;

      // Check if the input is an NIC (assuming NIC does not contain '@')
      if (!loginId.contains('@')) {
        // Find the user document by NIC in Firestore
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('nic', isEqualTo: loginId)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          error = 'No account found for this NIC.';
          isLoading = false;
          notifyListeners();
          return false;
        }

        // Retrieve the corresponding email for this NIC
        loginEmail = userQuery.docs.first.data()['email'];
      }

      // Proceed to authenticate with FirebaseAuth using the resolved email
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw AppException('Login failed, user not found.');
      }

      // Fetch the full user details from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        await FirebaseAuth.instance.signOut();
        throw AppException('No user record found. Access denied.');
      }

      final data = userDoc.data()!;

      // Parse Firestore data into the AppUser model
      user = AppUser.fromMap(firebaseUser.uid, data);
      return true;
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('FirebaseAuthException during login: ${e.code}\n$stackTrace');
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        error = 'Invalid credentials provided.';
      } else {
        error = 'An error occurred: ${e.message ?? e.code}';
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint('Generic error during login: $e');
      debugPrint(stackTrace.toString());
      error = 'An error occurred during login.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
