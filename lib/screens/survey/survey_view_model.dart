import 'package:flutter/material.dart';
import '../../data/survey_repository.dart';
import '../../data/voter_repository.dart';
import '../../models/survey.dart';

class SurveyViewModel extends ChangeNotifier {
  SurveyViewModel(this._surveys, this._voters);
  final SurveyRepository _surveys;
  final VoterRepository _voters;

  Survey survey = const Survey(); 
  bool isBusy = false;
  String? error;

  Future<void> searchHouse(String houseNumber) async {
    final query = houseNumber.trim();
    if (query.isEmpty) return;

    isBusy = true; 
    error = null; 
    notifyListeners();

    try {
      final existingSurvey = await _surveys.getSurveyByHouseNumber(query);
      
      if (existingSurvey != null) {
        survey = existingSurvey;
      } else {
        final voters = await _voters.findByHouse(query);
        
        if (voters.isEmpty) {
          error = 'මෙම ගෘහ අංකයට අදාළ දත්ත හමු නොවීය.';
          survey = survey.copyWith(houseNumber: query);
        } else {
          final members = voters.map((v) => FamilyMember(
            name: v.name,
            nic: v.nic,
            gender: v.gender == 'F' ? 'ස්ත්‍රී' : 'පුරුෂ', 
            birthday: DateTime(1990, 1, 1), 
          )).toList();

          survey = Survey(
            houseNumber: query,
            family: FamilyInfo(members: members),
          );
        }
      }
    } catch (e) {
      error = 'දත්ත සෙවීමේදී දෝෂයක් මතු විය: $e';
    } finally {
      isBusy = false; 
      notifyListeners();
    }
  }

  void toggleAswasuma(bool value) {
    survey = survey.copyWith(family: survey.family.copyWith(hasAswasuma: value));
    notifyListeners();
  }

  void updateSpecialNeeds(int count, double amount, String description) {
    survey = survey.copyWith(
      family: survey.family.copyWith(
        specialNeedsCount: count,
        specialNeedsAmount: amount,
        specialNeedDescription: description,
      ),
    );
  }

  void addMember(FamilyMember member) {
    final updatedList = List<FamilyMember>.from(survey.family.members)..add(member);
    survey = survey.copyWith(family: survey.family.copyWith(members: updatedList));
    notifyListeners();
  }

  void updateMember(FamilyMember updatedMember) {
    final updatedList = survey.family.members.map((m) {
      return m.id == updatedMember.id ? updatedMember : m;
    }).toList();
    survey = survey.copyWith(family: survey.family.copyWith(members: updatedList));
    notifyListeners();
  }

  void removeMember(String id) {
    final updatedList = survey.family.members.where((m) => m.id != id).toList();
    survey = survey.copyWith(family: survey.family.copyWith(members: updatedList));
    notifyListeners();
  }

  Future<bool> save() async {
    if (survey.houseNumber.isEmpty || survey.family.members.isEmpty) {
      error = 'කරුණාකර ගෘහ අංකය සහ සාමාජිකයන් ඇතුළත් කරන්න.';
      notifyListeners();
      return false;
    }

    isBusy = true; error = null; notifyListeners();

    try {
      await _surveys.saveFamilyDetails(survey.houseNumber, survey.family);
      return true;
    } catch (e) {
      error = 'දෝෂය: ${e.toString()}';
      return false;
    } finally {
      isBusy = false; notifyListeners(); 
    }
  }
}