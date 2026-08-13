class AssetsDetails {
  final String houseNumber;

  // නිශ්චල - ගොඩ
  final bool hasHighland;
  final String highlandExtent;
  final bool isHighlandCultivated;
  final bool hlNoWater;
  final bool hlAnimalDamage;
  final bool hlMoneyLabor;
  final bool hlOther;

  // නිශ්චල - මඩ
  final bool hasMudland;
  final String mudlandExtent;
  final bool isMudlandCultivated;
  final bool mlNoWater;
  final bool mlAnimalDamage;
  final bool mlMoneyLabor;
  final bool mlEquipment;
  final bool mlFertilizer;
  final bool mlOther;

  // චංචල - වාහන
  final bool hasBike;
  final bool hasThreeWheeler;
  final bool hasVan;
  final bool hasLorry;
  final bool hasBus;
  final bool hasTractor;
  final bool hasCar;
  final bool hasCab;
  final bool hasOtherVehicle;

  AssetsDetails({
    this.houseNumber = '',
    this.hasHighland = true,
    this.highlandExtent = '',
    this.isHighlandCultivated = true,
    this.hlNoWater = false,
    this.hlAnimalDamage = false,
    this.hlMoneyLabor = false,
    this.hlOther = false,
    this.hasMudland = false,
    this.mudlandExtent = '',
    this.isMudlandCultivated = true,
    this.mlNoWater = false,
    this.mlAnimalDamage = false,
    this.mlMoneyLabor = false,
    this.mlEquipment = false,
    this.mlFertilizer = false,
    this.mlOther = false,
    this.hasBike = false,
    this.hasThreeWheeler = false,
    this.hasVan = false,
    this.hasLorry = false,
    this.hasBus = false,
    this.hasTractor = false,
    this.hasCar = false,
    this.hasCab = false,
    this.hasOtherVehicle = false,
  });

  AssetsDetails copyWith({
    String? houseNumber,
    bool? hasHighland,
    String? highlandExtent,
    bool? isHighlandCultivated,
    bool? hlNoWater,
    bool? hlAnimalDamage,
    bool? hlMoneyLabor,
    bool? hlOther,
    bool? hasMudland,
    String? mudlandExtent,
    bool? isMudlandCultivated,
    bool? mlNoWater,
    bool? mlAnimalDamage,
    bool? mlMoneyLabor,
    bool? mlEquipment,
    bool? mlFertilizer,
    bool? mlOther,
    bool? hasBike,
    bool? hasThreeWheeler,
    bool? hasVan,
    bool? hasLorry,
    bool? hasBus,
    bool? hasTractor,
    bool? hasCar,
    bool? hasCab,
    bool? hasOtherVehicle,
  }) {
    return AssetsDetails(
      houseNumber: houseNumber ?? this.houseNumber,
      hasHighland: hasHighland ?? this.hasHighland,
      highlandExtent: highlandExtent ?? this.highlandExtent,
      isHighlandCultivated: isHighlandCultivated ?? this.isHighlandCultivated,
      hlNoWater: hlNoWater ?? this.hlNoWater,
      hlAnimalDamage: hlAnimalDamage ?? this.hlAnimalDamage,
      hlMoneyLabor: hlMoneyLabor ?? this.hlMoneyLabor,
      hlOther: hlOther ?? this.hlOther,
      hasMudland: hasMudland ?? this.hasMudland,
      mudlandExtent: mudlandExtent ?? this.mudlandExtent,
      isMudlandCultivated: isMudlandCultivated ?? this.isMudlandCultivated,
      mlNoWater: mlNoWater ?? this.mlNoWater,
      mlAnimalDamage: mlAnimalDamage ?? this.mlAnimalDamage,
      mlMoneyLabor: mlMoneyLabor ?? this.mlMoneyLabor,
      mlEquipment: mlEquipment ?? this.mlEquipment,
      mlFertilizer: mlFertilizer ?? this.mlFertilizer,
      mlOther: mlOther ?? this.mlOther,
      hasBike: hasBike ?? this.hasBike,
      hasThreeWheeler: hasThreeWheeler ?? this.hasThreeWheeler,
      hasVan: hasVan ?? this.hasVan,
      hasLorry: hasLorry ?? this.hasLorry,
      hasBus: hasBus ?? this.hasBus,
      hasTractor: hasTractor ?? this.hasTractor,
      hasCar: hasCar ?? this.hasCar,
      hasCab: hasCab ?? this.hasCab,
      hasOtherVehicle: hasOtherVehicle ?? this.hasOtherVehicle,
    );
  }

  Map<String, dynamic> toMap() => {
    'houseNumber': houseNumber,
    'hasHighland': hasHighland,
    'highlandExtent': highlandExtent,
    'isHighlandCultivated': isHighlandCultivated,
    'hlNoWater': hlNoWater,
    'hlAnimalDamage': hlAnimalDamage,
    'hlMoneyLabor': hlMoneyLabor,
    'hlOther': hlOther,
    'hasMudland': hasMudland,
    'mudlandExtent': mudlandExtent,
    'isMudlandCultivated': isMudlandCultivated,
    'mlNoWater': mlNoWater,
    'mlAnimalDamage': mlAnimalDamage,
    'mlMoneyLabor': mlMoneyLabor,
    'mlEquipment': mlEquipment,
    'mlFertilizer': mlFertilizer,
    'mlOther': mlOther,
    'hasBike': hasBike,
    'hasThreeWheeler': hasThreeWheeler,
    'hasVan': hasVan,
    'hasLorry': hasLorry,
    'hasBus': hasBus,
    'hasTractor': hasTractor,
    'hasCar': hasCar,
    'hasCab': hasCab,
    'hasOtherVehicle': hasOtherVehicle,
  };

  factory AssetsDetails.fromMap(Map<String, dynamic> map) {
    return AssetsDetails(
      houseNumber: map['houseNumber']?.toString() ?? '',
      hasHighland: map['hasHighland'] as bool? ?? true,
      highlandExtent: map['highlandExtent']?.toString() ?? '',
      isHighlandCultivated: map['isHighlandCultivated'] as bool? ?? true,
      hlNoWater: map['hlNoWater'] as bool? ?? false,
      hlAnimalDamage: map['hlAnimalDamage'] as bool? ?? false,
      hlMoneyLabor: map['hlMoneyLabor'] as bool? ?? false,
      hlOther: map['hlOther'] as bool? ?? false,
      hasMudland: map['hasMudland'] as bool? ?? false,
      mudlandExtent: map['mudlandExtent']?.toString() ?? '',
      isMudlandCultivated: map['isMudlandCultivated'] as bool? ?? true,
      mlNoWater: map['mlNoWater'] as bool? ?? false,
      mlAnimalDamage: map['mlAnimalDamage'] as bool? ?? false,
      mlMoneyLabor: map['mlMoneyLabor'] as bool? ?? false,
      mlEquipment: map['mlEquipment'] as bool? ?? false,
      mlFertilizer: map['mlFertilizer'] as bool? ?? false,
      mlOther: map['mlOther'] as bool? ?? false,
      hasBike: map['hasBike'] as bool? ?? false,
      hasThreeWheeler: map['hasThreeWheeler'] as bool? ?? false,
      hasVan: map['hasVan'] as bool? ?? false,
      hasLorry: map['hasLorry'] as bool? ?? false,
      hasBus: map['hasBus'] as bool? ?? false,
      hasTractor: map['hasTractor'] as bool? ?? false,
      hasCar: map['hasCar'] as bool? ?? false,
      hasCab: map['hasCab'] as bool? ?? false,
      hasOtherVehicle: map['hasOtherVehicle'] as bool? ?? false,
    );
  }
}
