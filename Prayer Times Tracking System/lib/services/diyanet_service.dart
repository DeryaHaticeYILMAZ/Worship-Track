import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_times.dart';

class DiyanetService {
  // Kayseri'nin koordinatları
  static const double _latitude = 38.7312;
  static const double _longitude = 35.4787;
  static const String _baseUrl = 'https://api.aladhan.com/v1';

  Future<PrayerTimes> getPrayerTimes() async {
    try {
      final now = DateTime.now();
      final response = await http.get(
        Uri.parse('$_baseUrl/calendar/${now.year}/${now.month}?latitude=$_latitude&longitude=$_longitude&method=13'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final today = data['data'][now.day - 1]['timings'];
        
        return PrayerTimes(
          date: now,
          fajr: today['Fajr'],
          sunrise: today['Sunrise'],
          dhuhr: today['Dhuhr'],
          asr: today['Asr'],
          maghrib: today['Maghrib'],
          isha: today['Isha'],
        );
      } else {
        throw Exception('Namaz vakitleri alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      print('API Hatası: $e');
      // API hatası durumunda varsayılan vakitleri döndür
      final now = DateTime.now();
      return PrayerTimes(
        date: now,
        fajr: '05:30',
        sunrise: '07:00',
        dhuhr: '12:30',
        asr: '15:30',
        maghrib: '18:00',
        isha: '19:30',
      );
    }
  }

  Future<List<PrayerTimes>> getHistoricalPrayerTimes(DateTime startDate, DateTime endDate) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/calendar/${startDate.year}/${startDate.month}?latitude=$_latitude&longitude=$_longitude&method=13'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<PrayerTimes> prayerTimes = [];

        for (var day in data['data']) {
          final date = DateTime.parse(day['date']['gregorian']);
          if (date.isAfter(startDate.subtract(const Duration(days: 1))) && 
              date.isBefore(endDate.add(const Duration(days: 1)))) {
            final timings = day['timings'];
            prayerTimes.add(PrayerTimes(
              date: date,
              fajr: timings['Fajr'],
              sunrise: timings['Sunrise'],
              dhuhr: timings['Dhuhr'],
              asr: timings['Asr'],
              maghrib: timings['Maghrib'],
              isha: timings['Isha'],
            ));
          }
        }

        return prayerTimes;
      } else {
        throw Exception('Geçmiş namaz vakitleri alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      print('API Hatası: $e');
      // API hatası durumunda varsayılan vakitleri döndür
      final List<PrayerTimes> defaultTimes = [];
      var currentDate = startDate;

      while (currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
        defaultTimes.add(PrayerTimes(
          date: currentDate,
          fajr: '05:30',
          sunrise: '07:00',
          dhuhr: '12:30',
          asr: '15:30',
          maghrib: '18:00',
          isha: '19:30',
        ));
        currentDate = currentDate.add(const Duration(days: 1));
      }

      return defaultTimes;
    }
  }
} 