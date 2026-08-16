import 'package:uuid/uuid.dart';

class OtherMemberInfo {
  OtherMemberInfo({
    String? id,
    this.name,
    this.relationship,
    this.gender,
    this.dateOfBirth,
    this.nic,
    this.phone,
    this.occupation,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String? name;
  final String? relationship;
  final String? gender;
  final String? dateOfBirth;
  final String? nic;
  final String? phone;
  final String? occupation;

  OtherMemberInfo copyWith({
    String? id,
    String? name,
    String? relationship,
    String? gender,
    String? dateOfBirth,
    String? nic,
    String? phone,
    String? occupation,
  }) {
    return OtherMemberInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nic: nic ?? this.nic,
      phone: phone ?? this.phone,
      occupation: occupation ?? this.occupation,
    );
  }
}

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
      chronicIllnessAllowance: (map['chronicIllnessAllowance'] ?? 0.0)
          .toDouble(),
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
  final List<OtherMemberInfo> otherMembers;
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
    this.otherMembers = const [],
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
    List<OtherMemberInfo>? otherMembers,
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
      otherMembers: otherMembers ?? this.otherMembers,
      hasAntiSocialActivities:
          hasAntiSocialActivities ?? this.hasAntiSocialActivities,
      antiSocialDescription:
          antiSocialDescription ?? this.antiSocialDescription,
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
    'otherMembers': otherMembers
        .map(
          (m) => {
            'id': m.id,
            'name': m.name,
            'relationship': m.relationship,
            'gender': m.gender,
            'dateOfBirth': m.dateOfBirth,
            'nic': m.nic,
            'phone': m.phone,
            'occupation': m.occupation,
          },
        )
        .toList(),
    'hasAntiSocialActivities': hasAntiSocialActivities,
    'antiSocialDescription': antiSocialDescription,
  };

  // 🔥 Firestore හි දත්ත නැවත කියවීම සඳහා
  factory BasicDetails.fromMap(Map<String, dynamic> map) {
    final childList = (map['children'] as List<dynamic>?) ?? [];
    final otherMembersList = (map['otherMembers'] as List<dynamic>?) ?? [];
    return BasicDetails(
      houseNumber: map['houseNumber'] as String? ?? '',
      headGender: map['headGender'] as String? ?? 'පුරුෂ',
      headName: map['headName'] as String? ?? '',
      nic: map['nic'] as String? ?? '',
      dob: map['dob'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      nationality: map['nationality'] as String? ?? 'සිංහල',
      children: childList
          .map((c) => ChildInfo.fromMap(c as Map<String, dynamic>))
          .toList(),
      otherMembers: otherMembersList.map((m) {
        final memberMap = m as Map<String, dynamic>;
        final savedId = memberMap['id'] as String?;
        return OtherMemberInfo(
          id: savedId == null || savedId.isEmpty ? null : savedId,
          name: memberMap['name'] as String?,
          relationship: memberMap['relationship'] as String?,
          gender: memberMap['gender'] as String?,
          dateOfBirth: memberMap['dateOfBirth'] as String?,
          nic: memberMap['nic'] as String?,
          phone: memberMap['phone'] as String?,
          occupation: memberMap['occupation'] as String?,
        );
      }).toList(),
      hasAntiSocialActivities: map['hasAntiSocialActivities'] as bool? ?? false,
      antiSocialDescription: map['antiSocialDescription'] as String? ?? '',
    );
  }
}
