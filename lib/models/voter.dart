
class AppVoter {
  final String id;
  final String name;
  final String nic;
  final String houseNumber;
  final String gender;

  const AppVoter({
    required this.id,
    required this.name,
    required this.nic,
    required this.houseNumber,
    required this.gender,
  });

  factory AppVoter.fromMap(String id, Map<String, dynamic> map) => AppVoter(
    id: id,
    name: map['Name'] as String? ?? '',
    nic: map['NIC'] as String? ?? '',
    houseNumber: map['House_Number'] as String? ?? '',
    gender: map['Gender'] as String? ?? '',
  );
}