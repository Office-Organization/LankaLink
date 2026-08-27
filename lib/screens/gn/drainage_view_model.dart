import 'package:flutter/material.dart';

class DrainageViewModel extends ChangeNotifier {
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<bool> saveDataAndProceed({
    required String locationName,
    required String developmentAmount,
    required String currentCondition,
    required String beneficiariesCount,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      // TODO: Add your API call or local database save logic here
      // Simulating a network request delay
      await Future.delayed(const Duration(seconds: 2));

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