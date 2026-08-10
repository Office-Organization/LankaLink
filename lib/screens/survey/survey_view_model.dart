import 'package:flutter/material.dart';
import '../../data/survey_repository.dart';
import '../../data/voter_repository.dart';
import '../../models/survey.dart';
import '../../models/voter.dart';

class SurveyViewModel extends ChangeNotifier {
  SurveyViewModel(this._surveys, this._voters);
  final SurveyRepository _surveys;
  final VoterRepository _voters;

  Survey survey = const Survey(); 
  List<AppVoter> familyMembers = []; // සොයාගත් පවුලේ සාමාජිකයන්
  
  bool isBusy = false;
  String? error;

  // ගෘහ මූලික අංකය සෙවීම
  Future<void> searchHouse(String houseNumber) async {
    if (houseNumber.isEmpty) return;

    isBusy = true; 
    error = null; 
    familyMembers = [];
    notifyListeners();

    try {
      final members = await _voters.findByHouse(houseNumber);
      if (members.isEmpty) {
        error = 'මෙම ගෘහ මූලික අංකයට අදාළ දත්ත හමු නොවීය.';
      } else {
        familyMembers = members;
        // ස්වයංක්‍රීයව පවුලේ ප්‍රධානියා සහ සාමාජික ගණන පෝරමයට යෙදීම
        updateFamily(FamilyInfo(
          headName: members.first.name,
          memberCount: members.length,
        ));
      }
    } catch (e) {
      error = 'දත්ත ලබාගැනීමේදී දෝෂයක් මතු විය.';
    } finally {
      isBusy = false; 
      notifyListeners();
    }
  }

  void updateFamily(FamilyInfo f) {
    survey = survey.copyWith(family: f);
    // මෙහි notifyListeners යොදන්නේ නැත (guide එකට අනුව)
  }

  Future<bool> save() async {
    // ... (පැරණි save ක්‍රියාවලිය එලෙසම පවතී)
    if (survey.family.headName.isEmpty || survey.family.memberCount <= 0) {
      error = 'කරුණාකර සියලුම තොරතුරු නිවැරදිව පුරවන්න.';
      notifyListeners();
      return false;
    }
    isBusy = true; error = null; notifyListeners();
    try {
      await _surveys.save(survey);
      return true;
    } catch (e) {
      error = 'දත්ත සුරැකීමේදී දෝෂයක් මතු විය.';
      return false;
    } finally {
      isBusy = false; notifyListeners();
    }
  }
}