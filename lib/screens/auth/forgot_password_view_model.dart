import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_strings.dart';
import '../../core/app_exception.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  ForgotPasswordViewModel(this._auth);
  final FirebaseAuth _auth;

  bool isLoading = false;
  String? message;
  String? error;

  Future<void> sendResetLink(String email) async {
    if (email.isEmpty) {
      error = AppStrings.errEmptyFields;
      notifyListeners();
      return;
    }

    isLoading = true;
    error = null;
    message = null;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      message = 'Password reset link sent to $email.';
    } on FirebaseAuthException catch (e) {
      error = e.message ?? 'An error occurred.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}