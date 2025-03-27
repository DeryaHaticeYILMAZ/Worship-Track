import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/prayer_times.dart';
import 'package:intl/intl.dart';

class PrayerService {
  static const String baseUrl = 'http://api.aladhan.com/v1/timings';

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Konum servisleri devre dışı.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Konum izni reddedildi.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Konum izni kalıcı olarak reddedildi.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<PrayerTimes> getPrayerTimes() async {
    try {
      final position = await _getCurrentLocation();
      final now = DateTime.now();
      final date = DateFormat('dd-MM-yyyy').format(now);
      
      final queryParameters = {
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'method': '2', // ISNA method
        'date': date,
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParameters);
      print('API URL: $uri'); // Debug için URL'yi yazdır

      final response = await http.get(uri);
      print('API Response: ${response.body}'); // Debug için yanıtı yazdır

      if (response.statusCode == 200) {
        return PrayerTimes.fromJson(json.decode(response.body));
      } else {
        throw Exception('Namaz vakitleri alınamadı: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Namaz vakitleri getirme hatası: $e');
      rethrow;
    }
  }

  Future<List<PrayerTimes>> getMonthlyPrayerTimes() async {
    try {
      final position = await _getCurrentLocation();
      final now = DateTime.now();
      final List<PrayerTimes> monthlyTimes = [];

      for (int day = 1; day <= 31; day++) {
        try {
          final date = DateTime(now.year, now.month, day);
          final formattedDate = DateFormat('dd-MM-yyyy').format(date);
          
          final queryParameters = {
            'latitude': position.latitude.toString(),
            'longitude': position.longitude.toString(),
            'method': '2', // ISNA method
            'date': formattedDate,
          };

          final uri = Uri.parse(baseUrl).replace(queryParameters: queryParameters);
          final response = await http.get(uri);

          if (response.statusCode == 200) {
            monthlyTimes.add(PrayerTimes.fromJson(json.decode(response.body)));
          }
        } catch (e) {
          print('Gün $day için namaz vakitleri alınamadı: $e');
          continue;
        }
      }

      return monthlyTimes;
    } catch (e) {
      print('Aylık namaz vakitleri getirme hatası: $e');
      rethrow;
    }
  }
} 