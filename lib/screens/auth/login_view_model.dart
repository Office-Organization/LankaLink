import 'package:flutter/material.dart';
import '../../data/auth_repository.dart';
import '../../core/app_exception.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  LoginViewModel(this._authRepository);

  Future<void> login(String nic, String password) async {
    if (nic.trim().isEmpty || password.trim().isEmpty) {
      _error = 'කරුණාකර ජා.හැ.අංකය සහ මුරපදය ඇතුළත් කරන්න.';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authRepository.signInWithNic(nic, password);

    } on AppException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'ලොගින් වීමට නොහැකි විය: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}