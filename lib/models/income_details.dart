class IncomeDetails {
  final String houseNumber;
  final String mainIncome;
  final String extraIncome;
  
  final String jobType;
  final String jobPosition;
  final String jobInstitute;
  
  final String tourismType;
  final String tourismOther;
  
  final String agricultureType;
  final String agricultureOther;
  
  final String animalHusbandryType;
  final String animalHusbandryOther;
  final String animalCount;
  
  final String fishingType;

  IncomeDetails({
    this.houseNumber = '',
    this.mainIncome = 'ඇත',
    this.extraIncome = 'නැත',
    this.jobType = 'නැත',
    this.jobPosition = '',
    this.jobInstitute = '',
    this.tourismType = 'නැත',
    this.tourismOther = '',
    this.agricultureType = 'නැත',
    this.agricultureOther = '',
    this.animalHusbandryType = 'නැත',
    this.animalHusbandryOther = '',
    this.animalCount = '',
    this.fishingType = 'නැත',
  });

  IncomeDetails copyWith({
    String? houseNumber,
    String? mainIncome,
    String? extraIncome,
    String? jobType,
    String? jobPosition,
    String? jobInstitute,
    String? tourismType,
    String? tourismOther,
    String? agricultureType,
    String? agricultureOther,
    String? animalHusbandryType,
    String? animalHusbandryOther,
    String? animalCount,
    String? fishingType,
  }) {
    return IncomeDetails(
      houseNumber: houseNumber ?? this.houseNumber,
      mainIncome: mainIncome ?? this.mainIncome,
      extraIncome: extraIncome ?? this.extraIncome,
      jobType: jobType ?? this.jobType,
      jobPosition: jobPosition ?? this.jobPosition,
      jobInstitute: jobInstitute ?? this.jobInstitute,
      tourismType: tourismType ?? this.tourismType,
      tourismOther: tourismOther ?? this.tourismOther,
      agricultureType: agricultureType ?? this.agricultureType,
      agricultureOther: agricultureOther ?? this.agricultureOther,
      animalHusbandryType: animalHusbandryType ?? this.animalHusbandryType,
      animalHusbandryOther: animalHusbandryOther ?? this.animalHusbandryOther,
      animalCount: animalCount ?? this.animalCount,
      fishingType: fishingType ?? this.fishingType,
    );
  }

  Map<String, dynamic> toMap() => {
    'houseNumber': houseNumber,
    'mainIncome': mainIncome,
    'extraIncome': extraIncome,
    'jobType': jobType,
    'jobPosition': jobPosition,
    'jobInstitute': jobInstitute,
    'tourismType': tourismType,
    'tourismOther': tourismOther,
    'agricultureType': agricultureType,
    'agricultureOther': agricultureOther,
    'animalHusbandryType': animalHusbandryType,
    'animalHusbandryOther': animalHusbandryOther,
    'animalCount': animalCount,
    'fishingType': fishingType,
  };

  factory IncomeDetails.fromMap(Map<String, dynamic> map) {
    return IncomeDetails(
      houseNumber: map['houseNumber']?.toString() ?? '',
      mainIncome: map['mainIncome']?.toString() ?? 'ඇත',
      extraIncome: map['extraIncome']?.toString() ?? 'නැත',
      jobType: map['jobType']?.toString() ?? 'නැත',
      jobPosition: map['jobPosition']?.toString() ?? '',
      jobInstitute: map['jobInstitute']?.toString() ?? '',
      tourismType: map['tourismType']?.toString() ?? 'නැත',
      tourismOther: map['tourismOther']?.toString() ?? '',
      agricultureType: map['agricultureType']?.toString() ?? 'නැත',
      agricultureOther: map['agricultureOther']?.toString() ?? '',
      animalHusbandryType: map['animalHusbandryType']?.toString() ?? 'නැත',
      animalHusbandryOther: map['animalHusbandryOther']?.toString() ?? '',
      animalCount: map['animalCount']?.toString() ?? '',
      fishingType: map['fishingType']?.toString() ?? 'නැත',
    );
  }
}
