import 'child.dart';
import 'housing.dart';
import 'income.dart';
import 'health.dart';
import 'voter.dart';

class Survey {
  final String id; // document ID = houseNumber + '_' + householderNic
  final String houseNumber;
  final String householderNic;
  final String householderName;
  final String householderGender;
  final List<String> familyMembersNames; // from voters
  final bool samurdhiStatus;
  final List<Child> children;
  final HousingInfo housing;
  final IncomeInfo income;
  final HealthInfo health;
  final String surveyStatus; // e.g. 'step1_completed', 'step2_completed', etc.

  const Survey({
    required this.id,
    required this.houseNumber,
    required this.householderNic,
    required this.householderName,
    required this.householderGender,
    this.familyMembersNames = const [],
    this.samurdhiStatus = false,
    this.children = const [],
    this.housing = const HousingInfo(),
    this.income = const IncomeInfo(),
    this.health = const HealthInfo(),
    this.surveyStatus = 'draft',
  });

  factory Survey.blank(String houseNumber, Voter head, List<Voter> allVoters) {
    return Survey(
      id: '${houseNumber}_${head.nic}',
      houseNumber: houseNumber,
      householderNic: head.nic,
      householderName: head.name,
      householderGender: head.gender ?? 'Male',
      familyMembersNames: allVoters.map((v) => v.name).toList(),
    );
  }

  factory Survey.fromMap(String id, Map<String, dynamic> map) {
    final householder = map['householder'] as Map<String, dynamic>? ?? {};
    final aswesuma = map['aswesuma'] as Map<String, dynamic>? ?? {};
    final childrenList = (map['children'] as List<dynamic>? ?? [])
        .map((c) => Child.fromMap(c as Map<String, dynamic>))
        .toList();
    final housingMap = map['housingAndLiving'] as Map<String, dynamic>? ?? {};
    final incomeMap = map['incomeSources'] as Map<String, dynamic>? ?? {};
    final healthMap = map['healthAndNutrition'] as Map<String, dynamic>? ?? {};
    final familyMembers = (map['familyMembersNames'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return Survey(
      id: id,
      houseNumber: map['houseNumber'] as String? ?? '',
      householderNic: householder['nic'] as String? ?? '',
      householderName: householder['fullName'] as String? ?? '',
      householderGender: householder['gender'] as String? ?? 'Male',
      familyMembersNames: familyMembers,
      samurdhiStatus: map['samurdhiStatus'] as bool? ?? false,
      children: childrenList,
      housing: HousingInfo.fromMap(housingMap),
      income: IncomeInfo.fromMap(incomeMap),
      health: HealthInfo.fromMap(healthMap),
      surveyStatus: map['surveyStatus'] as String? ?? 'draft',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'houseNumber': houseNumber,
      'householder': {
        'nic': householderNic,
        'fullName': householderName,
        'gender': householderGender,
      },
      'familyMembersNames': familyMembersNames,
      'samurdhiStatus': samurdhiStatus,
      'children': children.map((c) => c.toMap()).toList(),
      'housingAndLiving': housing.toMap(),
      'incomeSources': income.toMap(),
      'healthAndNutrition': health.toMap(),
      'surveyStatus': surveyStatus,
    };
  }

  Survey copyWith({
    String? id,
    String? houseNumber,
    String? householderNic,
    String? householderName,
    String? householderGender,
    List<String>? familyMembersNames,
    bool? samurdhiStatus,
    List<Child>? children,
    HousingInfo? housing,
    IncomeInfo? income,
    HealthInfo? health,
    String? surveyStatus,
  }) {
    return Survey(
      id: id ?? this.id,
      houseNumber: houseNumber ?? this.houseNumber,
      householderNic: householderNic ?? this.householderNic,
      householderName: householderName ?? this.householderName,
      householderGender: householderGender ?? this.householderGender,
      familyMembersNames: familyMembersNames ?? this.familyMembersNames,
      samurdhiStatus: samurdhiStatus ?? this.samurdhiStatus,
      children: children ?? this.children,
      housing: housing ?? this.housing,
      income: income ?? this.income,
      health: health ?? this.health,
      surveyStatus: surveyStatus ?? this.surveyStatus,
    );
  }
}