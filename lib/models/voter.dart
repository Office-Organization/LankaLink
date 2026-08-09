class Voter {
  final String houseNumber;
  final String name;
  final String nic;
  final String? gender;
  final int serialNumber;

  const Voter({
    required this.houseNumber,
    required this.name,
    required this.nic,
    this.gender,
    required this.serialNumber,
  });

  factory Voter.fromMap(Map<String, dynamic> map) {
    return Voter(
      houseNumber: map['House_Number'] as String? ?? '',
      name: map['Name'] as String? ?? '',
      nic: map['NIC'] as String? ?? '',
      gender: map['Gender'] as String?,
      serialNumber: int.tryParse(map['Serial_Number']?.toString() ?? '0') ?? 0,
    );
  }
}