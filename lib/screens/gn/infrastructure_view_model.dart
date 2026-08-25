
import 'package:flutter/material.dart';

class InfrastructureViewModel extends ChangeNotifier {
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  // Road Variables
  String? selectedRoadType;
  final List<String> roadTypes = ['කාපට්', 'කැටගල්', 'කොන්ක්‍රීට්'];

  // Bridge Variables
  String? selectedBridgeType;
  final List<String> bridgeTypes = ['බෝක්කු', 'සපත්තු පාලම', 'යකඩ පාලම'];

  void updateRoadType(String? type) {
    selectedRoadType = type;
    notifyListeners();
  }

  void updateBridgeType(String? type) {
    selectedBridgeType = type;
    notifyListeners();
  }

  Future<bool> saveDataAndProceed({
    required String roadName,
    required String roadDistance,
    required String roadBeneficiaries,
    required String bridgeName,
    required String bridgeCondition,
    required String bridgeBeneficiaries,
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
      "roads_infrastructure": {
        "road_name": roadName,
        "road_type": selectedRoadType ?? "",
        "development_distance": roadDistance,
        "beneficiaries_count": roadBeneficiaries,
      },
      "bridges_infrastructure": {
        "bridge_name": bridgeName,
        "bridge_type": selectedBridgeType ?? "",
        "current_condition": bridgeCondition,
        "beneficiaries_count": bridgeBeneficiaries,
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
      debugPrint("Data successfully mapped for Firebase: $dataToSave");
      await Future.delayed(const Duration(seconds: 1)); // Simulating network
      
      _isSaving = false;
      notifyListeners();
      return true; 
    } catch (e) {
      debugPrint("Error saving data: $e");
      _isSaving = false;
      notifyListeners();
      return false; 
    }
  }
}
