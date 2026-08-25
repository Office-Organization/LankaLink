import 'package:flutter/material.dart';
import '../../data/survey_repository.dart';
import '../../models/housing_details.dart';

class HousingViewModel extends ChangeNotifier {
  HousingViewModel(this._repository, this.houseNumber) {
    details = details.copyWith(houseNumber: houseNumber);
    _loadData();
  }
  
  final SurveyRepository _repository;
  final String houseNumber;

  HousingDetails details = HousingDetails();
  bool isBusy = false;
  String? error;

  Future<void> _loadData() async {
    isBusy = true; 
    notifyListeners();

    try {
      // 🔥 Type එක පැහැදිලිවම ලබාදීම මගින් දෝෂය වළක්වයි
      final HousingDetails? fetchedDetails = await _repository.getHousingDetails(houseNumber);
      
      if (fetchedDetails != null) {
        details = fetchedDetails; 
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to load housing details: $e');
      debugPrint(stackTrace.toString());
      error = 'දත්ත ලබා ගැනීමේදී දෝෂයක් මතු විය: $e';
    } finally {
      isBusy = false; 
      notifyListeners();
    }
  }

  void updateField({
    bool? hasHouse, String? nature, String? sanitation, 
    String? electricity, String? water, 
    bool? hasFixedPhone, bool? hasMobilePhone, String? signal
  }) {
    details = details.copyWith(
      hasHouse: hasHouse, nature: nature, sanitation: sanitation,
      electricity: electricity, water: water,
      hasFixedPhone: hasFixedPhone, hasMobilePhone: hasMobilePhone, signal: signal,
    );
    notifyListeners();
  }

  Future<bool> save() async {
    isBusy = true; error = null; notifyListeners();

    try {
      await _repository.saveHousingDetails(houseNumber, details);
      return true;
    } catch (e, stackTrace) {
      debugPrint('Failed to save housing details: $e');
      debugPrint(stackTrace.toString());
      error = 'දෝෂය: ${e.toString()}';
      return false;
    } finally {
      isBusy = false; notifyListeners(); 
    }
  }
}