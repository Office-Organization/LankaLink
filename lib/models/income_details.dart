import 'package:cloud_firestore/cloud_firestore.dart';

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

  // 🟢 අලුතින් එකතු කළ ලොග් විස්තර (Log details)
  final String? updatedBy;
  final DateTime? updatedAt;

  IncomeDetails({
    this.houseNumber = '',
    // 🟢 සියලුම Default අගයන් හිස් (Empty) කර ඇත
    this.mainIncome = '',
    this.extraIncome = '',
    this.jobType = '',
    this.jobPosition = '',
    this.jobInstitute = '',
    this.tourismType = '',
    this.tourismOther = '',
    this.agricultureType = '',
    this.agricultureOther = '',
    this.animalHusbandryType = '',
    this.animalHusbandryOther = '',
    this.animalCount = '',
    this.fishingType = '',
    this.updatedBy, // 🟢
    this.updatedAt, // 🟢
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
    String? updatedBy,    // 🟢
    DateTime? updatedAt,  // 🟢
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
      updatedBy: updatedBy ?? this.updatedBy, // 🟢
      updatedAt: updatedAt ?? this.updatedAt, // 🟢
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
    'updatedBy': updatedBy,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory IncomeDetails.fromMap(Map<String, dynamic> map) {
    // 🟢 Timestamp සහ DateTime නිවැරදිව හසුරුවන කොටස
    DateTime? parsedDate;
    if (map['updatedAt'] != null) {
      final t = map['updatedAt'];
      if (t is Timestamp) { 
        parsedDate = t.toDate();
      } else if (t is DateTime) {
        parsedDate = t;
      } else {
        parsedDate = DateTime.tryParse(t.toString());
      }
    }

    return IncomeDetails(
      houseNumber: map['houseNumber']?.toString() ?? '',
      mainIncome: map['mainIncome']?.toString() ?? '',
      extraIncome: map['extraIncome']?.toString() ?? '',
      jobType: map['jobType']?.toString() ?? '',
      jobPosition: map['jobPosition']?.toString() ?? '',
      jobInstitute: map['jobInstitute']?.toString() ?? '',
      tourismType: map['tourismType']?.toString() ?? '',
      tourismOther: map['tourismOther']?.toString() ?? '',
      agricultureType: map['agricultureType']?.toString() ?? '',
      agricultureOther: map['agricultureOther']?.toString() ?? '',
      animalHusbandryType: map['animalHusbandryType']?.toString() ?? '',
      animalHusbandryOther: map['animalHusbandryOther']?.toString() ?? '',
      animalCount: map['animalCount']?.toString() ?? '',
      fishingType: map['fishingType']?.toString() ?? '',
      updatedBy: map['updatedBy']?.toString(), // 🟢
      updatedAt: parsedDate,                   // 🟢
    );
  }
}