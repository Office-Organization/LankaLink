import 'dart:async';

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

  static const _requestTimeout = Duration(seconds: 15);

  // Helper function to parse dates in multiple formats
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      // Try removing common prefixes
      String cleanDate = dateStr
          .replaceAll('පිෂමග්: ', '')
          .replaceAll('Birth Date: ', '')
          .trim();

      return DateTime.parse(cleanDate);
    } catch (e) {
      return null;
    }
  }

  /// Adds people saved on the Basic Details screen to the survey family.
  ///
  /// The family data and basic details are stored in the same Firestore
  /// document, but in different fields. Loading both here means children and
  /// other members entered in Basic Details are visible on this screen too.
  Future<Survey> _mergeBasicDetailsMembers(
    Survey sourceSurvey,
    String houseNumber,
  ) async {
    try {
      final basicDetails = await _surveys
          .getBasicDetails(houseNumber)
          .timeout(_requestTimeout);

      if (basicDetails == null) return sourceSurvey;

      final members = List<FamilyMember>.from(sourceSurvey.family.members);

      void addIfMissing(FamilyMember member) {
        if (!members.any((existing) => _isSameMember(existing, member))) {
          members.add(member);
        }
      }

      for (final child in basicDetails.children) {
        addIfMissing(
          FamilyMember(
            id: child.id,
            name: child.name,
            nic: '',
            gender: child.gender,
            birthday: _parseDate(child.dob) ?? DateTime.now(),
          ),
        );
      }

      for (final member in basicDetails.otherMembers) {
        final name = member.name?.trim() ?? '';
        if (name.isEmpty) continue;

        addIfMissing(
          FamilyMember(
            id: member.id.isEmpty ? null : member.id,
            name: name,
            nic: member.nic?.trim() ?? '',
            gender: member.gender ?? '',
            birthday: _parseDate(member.dateOfBirth) ?? DateTime(1990),
          ),
        );
      }

      return sourceSurvey.copyWith(
        houseNumber: houseNumber,
        family: sourceSurvey.family.copyWith(members: members),
      );
    } catch (e) {
      // The saved survey can still be displayed when Basic Details is absent
      // or temporarily unavailable.
      debugPrint('Error loading BasicDetails members: $e');
      return sourceSurvey;
    }
  }

  bool _isSameMember(FamilyMember first, FamilyMember second) {
    if (first.id.isNotEmpty && second.id.isNotEmpty && first.id == second.id) {
      return true;
    }
    if (first.nic.isNotEmpty && second.nic.isNotEmpty) {
      return first.nic == second.nic;
    }
    return first.name.trim().toLowerCase() == second.name.trim().toLowerCase() &&
        first.birthday.year == second.birthday.year &&
        first.birthday.month == second.birthday.month &&
        first.birthday.day == second.birthday.day;
  }

  Future<void> searchHouse(String houseNumber) async {
    final query = houseNumber.trim();
    if (query.isEmpty) return;

    isBusy = true;
    error = null;
    notifyListeners();

    try {
      // Try to get existing survey first
      final existingSurvey = await _surveys
          .getSurveyByHouseNumber(query)
          .timeout(_requestTimeout);

      if (existingSurvey != null) {
        survey = await _mergeBasicDetailsMembers(existingSurvey, query);
      } else {
        // Get members from both voters and BasicDetails
        List<FamilyMember> allMembers = [];

        // 1. Fetch from BasicDetails (children and other members added by user)
        try {
          final basicDetails = await _surveys
              .getBasicDetails(query)
              .timeout(_requestTimeout);
          if (basicDetails != null) {
            // Add children from BasicDetails
            for (var child in basicDetails.children) {
              final dob = _parseDate(child.dob) ?? DateTime.now();
              allMembers.add(
                FamilyMember(
                  id: child.id,
                  name: child.name,
                  nic: '',
                  gender: child.gender == 'ස්ත්‍රී' ? 'ස්ත්‍රී' : 'පුරුෂ',
                  birthday: dob,
                ),
              );
            }

            // Add other members from BasicDetails
            for (var member in basicDetails.otherMembers) {
              final dob = _parseDate(member.dateOfBirth) ?? DateTime(1990);
              allMembers.add(
                FamilyMember(
                  id: member.id.isEmpty ? null : member.id,
                  name: member.name ?? '',
                  nic: member.nic ?? '',
                  gender: member.gender == 'ස්ත්‍රී' ? 'ස්ත්‍රී' : 'පුරුෂ',
                  birthday: dob,
                ),
              );
            }
          }
        } catch (e) {
          // BasicDetails might not exist yet, continue
          debugPrint('Error loading BasicDetails: $e');
        }

        // 2. Fetch from Voter Registry
        try {
          final voters = await _voters.findByHouse(query).timeout(_requestTimeout);
          for (var voter in voters) {
            // Check if this voter is already in allMembers (by NIC)
            final exists = allMembers.any((m) => m.nic == voter.nic);
            if (!exists) {
              allMembers.add(
                FamilyMember(
                  name: voter.name,
                  nic: voter.nic,
                  gender: voter.gender.isEmpty
                      ? 'පුරුෂ'
                      : (voter.gender == 'F' ? 'ස්ත්‍රී' : 'පුරුෂ'),
                  birthday: DateTime(
                    1990,
                    1,
                    1,
                  ), // Default birthday for voters without specific date
                ),
              );
            }
          }
        } catch (e) {
          // Voter registry might not have data, continue
          debugPrint('Error loading voters: $e');
        }

        // 3. Create survey with combined members
        if (allMembers.isEmpty) {
          error = 'මෙම ගෘහ අංකයට අදාළ දත්ත හමු නොවීය.';
          survey = survey.copyWith(houseNumber: query);
        } else {
          survey = Survey(
            houseNumber: query,
            family: FamilyInfo(members: allMembers),
          );
        }
      }
    } on TimeoutException {
      error = 'දත්ත ලබාගැනීමට වැඩි කාලයක් ගත විය. කරුණාකර නැවත උත්සාහ කරන්න.';
      debugPrint('Search timed out for house: $query');
    } catch (e) {
      error = 'දත්ත සෙවීමේදී දෝෂයක් මතු විය: $e';
      debugPrint('Search error: $e');
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  // Refresh members for current house number (useful when coming back from editing)
  Future<void> refreshMembers() async {
    if (survey.houseNumber.isEmpty) return;
    await searchHouse(survey.houseNumber);
  }

  void toggleAswasuma(bool value) {
    survey = survey.copyWith(
      family: survey.family.copyWith(hasAswasuma: value),
    );
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
    notifyListeners();
  }

  void addMember(FamilyMember member) {
    final updatedList = List<FamilyMember>.from(survey.family.members)
      ..add(member);
    survey = survey.copyWith(
      family: survey.family.copyWith(members: updatedList),
    );
    notifyListeners();
  }

  void updateMember(FamilyMember updatedMember) {
    final updatedList = survey.family.members.map((m) {
      return m.id == updatedMember.id ? updatedMember : m;
    }).toList();
    survey = survey.copyWith(
      family: survey.family.copyWith(members: updatedList),
    );
    notifyListeners();
  }

  void removeMember(String id) {
    final updatedList = survey.family.members.where((m) => m.id != id).toList();
    survey = survey.copyWith(
      family: survey.family.copyWith(members: updatedList),
    );
    notifyListeners();
  }

  Future<bool> save() async {
    if (survey.houseNumber.isEmpty || survey.family.members.isEmpty) {
      error = 'කරුණාකර ගෘහ අංකය සහ සාමාජිකයන් ඇතුළත් කරන්න.';
      notifyListeners();
      return false;
    }

    isBusy = true;
    error = null;
    notifyListeners();

    try {
      await _surveys.saveFamilyDetails(survey.houseNumber, survey.family);
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
