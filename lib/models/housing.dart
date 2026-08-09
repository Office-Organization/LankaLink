class HousingInfo {
  final bool houseOwnership;
  final String houseName;
  final bool electricity;
  final bool water;
  final String houseType;
  final bool housingFacilities;
  final String mobileNetwork;

  const HousingInfo({
    this.houseOwnership = true,
    this.houseName = '',
    this.electricity = true,
    this.water = true,
    this.houseType = '',
    this.housingFacilities = true,
    this.mobileNetwork = '4G',
  });

  factory HousingInfo.fromMap(Map<String, dynamic> map) {
    return HousingInfo(
      houseOwnership: map['houseOwnership'] as bool? ?? true,
      houseName: map['houseName'] as String? ?? '',
      electricity: map['electricity'] as bool? ?? true,
      water: map['water'] as bool? ?? true,
      houseType: map['houseType'] as String? ?? '',
      housingFacilities: map['housingFacilities'] as bool? ?? true,
      mobileNetwork: map['mobileNetwork'] as String? ?? '4G',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'houseOwnership': houseOwnership,
      'houseName': houseName,
      'electricity': electricity,
      'water': water,
      'houseType': houseType,
      'housingFacilities': housingFacilities,
      'mobileNetwork': mobileNetwork,
    };
  }

  HousingInfo copyWith({
    bool? houseOwnership,
    String? houseName,
    bool? electricity,
    bool? water,
    String? houseType,
    bool? housingFacilities,
    String? mobileNetwork,
  }) {
    return HousingInfo(
      houseOwnership: houseOwnership ?? this.houseOwnership,
      houseName: houseName ?? this.houseName,
      electricity: electricity ?? this.electricity,
      water: water ?? this.water,
      houseType: houseType ?? this.houseType,
      housingFacilities: housingFacilities ?? this.housingFacilities,
      mobileNetwork: mobileNetwork ?? this.mobileNetwork,
    );
  }
}