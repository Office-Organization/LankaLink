import 'package:uuid/uuid.dart';

class ChildInfo {
  final String id;
  final String name;
  final bool attendsSchool;
  final String dob;
  final String gender;
  final bool hasSpecialNeeds;
  final bool hasAudioNeed;
  final bool hasVisualNeed;
  final bool hasOtherNeed;
  final bool receivesGovtAssistance;
  final double disabilityAllowance;
  final double chronicIllnessAllowance;

  ChildInfo({
    String? id,
    required this.name,
    this.attendsSchool = true,
    required this.dob,
    required this.gender,
    this.hasSpecialNeeds = false,
    this.hasAudioNeed = false,
    this.hasVisualNeed = false,
    this.hasOtherNeed = false,
    this.receivesGovtAssistance = false,
    this.disabilityAllowance = 0.0,
    this.chronicIllnessAllowance = 0.0,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'attendsSchool': attendsSchool,
    'dob': dob,
    'gender': gender,
    'hasSpecialNeeds': hasSpecialNeeds,
    'hasAudioNeed': hasAudioNeed,
    'hasVisualNeed': hasVisualNeed,
    'hasOtherNeed': hasOtherNeed,
    'receivesGovtAssistance': receivesGovtAssistance,
    'disabilityAllowance': disabilityAllowance,
    'chronicIllnessAllowance': chronicIllnessAllowance,
  };

  // 🔥 Firestore හි දත්ත නැවත කියවීම සඳහා
  factory ChildInfo.fromMap(Map<String, dynamic> map) {
    return ChildInfo(
      id: map['id'] as String?,
      name: map['name'] as String? ?? '',
      attendsSchool: map['attendsSchool'] as bool? ?? true,
      dob: map['dob'] as String? ?? '',
      gender: map['gender'] as String? ?? 'පුරුෂ',
      hasSpecialNeeds: map['hasSpecialNeeds'] as bool? ?? false,
      hasAudioNeed: map['hasAudioNeed'] as bool? ?? false,
      hasVisualNeed: map['hasVisualNeed'] as bool? ?? false,
      hasOtherNeed: map['hasOtherNeed'] as bool? ?? false,
      receivesGovtAssistance: map['receivesGovtAssistance'] as bool? ?? false,
      disabilityAllowance: (map['disabilityAllowance'] ?? 0.0).toDouble(),
      chronicIllnessAllowance: (map['chronicIllnessAllowance'] ?? 0.0).toDouble(),
    );
  }
}

class BasicDetails {
  final String houseNumber;
  final String headGender;
  final String headName;
  final String nic;
  final String dob;
  final String phone;
  final String email;
  final String nationality;
  final List<ChildInfo> children;
  final bool hasAntiSocialActivities;
  final String antiSocialDescription;

  BasicDetails({
    this.houseNumber = '',
    this.headGender = 'පුරුෂ',
    this.headName = '',
    this.nic = '',
    this.dob = '',
    this.phone = '',
    this.email = '',
    this.nationality = 'සිංහල',
    this.children = const [],
    this.hasAntiSocialActivities = false,
    this.antiSocialDescription = '',
  });

  BasicDetails copyWith({
    String? houseNumber,
    String? headGender,
    String? headName,
    String? nic,
    String? dob,
    String? phone,
    String? email,
    String? nationality,
    List<ChildInfo>? children,
    bool? hasAntiSocialActivities,
    String? antiSocialDescription,
  }) {
    return BasicDetails(
      houseNumber: houseNumber ?? this.houseNumber,
      headGender: headGender ?? this.headGender,
      headName: headName ?? this.headName,
      nic: nic ?? this.nic,
      dob: dob ?? this.dob,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      nationality: nationality ?? this.nationality,
      children: children ?? this.children,
      hasAntiSocialActivities: hasAntiSocialActivities ?? this.hasAntiSocialActivities,
      antiSocialDescription: antiSocialDescription ?? this.antiSocialDescription,
    );
  }

  Map<String, dynamic> toMap() => {
    'houseNumber': houseNumber,
    'headGender': headGender,
    'headName': headName,
    'nic': nic,
    'dob': dob,
    'phone': phone,
    'email': email,
    'nationality': nationality,
    'children': children.map((c) => c.toMap()).toList(),
    'hasAntiSocialActivities': hasAntiSocialActivities,
    'antiSocialDescription': antiSocialDescription,
  };

  // 🔥 Firestore හි දත්ත නැවත කියවීම සඳහා
  factory BasicDetails.fromMap(Map<String, dynamic> map) {
    final childList = (map['children'] as List<dynamic>?) ?? [];
    return BasicDetails(
      houseNumber: map['houseNumber'] as String? ?? '',
      headGender: map['headGender'] as String? ?? 'පුරුෂ',
      headName: map['headName'] as String? ?? '',
      nic: map['nic'] as String? ?? '',
      dob: map['dob'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      nationality: map['nationality'] as String? ?? 'සිංහල',
      children: childList.map((c) => ChildInfo.fromMap(c as Map<String, dynamic>)).toList(),
      hasAntiSocialActivities: map['hasAntiSocialActivities'] as bool? ?? false,
      antiSocialDescription: map['antiSocialDescription'] as String? ?? '',
    );
  }
}