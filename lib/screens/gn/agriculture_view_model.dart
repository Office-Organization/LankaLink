
import 'package:flutter/material.dart';

class AgricultureViewModel extends ChangeNotifier {
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  // Dropdown 1: Development Category
  String? selectedDevelopmentCategory;
  final List<String> developmentCategories = [
    'ඇළ මාර්ග',
    'අමුණු',
    'කෘෂි මාර්ග',
    'පෙට්ටි බෝක්කු',
    'සිලින්ඩර් යොදන ස්ථාන',
  ];

  // Dropdown 2: Development Type
  String? selectedDevelopmentType;
  final List<String> developmentTypes = [
    'ප්‍රතිසංස්කරණය',
    'නව ඉදිකිරීම',
  ];

  // Location Coordinate (Map Point placeholder)
  String? selectedLocationCoordinates;

  void updateDevelopmentCategory(String? category) {
    selectedDevelopmentCategory = category;
    notifyListeners();
  }

  void updateDevelopmentType(String? type) {
    selectedDevelopmentType = type;
    notifyListeners();
  }

  void setLocationCoordinates(String coordinates) {
    selectedLocationCoordinates = coordinates;
    notifyListeners();
  }

  Future<bool> saveDataAndProceed({
    required String locationName,
    required String beneficiariesCount,
  }) async {
    _isSaving = true;
    notifyListeners();

    const String currentUserIdentifier = "981234567V";
    final String currentTimestamp = DateTime.now().toIso8601String();

    final Map<String, dynamic> dataToSave = {
      "primary_user_id": currentUserIdentifier,
      "added_by": currentUserIdentifier,
      "last_edited_by": currentUserIdentifier,
      "created_at_timestamp": currentTimestamp,
      "updated_at_timestamp": currentTimestamp,
      "agriculture_infrastructure": {
        "development_category": selectedDevelopmentCategory ?? "",
        "development_type": selectedDevelopmentType ?? "",
        "location_name": locationName,
        "map_coordinates": selectedLocationCoordinates ?? "",
        "beneficiaries_count": beneficiariesCount,
      },
      "edit_logs": [
        {
          "action": "CREATED",
          "user": currentUserIdentifier,
          "timestamp": currentTimestamp,
        }
      ]
    };

    try {
      debugPrint("Saving Agriculture Data: $dataToSave");
      // Simulating backend delay
      await Future.delayed(const Duration(seconds: 1));
      
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error saving agriculture data: $e");
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}