import 'package:flutter/material.dart';

class DisastersViewModel extends ChangeNotifier {
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _selectedDisasterType;
  String? get selectedDisasterType => _selectedDisasterType;

  String? _selectedLocationCoordinates;
  String? get selectedLocationCoordinates => _selectedLocationCoordinates;

  final List<String> disasterTypes = [
    'ගංවතුර', // Floods
    'නාය යෑම්', // Landslides
    'නියං', // Drought
    'අනෙකුත්', // Other
  ];

  void updateDisasterType(String? value) {
    _selectedDisasterType = value;
    notifyListeners();
  }

  void setLocationCoordinates(String coordinates) {
    _selectedLocationCoordinates = coordinates;
    notifyListeners();
  }

  Future<bool> finishAndSave() async {
    _isSaving = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate final save
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
