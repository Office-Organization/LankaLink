import 'package:uuid/uuid.dart';

class FamilyMember {
  final String id;
  final String name;
  final DateTime birthday;
  final String gender;
  final String nic;

  FamilyMember({
    String? id,
    required this.name,
    required this.birthday,
    required this.gender,
    this.nic = '',
  }) : id = id ?? const Uuid().v4();

  int get age {
    final now = DateTime.now();
    int calculatedAge = now.year - birthday.year;
    if (now.month < birthday.month || (now.month == birthday.month && now.day < birthday.day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }

  bool get isAdult => age >= 18;

  FamilyMember copyWith({String? name, DateTime? birthday, String? gender, String? nic}) {
    return FamilyMember(
      id: id,
      name: name ?? this.name,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      nic: nic ?? this.nic,
    );
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'] as String?,
      name: map['fullName'] as String? ?? '',
      birthday: map['dob'] != null ? DateTime.parse(map['dob']) : DateTime.now(),
      gender: map['gender'] as String? ?? '',
      nic: map['nic'] as String? ?? '',
    );
  }
}

class FamilyInfo {
  final List<FamilyMember> members;
  final bool hasAswasuma;
  final int specialNeedsCount;
  final double specialNeedsAmount;
  final String specialNeedDescription; // 🔥 අලුතින් එක් කළ කොටස

  const FamilyInfo({
    this.members = const [],
    this.hasAswasuma = false,
    this.specialNeedsCount = 0,
    this.specialNeedsAmount = 0.0,
    this.specialNeedDescription = '',
  });

  FamilyInfo copyWith({
    List<FamilyMember>? members, 
    bool? hasAswasuma,
    int? specialNeedsCount,
    double? specialNeedsAmount,
    String? specialNeedDescription,
  }) {
    return FamilyInfo(
      members: members ?? this.members,
      hasAswasuma: hasAswasuma ?? this.hasAswasuma,
      specialNeedsCount: specialNeedsCount ?? this.specialNeedsCount,
      specialNeedsAmount: specialNeedsAmount ?? this.specialNeedsAmount,
      specialNeedDescription: specialNeedDescription ?? this.specialNeedDescription,
    );
  }
}

class Survey {
  final String houseNumber;
  final FamilyInfo family;

  const Survey({
    this.houseNumber = '',
    this.family = const FamilyInfo(),
  });

  Survey copyWith({String? houseNumber, FamilyInfo? family}) => Survey(
    houseNumber: houseNumber ?? this.houseNumber,
    family: family ?? this.family,
  );

  factory Survey.fromMap(Map<String, dynamic> map) {
    final membersList = (map['members'] as List<dynamic>?) ?? [];
    final members = membersList.map((m) => FamilyMember.fromMap(m as Map<String, dynamic>)).toList();

    return Survey(
      houseNumber: map['houseNumber'] as String? ?? '',
      family: FamilyInfo(
        members: members,
        hasAswasuma: map['hasAswasuma'] as bool? ?? false,
        specialNeedsCount: map['specialNeedsCount'] as int? ?? 0,
        specialNeedsAmount: (map['specialNeedsAmount'] ?? 0.0).toDouble(),
        specialNeedDescription: map['specialNeedDescription'] as String? ?? '', // 🔥 අලුතින් එක් කළ කොටස
      ),
    );
  }
}