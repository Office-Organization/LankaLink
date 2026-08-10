class FamilyInfo {
  final String headName;
  final int memberCount;

  const FamilyInfo({this.headName = '', this.memberCount = 0});
}

class Survey {
  final String? id;
  final FamilyInfo family;

  const Survey({this.id, this.family = const FamilyInfo()});

  Survey copyWith({FamilyInfo? family}) =>
      Survey(id: id, family: family ?? this.family);

  // Firebase වෙත යැවීම සඳහා දත්ත Map එකක් බවට හැරවීම
  Map<String, dynamic> toMap() => {
    'headName': family.headName,
    'memberCount': family.memberCount,
    'createdAt': DateTime.now(),
  };
}
