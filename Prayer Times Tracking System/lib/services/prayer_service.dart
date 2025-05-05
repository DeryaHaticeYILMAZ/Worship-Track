import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_times.dart';
import 'package:geolocator/geolocator.dart';

class PrayerService {
  static const String _baseUrl = 'http://api.aladhan.com/v1';
  
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Konum servisleri devre dışı');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Konum izni reddedildi');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Konum izni kalıcı olarak reddedildi');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<PrayerTimes> getPrayerTimes() async {
    try {
      final position = await _getCurrentLocation();
      final now = DateTime.now();
      final date = '${now.day}-${now.month}-${now.year}';
      
      final response = await http.get(Uri.parse(
        '$_baseUrl/timings/$date?latitude=${position.latitude}&longitude=${position.longitude}&method=13'
      ));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timings = data['data']['timings'];
        
        return PrayerTimes(
          date: now,
          fajr: _formatTime(timings['Fajr']),
          sunrise: _formatTime(timings['Sunrise']),
          dhuhr: _formatTime(timings['Dhuhr']),
          asr: _formatTime(timings['Asr']),
          maghrib: _formatTime(timings['Maghrib']),
          isha: _formatTime(timings['Isha']),
        );
      } else {
        throw Exception('Namaz vakitleri alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Namaz vakitleri alınırken hata oluştu: $e');
    }
  }

  Future<List<PrayerTimes>> getHistoricalPrayerTimes(DateTime startDate, DateTime endDate) async {
    try {
      final position = await _getCurrentLocation();
      List<PrayerTimes> prayerTimes = [];
      
      for (var date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
        final formattedDate = '${date.day}-${date.month}-${date.year}';
        
        try {
          final response = await http.get(Uri.parse(
            '$_baseUrl/timings/$formattedDate?latitude=${position.latitude}&longitude=${position.longitude}&method=13'
          ));
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['data'] != null && data['data']['timings'] != null) {
              final timings = data['data']['timings'];
              
              prayerTimes.add(PrayerTimes(
                date: date,
                fajr: _formatTime(timings['Fajr']),
                sunrise: _formatTime(timings['Sunrise']),
                dhuhr: _formatTime(timings['Dhuhr']),
                asr: _formatTime(timings['Asr']),
                maghrib: _formatTime(timings['Maghrib']),
                isha: _formatTime(timings['Isha']),
              ));
            }
          }
        } catch (e) {
          print('Error fetching prayer times for $formattedDate: $e');
          continue; // Skip this date and continue with the next one
        }
        
        // Add a small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      return prayerTimes;
    } catch (e) {
      throw Exception('Geçmiş namaz vakitleri alınırken hata oluştu: $e');
    }
  }

  String _formatTime(String time) {
    // API'den gelen zaman formatını düzenle (örn: "04:30 (EET)" -> "04:30")
    return time.split(' ').first;
  }
} 