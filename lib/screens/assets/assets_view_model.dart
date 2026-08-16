import 'package:flutter/material.dart';
import '../../data/survey_repository.dart';
import '../../models/assets_details.dart';

class AssetsViewModel extends ChangeNotifier {
  AssetsViewModel(this._repository, this.houseNumber) {
    details = details.copyWith(houseNumber: houseNumber);
    _loadData();
  }

  final SurveyRepository _repository;
  final String houseNumber;

  AssetsDetails details = AssetsDetails();
  bool isBusy = false;
  String? error;

  Future<void> _loadData() async {
    isBusy = true;
    notifyListeners();

    try {
      final AssetsDetails? fetchedDetails = await _repository.getAssetsDetails(
        houseNumber,
      );
      if (fetchedDetails != null) {
        details = fetchedDetails;
      }
    } catch (e) {
      error = 'දත්ත ලබා ගැනීමේදී දෝෂයක් මතු විය.';
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  void updateField({
    bool? hasHighland,
    String? highlandExtent,
    bool? isHighlandCultivated,
    bool? hlNoWater,
    bool? hlAnimalDamage,
    bool? hlMoneyLabor,
    bool? hlOther,
    bool? hasMudland,
    String? mudlandExtent,
    bool? isMudlandCultivated,
    bool? mlNoWater,
    bool? mlAnimalDamage,
    bool? mlMoneyLabor,
    bool? mlEquipment,
    bool? mlFertilizer,
    bool? mlOther,
    bool? hasBike,
    bool? hasThreeWheeler,
    bool? hasVan,
    bool? hasLorry,
    bool? hasBus,
    bool? hasTractor,
    bool? hasCar,
    bool? hasCab,
    bool? hasOtherVehicle,
  }) {
    details = details.copyWith(
      hasHighland: hasHighland,
      highlandExtent: highlandExtent,
      isHighlandCultivated: isHighlandCultivated,
      hlNoWater: hlNoWater,
      hlAnimalDamage: hlAnimalDamage,
      hlMoneyLabor: hlMoneyLabor,
      hlOther: hlOther,
      hasMudland: hasMudland,
      mudlandExtent: mudlandExtent,
      isMudlandCultivated: isMudlandCultivated,
      mlNoWater: mlNoWater,
      mlAnimalDamage: mlAnimalDamage,
      mlMoneyLabor: mlMoneyLabor,
      mlEquipment: mlEquipment,
      mlFertilizer: mlFertilizer,
      mlOther: mlOther,
      hasBike: hasBike,
      hasThreeWheeler: hasThreeWheeler,
      hasVan: hasVan,
      hasLorry: hasLorry,
      hasBus: hasBus,
      hasTractor: hasTractor,
      hasCar: hasCar,
      hasCab: hasCab,
      hasOtherVehicle: hasOtherVehicle,
    );
    notifyListeners();
  }

  Future<bool> save() async {
    isBusy = true;
    error = null;
    notifyListeners();

    try {
      await _repository.saveAssetsDetails(houseNumber, details);
      return true;
    } catch (e) {
      error = 'දෝෂය: ${e.toString()}';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}
