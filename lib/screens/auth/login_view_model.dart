import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lankalink/models/app_user.dart';
import '../../core/app_exception.dart';
import '../../data/auth_repository.dart';

enum LoginErrorType {
  none,
  noAccount,          // ගිණුමක් නොමැති විට
  notActive,          // isActive: false වන විට
  deactivated,        // ගිණුම අක්‍රිය කර ඇති විට
  invalidCredentials, // මුරපදය වැරදි විට
  generalError,
}

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._auth);
  final AuthRepository _auth;

  bool _isDisposed = false;
  bool isLoading = false;
  String? error;
  LoginErrorType errorType = LoginErrorType.none;
  AppUser? user;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<bool> login(String loginId, String password) async {
    if (loginId.isEmpty || password.isEmpty) {
      error = 'කරුණාකර Email/NIC සහ මුරපදය ඇතුලත් කරන්න.';
      errorType = LoginErrorType.generalError;
      notifyListeners();
      return false;
    }

    isLoading = true;
    error = null;
    errorType = LoginErrorType.none;
    user = null;
    notifyListeners();

    try {
      String loginEmail = loginId.trim();
      QuerySnapshot<Map<String, dynamic>> userQuery;

      // 1. Firebase Auth කිරීමට පෙර Firestore එකෙන් පරිශීලකයා පරීක්ෂා කිරීම
      if (!loginId.contains('@')) {
        // NIC මඟින් සෙවීම
        userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('nic', isEqualTo: loginId.trim())
            .limit(1)
            .get();
      } else {
        // Email මඟින් සෙවීම
        userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: loginEmail)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty && loginEmail != loginEmail.toLowerCase()) {
          userQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: loginEmail.toLowerCase())
              .limit(1)
              .get();
        }
      }

      // ගිණුමක් හමු නොවූයේ නම්
      if (userQuery.docs.isEmpty) {
        error = 'මෙම තොරතුරු සඳහා ගිණුමක් ලියාපදිංචි කර නොමැත. කරුණාකර පළමුව ලියාපදිංචි වන්න.';
        errorType = LoginErrorType.noAccount;
        isLoading = false;
        notifyListeners();
        return false;
      }

      final userData = userQuery.docs.first.data();
      final String resolvedEmail = userData['email'] ?? loginEmail;
      final String role = userData['role']?.toString().toLowerCase().trim() ?? '';
      final String status = userData['status']?.toString().toLowerCase().trim() ?? '';

      // isActive පරීක්ෂා කිරීම
      final dynamic isActiveData = userData['isActive'];
      bool isActive = false;
      if (isActiveData is bool) {
        isActive = isActiveData;
      } else if (isActiveData != null) {
        isActive = isActiveData.toString().toLowerCase() == 'true';
      }

      // isDeactivated පරීක්ෂා කිරීම
      final dynamic isDeactivatedData = userData['isDeactivated'];
      bool isDeactivated = (status == 'deactivated');
      if (isDeactivatedData is bool) {
        isDeactivated = isDeactivatedData || isDeactivated;
      } else if (isDeactivatedData != null) {
        isDeactivated = isDeactivatedData.toString().toLowerCase() == 'true' || isDeactivated;
      }

      // A. ගිණුම Deactivate කර ඇත්නම් Pop-up එක සඳහා
      if (isDeactivated) {
        error = 'ඔබගේ ගිණුම අක්‍රිය කර ඇත. කරුණාකර පරිපාලක (Admin) අමතන්න.';
        errorType = LoginErrorType.deactivated;
        isLoading = false;
        notifyListeners();
        return false;
      }

      // B. ගිණුම තවමත් සක්‍රිය (Active) කර නොමැති නම් Pop-up එක සඳහා
      if (role != 'admin' && !isActive) {
        error = 'ඔබගේ ගිණුම තවමත් සක්‍රිය කර නොමැත. පරිපාලක (Admin) අනුමැතිය ලැබෙන තෙක් කරුණාකර රැඳී සිටින්න.';
        errorType = LoginErrorType.notActive;
        isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Account එක Active නම් පමණක් Firebase Auth වෙත Sign In වීම
      UserCredential credential;
      try {
        credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: resolvedEmail,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          error = 'ඇතුළත් කළ මුරපදය වැරදියි. කරුණාකර නැවත උත්සාහ කරන්න.';
          errorType = LoginErrorType.invalidCredentials;
        } else {
          error = 'දෝෂයක් මතු විය: ${e.message ?? e.code}';
          errorType = LoginErrorType.generalError;
        }
        return false;
      }

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw AppException('Login failed, user not found.');
      }

      userData['isActive'] = isActive;
      user = AppUser.fromMap(firebaseUser.uid, userData);
      return true;

    } catch (e) {
      debugPrint('Generic error during login: $e');
      if (errorType == LoginErrorType.none) {
        error = 'දෝෂයක් මතු විය: ${e.toString()}';
        errorType = LoginErrorType.generalError;
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}