import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

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
  final String specialNeedDescription; 
  
  // 🔴 ADDED LOCATION FIELDS 
  final String localAuthority;
  final String gnDivision;

  const FamilyInfo({
    this.members = const [],
    this.hasAswasuma = false,
    this.specialNeedsCount = 0,
    this.specialNeedsAmount = 0.0,
    this.specialNeedDescription = '',
    this.localAuthority = '', // 🔴
    this.gnDivision = '',     // 🔴
  });

  FamilyInfo copyWith({
    List<FamilyMember>? members, 
    bool? hasAswasuma,
    int? specialNeedsCount,
    double? specialNeedsAmount,
    String? specialNeedDescription,
    String? localAuthority, // 🔴
    String? gnDivision,     // 🔴
  }) {
    return FamilyInfo(
      members: members ?? this.members,
      hasAswasuma: hasAswasuma ?? this.hasAswasuma,
      specialNeedsCount: specialNeedsCount ?? this.specialNeedsCount,
      specialNeedsAmount: specialNeedsAmount ?? this.specialNeedsAmount,
      specialNeedDescription: specialNeedDescription ?? this.specialNeedDescription,
      localAuthority: localAuthority ?? this.localAuthority, // 🔴
      gnDivision: gnDivision ?? this.gnDivision,             // 🔴
    );
  }
}

class Survey {
  final String houseNumber;
  final FamilyInfo family;
  
  final String? updatedBy;
  final DateTime? updatedAt;

  const Survey({
    this.houseNumber = '',
    this.family = const FamilyInfo(),
    this.updatedBy, 
    this.updatedAt, 
  });

  Survey copyWith({
    String? houseNumber, 
    FamilyInfo? family,
    String? updatedBy,
    DateTime? updatedAt,
  }) => Survey(
    houseNumber: houseNumber ?? this.houseNumber,
    family: family ?? this.family,
    updatedBy: updatedBy ?? this.updatedBy,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory Survey.fromMap(Map<String, dynamic> map) {
    final membersList = (map['members'] as List<dynamic>?) ?? [];
    final members = membersList.map((m) => FamilyMember.fromMap(m as Map<String, dynamic>)).toList();

    DateTime? parsedDate;
    if (map['timestamp'] != null) {
      final t = map['timestamp'];
      if (t is Timestamp) { 
        parsedDate = t.toDate();
      } else if (t is DateTime) {
        parsedDate = t;
      } else {
        parsedDate = DateTime.tryParse(t.toString());
      }
    }

    return Survey(
      houseNumber: map['houseNumber'] as String? ?? '',
      family: FamilyInfo(
        members: members,
        hasAswasuma: map['hasAswasuma'] as bool? ?? false,
        specialNeedsCount: map['specialNeedsCount'] as int? ?? 0,
        specialNeedsAmount: (map['specialNeedsAmount'] ?? 0.0).toDouble(),
        specialNeedDescription: map['specialNeedDescription'] as String? ?? '', 
        localAuthority: map['localAuthority'] as String? ?? '', // 🔴 READ FROM MAP
        gnDivision: map['gnDivision'] as String? ?? '',         // 🔴 READ FROM MAP
      ),
      updatedBy: map['updatedBy']?.toString(), 
      updatedAt: parsedDate,                   
    );
  }
}