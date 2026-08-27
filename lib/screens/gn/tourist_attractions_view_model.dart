import 'package:flutter/material.dart';

class TouristAttractionsViewModel extends ChangeNotifier {
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _selectedLocationCoordinates;
  String? get selectedLocationCoordinates => _selectedLocationCoordinates;

  void setLocationCoordinates(String coordinates) {
    _selectedLocationCoordinates = coordinates;
    notifyListeners();
  }

  Future<bool> saveDataAndProceed({
    required String locationName,
    required String developmentNeeds,
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