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
  
  // වෙනම තිබූ children සහ otherMembers වෙනුවට දැන් ඇත්තේ එකම members ලිස්ට් එකකි.
  final List<FamilyMember> members;

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
    this.members = const [],
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
    List<FamilyMember>? members,
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
      members: members ?? this.members,
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
      'members': members.map((m) => m.toMap()).toList(),
    };
  }

  factory BasicDetails.fromMap(Map<String, dynamic> map) {
    var rawMembers = map['members'] as List<dynamic>? ?? [];
    List<FamilyMember> parsedMembers = rawMembers
        .map((item) => FamilyMember.fromMap(Map<String, dynamic>.from(item as Map)))
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
      members: parsedMembers,
    );
  }
}

// ළමයින් සහ වැඩිහිටියන් සඳහා වන තනි පොදු මොඩල් එක
class FamilyMember {
  // ඔබ ඉල්ලූ පරිදි JSON ආකෘතියට ගැලපෙන Fields
  final String id;
  final String fullName;
  final String nic;
  final String dob;
  final int age;
  final String gender;
  final bool isAdult;
  
  // අනෙකුත් සමීක්ෂණ දත්ත Fields (පරණ ෆෝම් වල තිබූ)
  final String relationship;
  final bool attendsSchool;
  final bool hasSpecialNeeds;
  final bool hasAudioNeed;
  final bool hasVisualNeed;
  final bool hasOtherNeed;
  final bool receivesGovtAssistance;
  final double disabilityAllowance;
  final double chronicIllnessAllowance;
  final bool hasAntiSocialActivities;
  final String antiSocialDescription;

  FamilyMember({
    required this.id,
    required this.fullName,
    required this.nic,
    required this.dob,
    required this.age,
    required this.gender,
    required this.isAdult,
    this.relationship = 'වෙනත්',
    this.attendsSchool = false,
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

  FamilyMember copyWith({
    String? id,
    String? fullName,
    String? nic,
    String? dob,
    int? age,
    String? gender,
    bool? isAdult,
    String? relationship,
    bool? attendsSchool,
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
    return FamilyMember(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      nic: nic ?? this.nic,
      dob: dob ?? this.dob,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      isAdult: isAdult ?? this.isAdult,
      relationship: relationship ?? this.relationship,
      attendsSchool: attendsSchool ?? this.attendsSchool,
      hasSpecialNeeds: hasSpecialNeeds ?? this.hasSpecialNeeds,
      hasAudioNeed: hasAudioNeed ?? this.hasAudioNeed,
      hasVisualNeed: hasVisualNeed ?? this.hasVisualNeed,
      hasOtherNeed: hasOtherNeed ?? this.hasOtherNeed,
      receivesGovtAssistance: receivesGovtAssistance ?? this.receivesGovtAssistance,
      disabilityAllowance: disabilityAllowance ?? this.disabilityAllowance,
      chronicIllnessAllowance: chronicIllnessAllowance ?? this.chronicIllnessAllowance,
      hasAntiSocialActivities: hasAntiSocialActivities ?? this.hasAntiSocialActivities,
      antiSocialDescription: antiSocialDescription ?? this.antiSocialDescription,
    );
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      nic: map['nic']?.toString() ?? '',
      dob: map['dob']?.toString() ?? '',
      age: int.tryParse(map['age']?.toString() ?? '0') ?? 0,
      gender: map['gender']?.toString() ?? 'පුරුෂ',
      isAdult: map['isAdult'] as bool? ?? true,
      relationship: map['relationship']?.toString() ?? 'වෙනත්',
      attendsSchool: map['attendsSchool'] as bool? ?? false,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'nic': nic,
      'dob': dob,
      'age': age,
      'gender': gender,
      'isAdult': isAdult,
      'relationship': relationship,
      'attendsSchool': attendsSchool,
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
}