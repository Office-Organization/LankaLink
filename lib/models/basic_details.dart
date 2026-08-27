class BasicDetails {
  final String houseNumber;
  final String headName;
  final String headGender;
  final String nic;
  final String dob;
  final String phone;
  final String email;
  final String nationality;
  final bool hasAntiSocialActivities;
  final String antiSocialDescription;
  final List<ChildInfo> children;
  final List<OtherMemberInfo> otherMembers;

  BasicDetails({
    this.houseNumber = '',
    this.headName = '',
    this.headGender = 'පිරිමි',
    this.nic = '',
    this.dob = '',
    this.phone = '',
    this.email = '',
    this.nationality = 'සිංහල',
    this.hasAntiSocialActivities = false,
    this.antiSocialDescription = '',
    this.children = const [],
    this.otherMembers = const [],
  });

  BasicDetails copyWith({
    String? houseNumber,
    String? headName,
    String? headGender,
    String? nic,
    String? dob,
    String? phone,
    String? email,
    String? nationality,
    bool? hasAntiSocialActivities,
    String? antiSocialDescription,
    List<ChildInfo>? children,
    List<OtherMemberInfo>? otherMembers,
  }) {
    return BasicDetails(
      houseNumber: houseNumber ?? this.houseNumber,
      headName: headName ?? this.headName,
      headGender: headGender ?? this.headGender,
      nic: nic ?? this.nic,
      dob: dob ?? this.dob,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      nationality: nationality ?? this.nationality,
      hasAntiSocialActivities:
          hasAntiSocialActivities ?? this.hasAntiSocialActivities,
      antiSocialDescription:
          antiSocialDescription ?? this.antiSocialDescription,
      children: children ?? this.children,
      otherMembers: otherMembers ?? this.otherMembers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'houseNumber': houseNumber,
      'headName': headName,
      'headGender': headGender,
      'nic': nic,
      'dob': dob,
      'phone': phone,
      'email': email,
      'nationality': nationality,
      'hasAntiSocialActivities': hasAntiSocialActivities,
      'antiSocialDescription': antiSocialDescription,
      'children': children.map((c) => c.toMap()).toList(),
      'otherMembers': otherMembers.map((m) => m.toMap()).toList(),
    };
  }

  factory BasicDetails.fromMap(Map<String, dynamic> map) {
    var rawChildren = map['children'] as List<dynamic>? ?? [];
    List<ChildInfo> parsedChildren = rawChildren
        .map((item) => ChildInfo.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();

    var rawOtherMembers = map['otherMembers'] as List<dynamic>? ?? [];
    List<OtherMemberInfo> parsedOtherMembers = rawOtherMembers
        .map((item) => OtherMemberInfo.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();

    return BasicDetails(
      houseNumber: map['houseNumber']?.toString() ?? '',
      headName: map['headName']?.toString() ?? '',
      headGender: map['headGender']?.toString() ?? 'පිරිමි',
      nic: map['nic']?.toString() ?? '',
      dob: map['dob']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      nationality: map['nationality']?.toString() ?? 'සිංහල',
      hasAntiSocialActivities: map['hasAntiSocialActivities'] as bool? ?? false,
      antiSocialDescription: map['antiSocialDescription']?.toString() ?? '',
      children: parsedChildren,
      otherMembers: parsedOtherMembers,
    );
  }
}

class OtherMemberInfo {
  final String id;
  final String? name;
  final String? nic;
  final String? dateOfBirth;
  final String? gender;
  final String? relationship;
  final bool hasAntiSocialActivities;
  final String antiSocialDescription;

  OtherMemberInfo({
    required this.id,
    this.name,
    this.nic,
    this.dateOfBirth,
    this.gender,
    this.relationship,
    this.hasAntiSocialActivities = false,
    this.antiSocialDescription = '',
  });

  OtherMemberInfo copyWith({
    String? id,
    String? name,
    String? nic,
    String? dateOfBirth,
    String? gender,
    String? relationship,
    bool? hasAntiSocialActivities,
    String? antiSocialDescription,
  }) {
    return OtherMemberInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      nic: nic ?? this.nic,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      relationship: relationship ?? this.relationship,
      hasAntiSocialActivities:
          hasAntiSocialActivities ?? this.hasAntiSocialActivities,
      antiSocialDescription:
          antiSocialDescription ?? this.antiSocialDescription,
    );
  }

  factory OtherMemberInfo.fromMap(Map<String, dynamic> map) {
    return OtherMemberInfo(
      id: map['id']?.toString() ?? '',
      name: (map['fullName'] ?? map['name'])?.toString() ?? '',
      nic: map['nic']?.toString() ?? '',
      dateOfBirth: (map['dob'] ?? map['dateOfBirth'])?.toString() ?? '',
      gender: map['gender']?.toString() ?? 'පුරුෂ',
      relationship: map['relationship']?.toString() ?? 'වෙනත්',
      hasAntiSocialActivities: map['hasAntiSocialActivities'] as bool? ?? false,
      antiSocialDescription: map['antiSocialDescription']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': name,
      'nic': nic,
      'dob': dateOfBirth,
      'gender': gender,
      'relationship': relationship,
      'hasAntiSocialActivities': hasAntiSocialActivities,
      'antiSocialDescription': antiSocialDescription,
    };
  }
}

class ChildInfo {
  final String? id;
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
  final bool hasAntiSocialActivities;
  final String antiSocialDescription;

  ChildInfo({
    this.id,
    required this.name,
    this.attendsSchool = false,
    required this.dob,
    required this.gender,
    this.hasSpecialNeeds = false,
    this.hasAudioNeed = false,
    this.hasVisualNeed = false,
    this.hasOtherNeed = false,
    this.receivesGovtAssistance = false,
    this.disabilityAllowance = 0.0,
    this.chronicIllnessAllowance = 0.0,
    this.hasAntiSocialActivities = false,
    this.antiSocialDescription = '',
  });

  ChildInfo copyWith({
    String? id,
    String? name,
    bool? attendsSchool,
    String? dob,
    String? gender,
    bool? hasSpecialNeeds,
    bool? hasAudioNeed,
    bool? hasVisualNeed,
    bool? hasOtherNeed,
    bool? receivesGovtAssistance,
    double? disabilityAllowance,
    double? chronicIllnessAllowance,
    bool? hasAntiSocialActivities,
    String? antiSocialDescription,
  }) {
    return ChildInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      attendsSchool: attendsSchool ?? this.attendsSchool,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      hasSpecialNeeds: hasSpecialNeeds ?? this.hasSpecialNeeds,
      hasAudioNeed: hasAudioNeed ?? this.hasAudioNeed,
      hasVisualNeed: hasVisualNeed ?? this.hasVisualNeed,
      hasOtherNeed: hasOtherNeed ?? this.hasOtherNeed,
      receivesGovtAssistance:
          receivesGovtAssistance ?? this.receivesGovtAssistance,
      disabilityAllowance: disabilityAllowance ?? this.disabilityAllowance,
      chronicIllnessAllowance:
          chronicIllnessAllowance ?? this.chronicIllnessAllowance,
      hasAntiSocialActivities:
          hasAntiSocialActivities ?? this.hasAntiSocialActivities,
      antiSocialDescription:
          antiSocialDescription ?? this.antiSocialDescription,
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
      'hasAntiSocialActivities': hasAntiSocialActivities,
      'antiSocialDescription': antiSocialDescription,
    };
  }

  factory ChildInfo.fromMap(Map<String, dynamic> map) {
    return ChildInfo(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      attendsSchool: map['attendsSchool'] as bool? ?? false,
      dob: map['dob']?.toString() ?? '',
      gender: map['gender']?.toString() ?? 'පිරිමි',
      hasSpecialNeeds: map['hasSpecialNeeds'] as bool? ?? false,
      hasAudioNeed: map['hasAudioNeed'] as bool? ?? false,
      hasVisualNeed: map['hasVisualNeed'] as bool? ?? false,
      hasOtherNeed: map['hasOtherNeed'] as bool? ?? false,
      receivesGovtAssistance: map['receivesGovtAssistance'] as bool? ?? false,
      disabilityAllowance: (map['disabilityAllowance'] as num?)?.toDouble() ?? 0.0,
      chronicIllnessAllowance: (map['chronicIllnessAllowance'] as num?)?.toDouble() ?? 0.0,
      hasAntiSocialActivities: map['hasAntiSocialActivities'] as bool? ?? false,
      antiSocialDescription: map['antiSocialDescription']?.toString() ?? '',
    );
  }
}