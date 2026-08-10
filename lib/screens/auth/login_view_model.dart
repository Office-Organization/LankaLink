import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import '../../core/app_exception.dart';
import '../../data/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._auth);
  final AuthRepository _auth;

  bool isLoading = false;
  String? error;

  Future<void> login(String nic, String password) async {
    if (nic.isEmpty || password.isEmpty) {
      error = AppStrings.errEmptyFields;
      notifyListeners();
      return;
    }

    isLoading = true;
    error = null;
    notifyListeners(); // Loading පෙන්වීම ආරම්භ කරයි

    try {
      await _auth.signInWithNic(nic, password);
      // මෙහි Navigation කේත නොමැත, AuthGate මගින් එය ස්වයංක්‍රීයව සිදු කරයි
    } on AppException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners(); // Loading අවසන් කරයි
    }
  }
}
