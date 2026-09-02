import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 Timestamp හැසිරවීමට මෙය අත්‍යවශ්‍යයි

class HousingDetails {
  final String houseNumber;
  final bool? hasHouse; // 🟢 Radio button කිසිවක් තෝරා නොමැතිව තැබීමට bool? ලෙස යොදා ඇත
  final String nature; 
  final String sanitation; 
  final String electricity; 
  final String water; 
  final bool hasFixedPhone; 
  final bool hasMobilePhone; 
  final String signal; 

  // 🟢 අලුතින් එකතු කළ ලොග් විස්තර (Log details)
  final String? updatedBy;
  final DateTime? updatedAt;

  HousingDetails({
    this.houseNumber = '',
    this.hasHouse, // 🟢 Default අගය ඉවත් කර null ලෙස තබා ඇත
    this.nature = '', // 🟢 Default අගයන් සියල්ල හිස් කර (Empty) ඇත
    this.sanitation = '',
    this.electricity = '',
    this.water = '',
    this.hasFixedPhone = false, // 🟢 Checkbox එක unchecked ලෙස තැබීමට false
    this.hasMobilePhone = false,
    this.signal = '',
    this.updatedBy, // 🟢
    this.updatedAt, // 🟢
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
    String? updatedBy,    // 🟢
    DateTime? updatedAt,  // 🟢
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
      updatedBy: updatedBy ?? this.updatedBy, // 🟢
      updatedAt: updatedAt ?? this.updatedAt, // 🟢
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
    'updatedBy': updatedBy,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory HousingDetails.fromMap(Map<String, dynamic> map) {
    // 🟢 Timestamp සහ DateTime නිවැරදිව හසුරුවන කොටස
    DateTime? parsedDate;
    if (map['updatedAt'] != null) {
      final t = map['updatedAt'];
      if (t is Timestamp) { // Cloud Firestore Timestamp එකක් නම්
        parsedDate = t.toDate();
      } else if (t is DateTime) {
        parsedDate = t;
      } else {
        parsedDate = DateTime.tryParse(t.toString());
      }
    }

    return HousingDetails(
      houseNumber: map['houseNumber']?.toString() ?? '',
      hasHouse: map['hasHouse'] as bool?,
      nature: map['nature']?.toString() ?? '',
      sanitation: map['sanitation']?.toString() ?? '',
      electricity: map['electricity']?.toString() ?? '',
      water: map['water']?.toString() ?? '',
      hasFixedPhone: map['hasFixedPhone'] as bool? ?? false,
      hasMobilePhone: map['hasMobilePhone'] as bool? ?? false,
      signal: map['signal']?.toString() ?? '',
      updatedBy: map['updatedBy']?.toString(), // 🟢
      updatedAt: parsedDate,                   // 🟢
    );
  }
}