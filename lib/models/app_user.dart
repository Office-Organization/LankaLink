enum UserStatus {
  active,
  inactive;

  static UserStatus from(String? raw) =>
      raw == 'inactive' ? UserStatus.inactive : UserStatus.active;
}

class AppUser {
  final String uid;
  final String name;
  final String nic;
  final String email;
  final UserStatus status;

  const AppUser({
    required this.uid,
    required this.name,
    required this.nic,
    required this.email,
    required this.status,
  });

  // Map එකක් වෙනුවට Model එකක් භාවිත කිරීම මගින් අක්ෂර වින්‍යාස දෝෂ වළක්වා ගනී
  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
    uid: uid,
    name: map['name'] as String? ?? '',
    nic: map['nic'] as String? ?? '',
    email: map['email'] as String? ?? '',
    status: UserStatus.from(map['status'] as String?),
  );

  bool get canSignIn => status == UserStatus.active;
}
