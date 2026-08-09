import '../../core/app_constants.dart';

enum UserStatus { active, inactive, pending }

extension UserStatusExt on UserStatus {
  static UserStatus from(String? raw) {
    switch (raw) {
      case 'active':
        return UserStatus.active;
      case 'inactive':
        return UserStatus.inactive;
      default:
        return UserStatus.pending;
    }
  }

  String get dbValue => name;
}

class AppUser {
  final String uid;
  final String fullName;
  final String nic;
  final String email;
  final String mobilePhone;
  final String? district;
  final String? gnDivision;
  final UserStatus status;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.nic,
    required this.email,
    required this.mobilePhone,
    this.district,
    this.gnDivision,
    required this.status,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      fullName: map[Fields.fullName] as String? ?? '',
      nic: map[Fields.nic] as String? ?? '',
      email: map[Fields.email] as String? ?? '',
      mobilePhone: map['mobilePhone'] as String? ?? '',
      district: map['district'] as String?,
      gnDivision: map['gnDivision'] as String?,
      status: UserStatusExt.from(map[Fields.status] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      Fields.fullName: fullName,
      Fields.nic: nic,
      Fields.email: email,
      'mobilePhone': mobilePhone,
      'district': district,
      'gnDivision': gnDivision,
      Fields.status: status.dbValue,
    };
  }

  bool get canSignIn => status == UserStatus.active;
}