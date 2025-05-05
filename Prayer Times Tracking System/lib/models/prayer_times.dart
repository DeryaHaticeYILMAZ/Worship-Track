import 'package:intl/intl.dart';

class PrayerTimes {
  final DateTime date;
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  
  // Prayer status tracking
  bool fajrPrayed;
  bool dhuhrPrayed;
  bool asrPrayed;
  bool maghribPrayed;
  bool ishaPrayed;

  PrayerTimes({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.fajrPrayed = false,
    this.dhuhrPrayed = false,
    this.asrPrayed = false,
    this.maghribPrayed = false,
    this.ishaPrayed = false,
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    return PrayerTimes(
      date: DateFormat('dd.MM.yyyy').parse(json['MiladiTarihKisa']),
      fajr: json['Imsak'],
      sunrise: json['Gunes'],
      dhuhr: json['Ogle'],
      asr: json['Ikindi'],
      maghrib: json['Aksam'],
      isha: json['Yatsi'],
    );
  }

  Map<String, dynamic> toJson() => {
    'date': DateFormat('dd.MM.yyyy').format(date),
    'fajr': fajr,
    'sunrise': sunrise,
    'dhuhr': dhuhr,
    'asr': asr,
    'maghrib': maghrib,
    'isha': isha,
  };

  String getNextPrayer() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    
    final prayers = [
      {'name': 'Sabah', 'time': fajr},
      {'name': 'Güneş', 'time': sunrise},
      {'name': 'Öğle', 'time': dhuhr},
      {'name': 'İkindi', 'time': asr},
      {'name': 'Akşam', 'time': maghrib},
      {'name': 'Yatsı', 'time': isha},
    ];

    for (var prayer in prayers) {
      final prayerTime = prayer['time']!.split(':');
      final prayerHour = int.parse(prayerTime[0]);
      final prayerMinute = int.parse(prayerTime[1]);
      
      if (currentHour < prayerHour || 
         (currentHour == prayerHour && currentMinute < prayerMinute)) {
        return '${prayer['name']} - ${prayer['time']}';
      }
    }
    
    return 'Sabah - $fajr';
  }

  String formatTimeForDisplay(String time) {
    return time;
  }

  DateTime getPrayerDateTime(String prayerTime) {
    final now = DateTime.now();
    final time = DateFormat('HH:mm').parse(prayerTime);
    return DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
      'fajrPrayed': fajrPrayed,
      'dhuhrPrayed': dhuhrPrayed,
      'asrPrayed': asrPrayed,
      'maghribPrayed': maghribPrayed,
      'ishaPrayed': ishaPrayed,
    };
  }

  // Create from Map for storage retrieval
  factory PrayerTimes.fromMap(Map<String, dynamic> map) {
    return PrayerTimes(
      date: DateTime.parse(map['date']),
      fajr: map['fajr'] ?? '00:00',
      sunrise: map['sunrise'] ?? '00:00',
      dhuhr: map['dhuhr'] ?? '00:00',
      asr: map['asr'] ?? '00:00',
      maghrib: map['maghrib'] ?? '00:00',
      isha: map['isha'] ?? '00:00',
      fajrPrayed: map['fajrPrayed'] ?? false,
      dhuhrPrayed: map['dhuhrPrayed'] ?? false,
      asrPrayed: map['asrPrayed'] ?? false,
      maghribPrayed: map['maghribPrayed'] ?? false,
      ishaPrayed: map['ishaPrayed'] ?? false,
    );
  }

  bool isPrayerPrayed(String prayer) {
    switch (prayer) {
      case 'fajr':
        return fajrPrayed;
      case 'dhuhr':
        return dhuhrPrayed;
      case 'asr':
        return asrPrayed;
      case 'maghrib':
        return maghribPrayed;
      case 'isha':
        return ishaPrayed;
      default:
        return false;
    }
  }
} 