import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GNSummaryViewModel extends ChangeNotifier {
  bool isLoadingGNs = true;
  bool isGenerating = false;
  String? selectedGN;
  List<String> gnDivisions = [];
  
  Map<String, dynamic> reportData = {};
  List<Map<String, dynamic>> allFamilies = [];
  List<Map<String, dynamic>> displayedFamilies = [];

  String searchQuery = '';
  String selectedFilter = 'සියල්ල (All)';
  
  final List<String> filterOptions = [
    'සියල්ල (All)',
    'අස්වැසුම ලබන',
    'විශේෂ අවශ්‍යතා සහිත',
    'සමාජ විරෝධී ක්‍රියාකාරකම්',
    'කාන්තා මූලික පවුල්',
    'නිවාස නොමැති පවුල්' 
  ];

  GNSummaryViewModel() {
    fetchGNDivisions();
  }

  Future<void> fetchGNDivisions() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('survey_responses').get();
      final Set<String> gns = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['gnDivision'] != null && data['gnDivision'].toString().isNotEmpty) {
          gns.add(data['gnDivision'].toString());
        }
      }
      gnDivisions = gns.toList()..sort();
      isLoadingGNs = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching GNs: $e");
      isLoadingGNs = false;
      notifyListeners();
    }
  }

  int? _calculateRealAge(String? nic, String? dobStr) {
    final now = DateTime.now();

    if (nic != null && nic.trim().isNotEmpty && nic.trim() != '-') {
      String cleanNic = nic.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      if (cleanNic.length == 10 && (cleanNic.endsWith('V') || cleanNic.endsWith('X'))) {
        int? yearOffset = int.tryParse(cleanNic.substring(0, 2));
        if (yearOffset != null) return now.year - (1900 + yearOffset);
      } else if (cleanNic.length == 12) {
        int? fullYear = int.tryParse(cleanNic.substring(0, 4));
        if (fullYear != null) return now.year - fullYear;
      }
    }

    if (dobStr != null && dobStr.isNotEmpty) {
      if (!dobStr.startsWith('1990-01-01')) {
        DateTime? d = DateTime.tryParse(dobStr);
        if (d != null) {
          int age = now.year - d.year;
          if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
          return age;
        }
      }
    }

    return null; 
  }

  // 🔥 අතිශය නිවැරදිව "නැත" හඳුනාගන්නා ලොජික් එක (Bulletproof check)
  bool _isNo(dynamic val) {
    if (val == null) return true; // දත්ත නැත්නම් ඒකත් "නැත"
    if (val is bool) return !val; // false නම් "නැත"
    
    final str = val.toString().trim().toLowerCase();
    if (str.isEmpty || 
        str == 'false' || 
        str == 'no' || 
        str == '0' || 
        str == 'null' || 
        str.contains('නැත')) {
      return true;
    }
    return false;
  }

  Future<void> generateReport(String gn) async {
    selectedGN = gn;
    isGenerating = true;
    reportData.clear();
    allFamilies.clear();
    displayedFamilies.clear();
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('survey_responses')
          .where('gnDivision', isEqualTo: selectedGN)
          .get();

      int totalFamilies = snapshot.docs.length;
      int totalPopulation = 0;
      int totalMale = 0, totalFemale = 0;
      int sinhalaCount = 0, tamilCount = 0, muslimCount = 0;
      
      int femaleHeadedCount = 0;
      int specialNeedsFamilyCount = 0;
      int aswasumaCount = 0;
      int antiSocialFamilyCount = 0;
      int schoolDropouts = 0;

      int noIncomeGovtAid = 0;
      int noIncomeNoGovtAid = 0;
      int noHousingCount = 0;
      int noWaterPowerCount = 0;
      int agriFamilies = 0;
      int animalFamilies = 0;
      int fishingFamilies = 0;

      for (var doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        bool hasAswasuma = data['hasAswasuma'] == true;
        if (hasAswasuma) aswasumaCount++;
        if ((data['specialNeedsCount'] ?? 0) > 0) specialNeedsFamilyCount++;

        // Basic Details Check
        if (data['basicDetails'] is Map) {
          final basicDetails = Map<String, dynamic>.from(data['basicDetails']);
          data['basicDetails'] = basicDetails;

          if (basicDetails['headGender'] == 'ස්ත්‍රී') femaleHeadedCount++;
          if (basicDetails['hasAntiSocialActivities'] == true) antiSocialFamilyCount++;

          final nationality = basicDetails['nationality']?.toString() ?? '';
          if (nationality == 'සිංහල') sinhalaCount++;
          else if (nationality == 'දෙමළ' || nationality == 'දමිළ') tamilCount++;
          else if (nationality == 'මුස්ලිම්') muslimCount++;

          if (basicDetails['members'] is List) {
            final membersList = List<dynamic>.from(basicDetails['members']);
            final List<Map<String, dynamic>> updatedMembers = [];
            bool familyHasAntiSocial = false;

            for (var memberData in membersList) {
              if (memberData is Map) {
                final m = Map<String, dynamic>.from(memberData);
                if (m['gender'] == 'පුරුෂ') totalMale++;
                if (m['gender'] == 'ස්ත්‍රී') totalFemale++;
                
                int? realAge = _calculateRealAge(m['nic']?.toString(), m['dob']?.toString());
                m['calculatedAge'] = realAge;
                m['ageDisplay'] = realAge != null ? realAge.toString() : 'උපන්දිනය ඇතුළත් කර නැත';
                
                int logicAge = realAge ?? (m['age'] ?? 0);
                if (logicAge >= 5 && logicAge <= 18 && m['attendsSchool'] != true) schoolDropouts++;
                if (m['hasAntiSocialActivities'] == true) familyHasAntiSocial = true;
                
                updatedMembers.add(m); 
              }
            }
            basicDetails['members'] = updatedMembers;
            totalPopulation += updatedMembers.length;

            if (basicDetails['hasAntiSocialActivities'] != true && familyHasAntiSocial) {
               antiSocialFamilyCount++;
            }
          }
        }

        // Income Details Check
        if (data['incomeDetails'] is Map) {
          final inc = data['incomeDetails'] as Map;
          bool hasNoJob = _isNo(inc['jobType']); 
          
          if (hasNoJob) {
            if (hasAswasuma) noIncomeGovtAid++; else noIncomeNoGovtAid++;
          }
          if (!_isNo(inc['agricultureType'])) agriFamilies++;
          if (!_isNo(inc['animalHusbandryType'])) animalFamilies++;
          if (!_isNo(inc['fishingType'])) fishingFamilies++;
        }

        // 🔥 නිවාස දත්ත විශ්ලේෂණය (Fail-proof)
        Map<dynamic, dynamic> hs = {};
        if (data.containsKey('housingDetails') && data['housingDetails'] is Map) {
          hs = data['housingDetails'] as Map;
        }

        bool hasNoHouse = _isNo(hs['hasHouse']);
        bool hasNoElectricity = _isNo(hs['electricity']);
        bool hasNoWater = _isNo(hs['water']);

        // නිවසක් නොමැති නම්
        if (hasNoHouse) {
          noHousingCount++;
        }
        
        // විදුලිය හෝ ජලය නොමැති නම්
        if (hasNoElectricity || hasNoWater) {
          noWaterPowerCount++;
        }

        allFamilies.add(data);
      }

      reportData = {
        'totalFamilies': totalFamilies,
        'totalPopulation': totalPopulation,
        'totalMale': totalMale,
        'totalFemale': totalFemale,
        'sinhala': sinhalaCount,
        'tamil': tamilCount,
        'muslim': muslimCount,
        'femaleHeaded': femaleHeadedCount,
        'specialNeeds': specialNeedsFamilyCount,
        'aswasuma': aswasumaCount,
        'antiSocial': antiSocialFamilyCount,
        'dropouts': schoolDropouts,
        'noIncomeGovtAid': noIncomeGovtAid,
        'noIncomeNoGovtAid': noIncomeNoGovtAid,
        'noHousingCount': noHousingCount, // 🟢 දැන් නිවැරදිව ගණනය වේ
        'noWaterPowerCount': noWaterPowerCount, // 🟢 දැන් නිවැරදිව ගණනය වේ
        'agriFamilies': agriFamilies,
        'animalFamilies': animalFamilies,
        'fishingFamilies': fishingFamilies,
      };

      displayedFamilies = List<Map<String, dynamic>>.from(allFamilies);

    } catch (e) {
      debugPrint('Error generating report: $e');
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  void applyFilters(String query, String filter) {
    searchQuery = query.toLowerCase();
    selectedFilter = filter;

    displayedFamilies = allFamilies.where((family) {
      bool matchesSearch = false;
      final hn = (family['houseNumber'] ?? '').toString().toLowerCase();
      
      String headName = '';
      String headNic = '';
      if (family['basicDetails'] is Map) {
        final basic = family['basicDetails'] as Map;
        headName = (basic['headName'] ?? '').toString().toLowerCase();
        headNic = (basic['nic'] ?? '').toString().toLowerCase();
      }

      if (hn.contains(searchQuery) || headName.contains(searchQuery) || headNic.contains(searchQuery)) {
        matchesSearch = true;
      }

      if (!matchesSearch && searchQuery.isNotEmpty) return false;

      if (selectedFilter == 'අස්වැසුම ලබන') {
        if (family['hasAswasuma'] != true) return false;
      } 
      else if (selectedFilter == 'විශේෂ අවශ්‍යතා සහිත') {
        if ((family['specialNeedsCount'] ?? 0) <= 0) return false;
      } 
      else if (selectedFilter == 'කාන්තා මූලික පවුල්') {
        if (family['basicDetails'] is Map && family['basicDetails']['headGender'] != 'ස්ත්‍රී') return false;
      } 
      else if (selectedFilter == 'සමාජ විරෝධී ක්‍රියාකාරකම්') {
        bool hasAntiSocial = false;
        if (family['basicDetails'] is Map) {
           if (family['basicDetails']['hasAntiSocialActivities'] == true) hasAntiSocial = true;
           final members = family['basicDetails']['members'];
           if (members is List) {
             for (var m in members) {
               if (m is Map && m['hasAntiSocialActivities'] == true) hasAntiSocial = true;
             }
           }
        }
        if (!hasAntiSocial) return false;
      }
      else if (selectedFilter == 'නිවාස නොමැති පවුල්') {
        Map<dynamic, dynamic> hs = {};
        if (family.containsKey('housingDetails') && family['housingDetails'] is Map) {
          hs = family['housingDetails'] as Map;
        }
        // 🔥 ෆිල්ටර් එකෙත් නිවැරදිම ලොජික් එක
        if (!_isNo(hs['hasHouse'])) return false; 
      }

      return true;
    }).toList();

    notifyListeners();
  }
}