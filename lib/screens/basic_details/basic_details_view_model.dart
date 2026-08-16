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
    } catch (e) {
      error = 'දත්ත ලබා ගැනීමේදී දෝෂයක් මතු විය.';
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

  void addChild(ChildInfo child) {
    final updatedList = List<ChildInfo>.from(details.children)..add(child);
    details = details.copyWith(children: updatedList);
    notifyListeners();
  }

  void updateChild(ChildInfo updatedChild) {
    final updatedList = details.children
        .map((c) => c.id == updatedChild.id ? updatedChild : c)
        .toList();
    details = details.copyWith(children: updatedList);
    notifyListeners();
  }

  void removeChild(String id) {
    final updatedList = details.children.where((c) => c.id != id).toList();
    details = details.copyWith(children: updatedList);
    notifyListeners();
  }

  // 🔥 වෙනත් සාමාජිකයන් (Other Members) සඳහා Methods
  void addOtherMember(OtherMemberInfo member) {
    final updatedList = List<OtherMemberInfo>.from(details.otherMembers)
      ..add(member);
    details = details.copyWith(otherMembers: updatedList);
    notifyListeners();
  }

  void updateOtherMember(OtherMemberInfo updatedMember) {
    final updatedList = details.otherMembers
        .map((m) => (m.id) == (updatedMember.id) ? updatedMember : m)
        .toList();
    details = details.copyWith(otherMembers: updatedList);
    notifyListeners();
  }

  void removeOtherMember(String id) {
    final updatedList = details.otherMembers
        .where((m) => (m.id) != id)
        .toList();
    details = details.copyWith(otherMembers: updatedList);
    notifyListeners();
  }

  // 🔥 Age Calculation Methods
  int getAge(String dateOfBirth) {
    try {
      final dob = DateTime.parse(dateOfBirth);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  bool isChild(String dateOfBirth) {
    return getAge(dateOfBirth) < 18;
  }

  String getCategoryLabel(String dateOfBirth) {
    return isChild(dateOfBirth) ? '(ළමා)' : '(වැඩිහිටි)';
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
    } catch (e) {
      error = 'දෝෂය: ${e.toString()}';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}
