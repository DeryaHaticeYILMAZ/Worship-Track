import 'package:intl/intl.dart';

class PrayerTimes {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final DateTime date;
  
  // Prayer status tracking
  bool fajrPrayed;
  bool dhuhrPrayed;
  bool asrPrayed;
  bool maghribPrayed;
  bool ishaPrayed;

  PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
    this.fajrPrayed = false,
    this.dhuhrPrayed = false,
    this.asrPrayed = false,
    this.maghribPrayed = false,
    this.ishaPrayed = false,
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    final timings = json['data']['timings'];
    final dateStr = json['data']['date']['gregorian']['date'];
    
    // API'den gelen 24 saat formatındaki saatleri 12 saat formatına çevir
    String formatTime(String time24) {
      try {
        final parsedTime = DateFormat('HH:mm').parse(time24);
        return DateFormat('hh:mm a').format(parsedTime);
      } catch (e) {
        return time24; // Hata durumunda orijinal değeri döndür
      }
    }

    return PrayerTimes(
      fajr: formatTime(timings['Fajr']),
      sunrise: formatTime(timings['Sunrise']),
      dhuhr: formatTime(timings['Dhuhr']),
      asr: formatTime(timings['Asr']),
      maghrib: formatTime(timings['Maghrib']),
      isha: formatTime(timings['Isha']),
      date: DateFormat('dd-MM-yyyy').parse(dateStr),
    );
  }

  String getNextPrayer() {
    final now = DateTime.now();
    final currentTime = DateFormat('HH:mm').format(now);
    
    final prayers = [
      {'name': 'Fajr', 'time': fajr},
      {'name': 'Sunrise', 'time': sunrise},
      {'name': 'Dhuhr', 'time': dhuhr},
      {'name': 'Asr', 'time': asr},
      {'name': 'Maghrib', 'time': maghrib},
      {'name': 'Isha', 'time': isha},
    ];

    for (var prayer in prayers) {
      if (currentTime.compareTo(prayer['time']!) < 0) {
        return prayer['name']!;
      }
    }

    return 'Fajr'; // If all prayers have passed, return next day's Fajr
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
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
      'date': date.toIso8601String(),
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
      fajr: map['fajr'] ?? '00:00',
      sunrise: map['sunrise'] ?? '00:00',
      dhuhr: map['dhuhr'] ?? '00:00',
      asr: map['asr'] ?? '00:00',
      maghrib: map['maghrib'] ?? '00:00',
      isha: map['isha'] ?? '00:00',
      date: DateTime.parse(map['date']),
      fajrPrayed: map['fajrPrayed'] ?? false,
      dhuhrPrayed: map['dhuhrPrayed'] ?? false,
      asrPrayed: map['asrPrayed'] ?? false,
      maghribPrayed: map['maghribPrayed'] ?? false,
      ishaPrayed: map['ishaPrayed'] ?? false,
    );
  }
} 