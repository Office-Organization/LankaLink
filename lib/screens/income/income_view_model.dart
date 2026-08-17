import 'package:flutter/material.dart';
import '../../data/survey_repository.dart';
import '../../models/income_details.dart';

class IncomeViewModel extends ChangeNotifier {
  IncomeViewModel(this._repository, this.houseNumber) {
    details = details.copyWith(houseNumber: houseNumber);
    _loadData();
  }

  final SurveyRepository _repository;
  final String houseNumber;

  IncomeDetails details = IncomeDetails();
  bool isBusy = false;
  String? error;

  Future<void> _loadData() async {
    isBusy = true;
    notifyListeners();

    try {
      final IncomeDetails? fetchedDetails = await _repository.getIncomeDetails(
        houseNumber,
      );
      if (fetchedDetails != null) {
        details = fetchedDetails;
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to load income details: $e');
      debugPrint(stackTrace.toString());
      error = 'දත්ත ලබා ගැනීමේදී දෝෂයක් මතු විය: $e';
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  void updateField({
    String? mainIncome,
    String? extraIncome,
    String? jobType,
    String? jobPosition,
    String? jobInstitute,
    String? tourismType,
    String? tourismOther,
    String? agricultureType,
    String? agricultureOther,
    String? animalHusbandryType,
    String? animalHusbandryOther,
    String? animalCount,
    String? fishingType,
  }) {
    details = details.copyWith(
      mainIncome: mainIncome,
      extraIncome: extraIncome,
      jobType: jobType,
      jobPosition: jobPosition,
      jobInstitute: jobInstitute,
      tourismType: tourismType,
      tourismOther: tourismOther,
      agricultureType: agricultureType,
      agricultureOther: agricultureOther,
      animalHusbandryType: animalHusbandryType,
      animalHusbandryOther: animalHusbandryOther,
      animalCount: animalCount,
      fishingType: fishingType,
    );
    notifyListeners();
  }

  Future<bool> save() async {
    isBusy = true;
    error = null;
    notifyListeners();

    try {
      // Clean up fields if user changed main dropdown to 'නැත' or removed 'වෙනත්'
      final cleanedDetails = details.copyWith(
        jobPosition: details.jobType == 'නැත' ? '' : details.jobPosition,
        jobInstitute: details.jobType == 'නැත' ? '' : details.jobInstitute,
        tourismOther: details.tourismType != 'වෙනත්'
            ? ''
            : details.tourismOther,
        agricultureOther: details.agricultureType != 'වෙනත්'
            ? ''
            : details.agricultureOther,
        animalHusbandryOther: details.animalHusbandryType != 'වෙනත්'
            ? ''
            : details.animalHusbandryOther,
        animalCount: details.animalHusbandryType == 'නැත'
            ? ''
            : details.animalCount,
      );

      await _repository.saveIncomeDetails(houseNumber, cleanedDetails);
      details = cleanedDetails;
      return true;
    } catch (e, stackTrace) {
      debugPrint('Failed to save income details: $e');
      debugPrint(stackTrace.toString());
      error = 'දෝෂය: ${e.toString()}';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}
