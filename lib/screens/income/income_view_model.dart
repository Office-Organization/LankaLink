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
      final IncomeDetails? fetchedDetails = await _repository.getIncomeDetails(houseNumber);
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
    String? fishingOther, // 🟢
    String? otherIncomeDesc,
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
      fishingOther: fishingOther, // 🟢
      otherIncomeDesc: otherIncomeDesc,
    );
    notifyListeners();
  }

  Future<bool> save() async {
    isBusy = true;
    error = null;
    notifyListeners();

    try {
      final main = details.mainIncome;
      final hasExtra = details.extraIncome == 'ඇත';

      String jType = details.jobType;
      String tType = details.tourismType;
      String aType = details.agricultureType;
      String anType = details.animalHusbandryType;
      String fType = details.fishingType;
      String oDesc = details.otherIncomeDesc;

      // ප්‍රධාන ආදායමත් නොවන, අමතර ආදායමකුත් නොමැති ඒවා හිස් කිරීම
      if (!hasExtra) {
         if (main != 'රැකියාව / කුලී වැඩ / ව්‍යාපාර') jType = 'නැත';
         if (main != 'සංචාරක කර්මාන්තය') tType = 'නැත';
         if (main != 'කෘෂිකර්මාන්තය') aType = 'නැත';
         if (main != 'සත්ත්ව කර්මාන්තය') anType = 'නැත';
         if (main != 'ධීවර කර්මාන්තය') fType = 'නැත';
         if (main != 'වෙනත්') oDesc = '';
      }

      final cleanedDetails = details.copyWith(
        jobType: jType,
        jobPosition: (jType == 'නැත' || jType.isEmpty) ? '' : details.jobPosition,
        jobInstitute: (jType == 'නැත' || jType.isEmpty) ? '' : details.jobInstitute,

        tourismType: tType,
        tourismOther: tType != 'වෙනත්' ? '' : details.tourismOther,

        agricultureType: aType,
        agricultureOther: aType != 'වෙනත්' ? '' : details.agricultureOther,

        animalHusbandryType: anType,
        animalHusbandryOther: anType != 'වෙනත්' ? '' : details.animalHusbandryOther,
        animalCount: (anType == 'නැත' || anType.isEmpty) ? '' : details.animalCount,

        fishingType: fType,
        fishingOther: fType != 'වෙනත්' ? '' : details.fishingOther,

        otherIncomeDesc: oDesc,
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