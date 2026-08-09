class HealthInfo {
  final bool hasMainDisability;
  final bool otherDisability;
  final String diseases;
  final String careType;
  final String medicalTreatment;
  final String prevention;
  final String medicalCheckup;
  final String nutrition;
  final String drinks;
  final String milk;
  final String alcohol;

  const HealthInfo({
    this.hasMainDisability = false,
    this.otherDisability = false,
    this.diseases = '',
    this.careType = '',
    this.medicalTreatment = '',
    this.prevention = '',
    this.medicalCheckup = '',
    this.nutrition = '',
    this.drinks = '',
    this.milk = '',
    this.alcohol = '',
  });

  factory HealthInfo.fromMap(Map<String, dynamic> map) {
    return HealthInfo(
      hasMainDisability: map['hasMainDisability'] as bool? ?? false,
      otherDisability: map['otherDisability'] as bool? ?? false,
      diseases: map['diseases'] as String? ?? '',
      careType: map['careType'] as String? ?? '',
      medicalTreatment: map['medicalTreatment'] as String? ?? '',
      prevention: map['prevention'] as String? ?? '',
      medicalCheckup: map['medicalCheckup'] as String? ?? '',
      nutrition: map['nutrition'] as String? ?? '',
      drinks: map['drinks'] as String? ?? '',
      milk: map['milk'] as String? ?? '',
      alcohol: map['alcohol'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hasMainDisability': hasMainDisability,
      'otherDisability': otherDisability,
      'diseases': diseases,
      'careType': careType,
      'medicalTreatment': medicalTreatment,
      'prevention': prevention,
      'medicalCheckup': medicalCheckup,
      'nutrition': nutrition,
      'drinks': drinks,
      'milk': milk,
      'alcohol': alcohol,
    };
  }

  HealthInfo copyWith({
    bool? hasMainDisability,
    bool? otherDisability,
    String? diseases,
    String? careType,
    String? medicalTreatment,
    String? prevention,
    String? medicalCheckup,
    String? nutrition,
    String? drinks,
    String? milk,
    String? alcohol,
  }) {
    return HealthInfo(
      hasMainDisability: hasMainDisability ?? this.hasMainDisability,
      otherDisability: otherDisability ?? this.otherDisability,
      diseases: diseases ?? this.diseases,
      careType: careType ?? this.careType,
      medicalTreatment: medicalTreatment ?? this.medicalTreatment,
      prevention: prevention ?? this.prevention,
      medicalCheckup: medicalCheckup ?? this.medicalCheckup,
      nutrition: nutrition ?? this.nutrition,
      drinks: drinks ?? this.drinks,
      milk: milk ?? this.milk,
      alcohol: alcohol ?? this.alcohol,
    );
  }
}