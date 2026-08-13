import 'package:flutter/material.dart';
import '../../data/survey_repository.dart';
import '../../models/basic_details.dart';

class BasicDetailsViewModel extends ChangeNotifier {
  BasicDetailsViewModel(this._repository, this.houseNumber) {
    isBusy = true; // තිරය විවෘත වෙද්දීම Loading පෙන්වීමට
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
    String? headGender, String? headName, String? nic, 
    String? dob, String? phone, String? email, 
    String? nationality, bool? hasAntiSocialActivities, 
    String? antiSocialDescription
  }) {
    details = details.copyWith(
      headGender: headGender, headName: headName, nic: nic,
      dob: dob, phone: phone, email: email,
      nationality: nationality, hasAntiSocialActivities: hasAntiSocialActivities,
      antiSocialDescription: antiSocialDescription,
    );
    notifyListeners(); // UI එක Update කරයි
  }

  void addChild(ChildInfo child) {
    final updatedList = List<ChildInfo>.from(details.children)..add(child);
    details = details.copyWith(children: updatedList);
    notifyListeners();
  }

  // 🔥 දරුවන්ගේ තොරතුරු සංස්කරණය (Edit) කිරීම
  void updateChild(ChildInfo updatedChild) {
    final updatedList = details.children.map((c) {
      return c.id == updatedChild.id ? updatedChild : c;
    }).toList();
    details = details.copyWith(children: updatedList);
    notifyListeners();
  }

  void removeChild(String id) {
    final updatedList = details.children.where((c) => c.id != id).toList();
    details = details.copyWith(children: updatedList);
    notifyListeners();
  }

  Future<bool> save() async {
    if (details.headName.isEmpty || details.nic.isEmpty) {
      error = 'කරුණාකර ගෘහ මූලිකයාගේ නම සහ NIC අංකය ඇතුළත් කරන්න.';
      notifyListeners();
      return false;
    }

    isBusy = true; error = null; notifyListeners();

    try {
      await _repository.saveBasicDetails(houseNumber, details);
      return true;
    } catch (e) {
      error = 'දෝෂය: ${e.toString()}';
      return false;
    } finally {
      isBusy = false; notifyListeners(); 
    }
  }
}