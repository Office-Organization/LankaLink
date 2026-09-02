import 'package:flutter/material.dart';
import '../../data/survey_repository.dart';
import '../../models/basic_details.dart';

class BasicDetailsViewModel extends ChangeNotifier {
  BasicDetailsViewModel(this._repository, this.houseNumber) {
    isBusy = true;
    details = details.copyWith(houseNumber: houseNumber);
    _loadData();
  }

  final SurveyRepository _repository;
  final String houseNumber;

  BasicDetails details = BasicDetails();
  bool isBusy = false;
  String? error;

  Future<void> _loadData() async {
    try {
      final fetchedDetails = await _repository.getBasicDetails(houseNumber);
      if (fetchedDetails != null) {
        details = fetchedDetails;
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to load basic details: $e');
      debugPrint(stackTrace.toString());
      error = 'දත්ත ලබා ගැනීමේදී දෝෂයක් මතු විය: $e';
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  void updateField({
    String? headGender,
    String? headName,
    String? nic,
    String? dob,
    String? phone,
    String? email,
    String? nationality,
    bool? hasAntiSocialActivities,
    String? antiSocialDescription,
  }) {
    details = details.copyWith(
      headGender: headGender,
      headName: headName,
      nic: nic,
      dob: dob,
      phone: phone,
      email: email,
      nationality: nationality,
      hasAntiSocialActivities: hasAntiSocialActivities,
      antiSocialDescription: antiSocialDescription,
    );
    notifyListeners();
  }

  // අලුත් Member Method එක
  void addMember(FamilyMember member) {
    final updatedList = List<FamilyMember>.from(details.members)..add(member);
    details = details.copyWith(members: updatedList);
    notifyListeners();
  }

  void updateMember(FamilyMember updatedMember) {
    final updatedList = details.members.map((m) => m.id == updatedMember.id ? updatedMember : m).toList();
    details = details.copyWith(members: updatedList);
    notifyListeners();
  }

  void removeMember(String id) {
    final updatedList = details.members.where((m) => m.id != id).toList();
    details = details.copyWith(members: updatedList);
    notifyListeners();
  }

  Future<bool> save() async {
    if (details.headName.isEmpty || details.nic.isEmpty) {
      error = 'කරුණාකර ගෘහ මූලිකයාගේ නම සහ NIC අංකය ඇතුළත් කරන්න.';
      notifyListeners();
      return false;
    }

    isBusy = true;
    error = null;
    notifyListeners();

    try {
      await _repository.saveBasicDetails(houseNumber, details);
      return true;
    } catch (e, stackTrace) {
      debugPrint('Failed to save basic details: $e');
      debugPrint(stackTrace.toString());
      error = 'දෝෂය: ${e.toString()}';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}