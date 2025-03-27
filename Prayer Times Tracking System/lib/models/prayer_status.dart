import 'package:intl/intl.dart';

enum PrayerType {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha
}

class PrayerStatus {
  final DateTime date;
  bool fajrPrayed;
  bool dhuhrPrayed;
  bool asrPrayed;
  bool maghribPrayed;
  bool ishaPrayed;

  PrayerStatus({
    required this.date,
    this.fajrPrayed = false,
    this.dhuhrPrayed = false,
    this.asrPrayed = false,
    this.maghribPrayed = false,
    this.ishaPrayed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'fajrPrayed': fajrPrayed,
      'dhuhrPrayed': dhuhrPrayed,
      'asrPrayed': asrPrayed,
      'maghribPrayed': maghribPrayed,
      'ishaPrayed': ishaPrayed,
    };
  }

  factory PrayerStatus.fromJson(Map<String, dynamic> json) {
    return PrayerStatus(
      date: DateTime.parse(json['date']),
      fajrPrayed: json['fajrPrayed'] ?? false,
      dhuhrPrayed: json['dhuhrPrayed'] ?? false,
      asrPrayed: json['asrPrayed'] ?? false,
      maghribPrayed: json['maghribPrayed'] ?? false,
      ishaPrayed: json['ishaPrayed'] ?? false,
    );
  }

  bool get isCompleted {
    return fajrPrayed && dhuhrPrayed && asrPrayed && maghribPrayed && ishaPrayed;
  }
} 