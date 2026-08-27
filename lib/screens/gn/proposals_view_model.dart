import 'package:flutter/material.dart';

class ProposalsViewModel extends ChangeNotifier {
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<bool> saveDataAndProceed({
    required String proposedProject,
    required String beneficiariesCount,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate save
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
