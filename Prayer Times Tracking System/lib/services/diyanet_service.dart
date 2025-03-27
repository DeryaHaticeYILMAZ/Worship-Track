import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/prayer_times.dart';

class DiyanetService {
  static const String _baseUrl = 'http://api.aladhan.com/v1/timings';
  static const String _method = '13'; // Turkey method
  
  // Kayseri coordinates
  static const double _latitude = 38.7312;
  static const double _longitude = 35.4787;

  Future<PrayerTimes> getPrayerTimes(DateTime date) async {
    try {
      print('Fetching prayer times for date: $date'); // Debug log
      
      final formattedDate = '${date.day}-${date.month}-${date.year}';
      final url = '$_baseUrl/$formattedDate?latitude=$_latitude&longitude=$_longitude&method=$_method';
      print('API URL: $url'); // Debug log

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout - Please check your internet connection');
        },
      );

      print('Response status code: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data.containsKey('data') && data['data'].containsKey('timings')) {
            return PrayerTimes.fromJson(data);
          } else {
            print('Invalid data format received from API'); // Debug log
            throw Exception('Invalid prayer times data format');
          }
        } catch (e) {
          print('JSON parsing error: $e'); // Debug log
          throw Exception('Error parsing prayer times data: $e');
        }
      } else {
        print('API error: ${response.statusCode} - ${response.body}'); // Debug log
        throw Exception('Failed to load prayer times: ${response.statusCode}');
      }
    } catch (e) {
      print('Service error: $e'); // Debug log
      throw Exception('Error fetching prayer times: $e');
    }
  }

  Future<List<PrayerTimes>> getHistoricalPrayerTimes(DateTime startDate, DateTime endDate) async {
    List<PrayerTimes> prayerTimesList = [];
    DateTime currentDate = startDate;

    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      try {
        final prayerTimes = await getPrayerTimes(currentDate);
        prayerTimesList.add(prayerTimes);
      } catch (e) {
        print('Error fetching historical prayer times for ${currentDate.toString()}: $e');
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return prayerTimesList;
  }

  Future<PrayerTimes> getNextPrayerTime() async {
    final now = DateTime.now();
    return await getPrayerTimes(now);
  }
} 