class HousingDetails {
  final String houseNumber;
  final bool hasHouse;
  final String nature; 
  final String sanitation; 
  final String electricity; 
  final String water; 
  final bool hasFixedPhone; 
  final bool hasMobilePhone; 
  final String signal; 

  HousingDetails({
    this.houseNumber = '',
    this.hasHouse = true,
    this.nature = 'ස්ථිර තනි',
    this.sanitation = 'ජල මුද්‍රිත',
    this.electricity = 'ඇත',
    this.water = 'ප්‍රජා ජල ව්‍යාපෘත',
    this.hasFixedPhone = true,
    this.hasMobilePhone = false,
    this.signal = '4G',
  });

  HousingDetails copyWith({
    String? houseNumber,
    bool? hasHouse,
    String? nature,
    String? sanitation,
    String? electricity,
    String? water,
    bool? hasFixedPhone,
    bool? hasMobilePhone,
    String? signal,
  }) {
    return HousingDetails(
      houseNumber: houseNumber ?? this.houseNumber,
      hasHouse: hasHouse ?? this.hasHouse,
      nature: nature ?? this.nature,
      sanitation: sanitation ?? this.sanitation,
      electricity: electricity ?? this.electricity,
      water: water ?? this.water,
      hasFixedPhone: hasFixedPhone ?? this.hasFixedPhone,
      hasMobilePhone: hasMobilePhone ?? this.hasMobilePhone,
      signal: signal ?? this.signal,
    );
  }

  Map<String, dynamic> toMap() => {
    'houseNumber': houseNumber,
    'hasHouse': hasHouse,
    'nature': nature,
    'sanitation': sanitation,
    'electricity': electricity,
    'water': water,
    'hasFixedPhone': hasFixedPhone,
    'hasMobilePhone': hasMobilePhone,
    'signal': signal,
  };

  factory HousingDetails.fromMap(Map<String, dynamic> map) {
    return HousingDetails(
      houseNumber: map['houseNumber']?.toString() ?? '',
      hasHouse: map['hasHouse'] as bool? ?? true,
      nature: map['nature']?.toString() ?? 'ස්ථිර තනි',
      sanitation: map['sanitation']?.toString() ?? 'ජල මුද්‍රිත',
      electricity: map['electricity']?.toString() ?? 'ඇත',
      water: map['water']?.toString() ?? 'ප්‍රජා ජල ව්‍යාපෘත',
      hasFixedPhone: map['hasFixedPhone'] as bool? ?? true,
      hasMobilePhone: map['hasMobilePhone'] as bool? ?? false,
      signal: map['signal']?.toString() ?? '4G',
    );
  }
}