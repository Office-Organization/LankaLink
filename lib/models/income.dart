class IncomeInfo {
  final String mainIncome;
  final String additionalIncome;
  final String job;
  final String tourism;
  final String agriculture;
  final String animalHusbandry;
  final String animalCount;
  final String fishingIndustry;

  const IncomeInfo({
    this.mainIncome = 'ඇත',
    this.additionalIncome = 'ඇත',
    this.job = 'රජයේ',
    this.tourism = 'පහසුකම් සැපයීම',
    this.agriculture = 'වී',
    this.animalHusbandry = 'කුකුළන්',
    this.animalCount = '',
    this.fishingIndustry = 'මිරිදිය',
  });

  factory IncomeInfo.fromMap(Map<String, dynamic> map) {
    return IncomeInfo(
      mainIncome: map['mainIncome'] as String? ?? 'ඇත',
      additionalIncome: map['additionalIncome'] as String? ?? 'ඇත',
      job: map['job'] as String? ?? 'රජයේ',
      tourism: map['tourism'] as String? ?? 'පහසුකම් සැපයීම',
      agriculture: map['agriculture'] as String? ?? 'වී',
      animalHusbandry: map['animalHusbandry'] as String? ?? 'කුකුළන්',
      animalCount: map['animalCount'] as String? ?? '',
      fishingIndustry: map['fishingIndustry'] as String? ?? 'මිරිදිය',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mainIncome': mainIncome,
      'additionalIncome': additionalIncome,
      'job': job,
      'tourism': tourism,
      'agriculture': agriculture,
      'animalHusbandry': animalHusbandry,
      'animalCount': animalCount,
      'fishingIndustry': fishingIndustry,
    };
  }

  IncomeInfo copyWith({
    String? mainIncome,
    String? additionalIncome,
    String? job,
    String? tourism,
    String? agriculture,
    String? animalHusbandry,
    String? animalCount,
    String? fishingIndustry,
  }) {
    return IncomeInfo(
      mainIncome: mainIncome ?? this.mainIncome,
      additionalIncome: additionalIncome ?? this.additionalIncome,
      job: job ?? this.job,
      tourism: tourism ?? this.tourism,
      agriculture: agriculture ?? this.agriculture,
      animalHusbandry: animalHusbandry ?? this.animalHusbandry,
      animalCount: animalCount ?? this.animalCount,
      fishingIndustry: fishingIndustry ?? this.fishingIndustry,
    );
  }
}