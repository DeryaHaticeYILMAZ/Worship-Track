import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/prayer_times_response.dart';

class PrayerTimesService {
  static const String baseUrl = 'https://api.aladhan.com/v1';

  Future<PrayerTimesResponse> getPrayerTimes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/timingsByCity?city=Kayseri&country=Turkey&method=13'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Log the raw response and specific parts we're interested in
        developer.log('Raw API Response: ${response.body}', name: 'PrayerTimesService');
        developer.log('Data structure: ${jsonData['data']}', name: 'PrayerTimesService');
        if (jsonData['data'] != null) {
          developer.log('Meta structure: ${jsonData['data']['meta']}', name: 'PrayerTimesService');
          if (jsonData['data']['meta'] != null) {
            developer.log('Offset structure: ${jsonData['data']['meta']['offset']}', name: 'PrayerTimesService');
          }
        }
        return PrayerTimesResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load prayer times. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      developer.log('Error details: $e\nStack trace: $stackTrace', name: 'PrayerTimesService', error: e);
      throw Exception('Error fetching prayer times: $e');
    }
  }

  Future<Map<String, dynamic>?> getNextPrayerTime() async {
    try {
      final prayerTimes = await getPrayerTimes();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Get all prayer times for today
      final times = {
        'İmsak': DateTime.parse('${today.toString().split(' ')[0]} ${prayerTimes.data.timings.fajr}'),
        'Öğle': DateTime.parse('${today.toString().split(' ')[0]} ${prayerTimes.data.timings.dhuhr}'),
        'İkindi': DateTime.parse('${today.toString().split(' ')[0]} ${prayerTimes.data.timings.asr}'),
        'Akşam': DateTime.parse('${today.toString().split(' ')[0]} ${prayerTimes.data.timings.maghrib}'),
        'Yatsı': DateTime.parse('${today.toString().split(' ')[0]} ${prayerTimes.data.timings.isha}'),
      };

      // Find the next prayer time
      DateTime? nextPrayerTime;
      String? nextPrayerName;
      
      for (var entry in times.entries) {
        if (entry.value.isAfter(now)) {
          if (nextPrayerTime == null || entry.value.isBefore(nextPrayerTime)) {
            nextPrayerTime = entry.value;
            nextPrayerName = entry.key;
          }
        }
      }

      // If no next prayer time found for today, get first prayer time for tomorrow
      if (nextPrayerTime == null) {
        final tomorrow = today.add(const Duration(days: 1));
        final tomorrowResponse = await http.get(
          Uri.parse('$baseUrl/timingsByCity?city=Kayseri&country=Turkey&method=13'),
        );
        
        if (tomorrowResponse.statusCode == 200) {
          final tomorrowPrayerTimes = PrayerTimesResponse.fromJson(json.decode(tomorrowResponse.body));
          nextPrayerTime = DateTime.parse('${tomorrow.toString().split(' ')[0]} ${tomorrowPrayerTimes.data.timings.fajr}');
          nextPrayerName = 'İmsak';
        }
      }

      if (nextPrayerTime != null && nextPrayerName != null) {
        return {
          'time': nextPrayerTime,
          'name': nextPrayerName,
        };
      }

      return null;
    } catch (e) {
      print('Error getting next prayer time: $e');
      return null;
    }
  }

  Future<PrayerTimesResponse> getPrayerTimesForDate(DateTime date) async {
    try {
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final response = await http.get(
        Uri.parse('$baseUrl/timingsByCity?city=Kayseri&country=Turkey&method=13&date=$formattedDate'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PrayerTimesResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load prayer times for date. Status code: \\${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching prayer times for date: $e');
    }
  }
} 
 