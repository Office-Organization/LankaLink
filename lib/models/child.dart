class Child {
  final String nic;
  final String name;
  final String dob;
  final String gender;
  final String school;
  final bool attendsSchool;
  final bool specialNeeds;
  final String assistance;

  const Child({
    required this.nic,
    required this.name,
    required this.dob,
    required this.gender,
    required this.school,
    required this.attendsSchool,
    required this.specialNeeds,
    this.assistance = 'None',
  });

  factory Child.fromMap(Map<String, dynamic> map) {
    return Child(
      nic: map['nic'] as String? ?? '',
      name: map['name'] as String? ?? '',
      dob: map['dob'] as String? ?? '',
      gender: map['gender'] as String? ?? '',
      school: map['school'] as String? ?? '',
      attendsSchool: map['attendsSchool'] as bool? ?? false,
      specialNeeds: map['specialNeeds'] as bool? ?? false,
      assistance: map['assistance'] as String? ?? 'None',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nic': nic,
      'name': name,
      'dob': dob,
      'gender': gender,
      'school': school,
      'attendsSchool': attendsSchool,
      'specialNeeds': specialNeeds,
      'assistance': assistance,
    };
  }
}