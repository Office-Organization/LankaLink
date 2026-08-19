
import 'package:flutter/material.dart';

class DailyFacilitiesViewModel extends ChangeNotifier {
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  // Dropdown 1: Facility Type
  String? selectedFacilityType;
  final List<String> facilityTypes = [
    'බස් නැවතුම',     // Bus Stop
    'ඩිස්පෙන්සරිය',     // Dispensary
    'පුස්තකාලය',       // Library
    'සුසාන භූමිය',      // Cemetery
  ];

  // Map Coordinates
  String? selectedLocationCoordinates;

  // Dropdown 2: Government Land Availability
  String? hasGovernmentLand;
  final List<String> governmentLandOptions = [
    'ඔව්',   // Yes
    'නැත',   // No
  ];

  void updateFacilityType(String? type) {
    selectedFacilityType = type;
    notifyListeners();
  }

  void setLocationCoordinates(String coordinates) {
    selectedLocationCoordinates = coordinates;
    notifyListeners();
  }

  void updateGovernmentLand(String? value) {
    hasGovernmentLand = value;
    notifyListeners();
  }

  Future<bool> saveDataAndProceed({
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
      "daily_facilities": {
        "facility_type": selectedFacilityType ?? "",
        "map_coordinates": selectedLocationCoordinates ?? "",
        "has_government_land": hasGovernmentLand ?? "",
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
      debugPrint("Saving Daily Facilities Data: $dataToSave");
      // Simulating backend network delay
      await Future.delayed(const Duration(seconds: 1));
      
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error saving daily facilities data: $e");
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}