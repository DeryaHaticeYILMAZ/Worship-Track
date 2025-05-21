import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_status.dart';
import '../models/prayer_times_response.dart';
import 'package:http/http.dart' as http;

class PrayerTrackingService {
  static const String _prayerStatusKey = 'prayer_status';
  static const String _lastLoginKey = 'last_login';
  static const String _lastCheckDateKey = 'last_check_date';

  // Save prayer status
  Future<void> savePrayerStatus(List<PrayerStatus> statuses) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = statuses.map((status) => status.toJson()).toList();
    await prefs.setString(_prayerStatusKey, jsonEncode(jsonList));
  }

  // Get prayer status
  Future<List<PrayerStatus>> getPrayerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prayerStatusKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => PrayerStatus.fromJson(json)).toList();
  }

  // Save last login time
  Future<void> saveLastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
  }

  // Get last login time
  Future<DateTime?> getLastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final loginString = prefs.getString(_lastLoginKey);
    return loginString != null ? DateTime.parse(loginString) : null;
  }

  // Save last check date
  Future<void> saveLastCheckDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCheckDateKey, date.toIso8601String());
  }

  // Get last check date
  Future<DateTime?> getLastCheckDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_lastCheckDateKey);
    return dateString != null ? DateTime.parse(dateString) : null;
  }

  // Check and update missed prayers
  Future<void> checkAndUpdateMissedPrayers() async {
    final lastCheckDate = await getLastCheckDate();
    final now = DateTime.now();
    
    // If no last check date, start from 30 days ago
    final startDate = lastCheckDate ?? now.subtract(Duration(days: 30));
    
    // Get existing statuses
    List<PrayerStatus> statuses = await getPrayerStatus();
    
    // Check each day from last check date to now
    for (DateTime date = startDate;
        !date.isAfter(now);
        date = date.add(Duration(days: 1))) {
      
      // Skip future dates
      if (date.isAfter(now)) continue;
      
      // Get prayer times for this date
      final prayerTimes = await _getPrayerTimesForDate(date);
      if (prayerTimes != null) {
        // Check if we already have prayers for this date
        final existingPrayersForDate = statuses.where((status) => 
          status.prayerTime.year == date.year &&
          status.prayerTime.month == date.month &&
          status.prayerTime.day == date.day
        ).toList();

        // If we don't have prayers for this date, add them as missed
        if (existingPrayersForDate.isEmpty) {
          statuses.addAll([
            PrayerStatus(
              prayerName: 'İmsak',
              prayerTime: DateTime.parse('${date.toString().split(' ')[0]} ${prayerTimes.data.timings.fajr}'),
              isMissed: true,
            ),
            PrayerStatus(
              prayerName: 'Öğle',
              prayerTime: DateTime.parse('${date.toString().split(' ')[0]} ${prayerTimes.data.timings.dhuhr}'),
              isMissed: true,
            ),
            PrayerStatus(
              prayerName: 'İkindi',
              prayerTime: DateTime.parse('${date.toString().split(' ')[0]} ${prayerTimes.data.timings.asr}'),
              isMissed: true,
            ),
            PrayerStatus(
              prayerName: 'Akşam',
              prayerTime: DateTime.parse('${date.toString().split(' ')[0]} ${prayerTimes.data.timings.maghrib}'),
              isMissed: true,
            ),
            PrayerStatus(
              prayerName: 'Yatsı',
              prayerTime: DateTime.parse('${date.toString().split(' ')[0]} ${prayerTimes.data.timings.isha}'),
              isMissed: true,
            ),
          ]);
        }
      }
    }
    
    // Save updated statuses
    await savePrayerStatus(statuses);
    // Update last check date
    await saveLastCheckDate(now);
  }

  // Update prayer status based on login time
  Future<void> updatePrayerStatus(PrayerTimesResponse prayerTimes) async {
    final lastLogin = await getLastLogin();
    final now = DateTime.now();
    final List<PrayerStatus> statuses = [];

    if (lastLogin == null) {
      // First time login, mark all past prayers as missed
      statuses.addAll([
        PrayerStatus(
          prayerName: 'İmsak',
          prayerTime: DateTime.parse('${now.toString().split(' ')[0]} ${prayerTimes.data.timings.fajr}'),
          isMissed: true,
        ),
        PrayerStatus(
          prayerName: 'Öğle',
          prayerTime: DateTime.parse('${now.toString().split(' ')[0]} ${prayerTimes.data.timings.dhuhr}'),
          isMissed: true,
        ),
        PrayerStatus(
          prayerName: 'İkindi',
          prayerTime: DateTime.parse('${now.toString().split(' ')[0]} ${prayerTimes.data.timings.asr}'),
          isMissed: true,
        ),
        PrayerStatus(
          prayerName: 'Akşam',
          prayerTime: DateTime.parse('${now.toString().split(' ')[0]} ${prayerTimes.data.timings.maghrib}'),
          isMissed: true,
        ),
        PrayerStatus(
          prayerName: 'Yatsı',
          prayerTime: DateTime.parse('${now.toString().split(' ')[0]} ${prayerTimes.data.timings.isha}'),
          isMissed: true,
        ),
      ]);
    } else {
      // Get existing statuses
      statuses.addAll(await getPrayerStatus());

      // Calculate the difference in days between last login and now
      final difference = now.difference(lastLogin).inDays;

      // If more than one day has passed, mark all prayers in between as missed
      if (difference > 0) {
        // Get prayer times for each day between last login and now
        for (int i = 0; i <= difference; i++) {
          final currentDate = lastLogin.add(Duration(days: i));
          final prayerTimesForDate = await _getPrayerTimesForDate(currentDate);
          
          if (prayerTimesForDate != null) {
            // Check if we already have prayers for this date
            final existingPrayersForDate = statuses.where((status) => 
              status.prayerTime.year == currentDate.year &&
              status.prayerTime.month == currentDate.month &&
              status.prayerTime.day == currentDate.day
            ).toList();

            // If we don't have prayers for this date, add them as missed
            if (existingPrayersForDate.isEmpty) {
              statuses.addAll([
                PrayerStatus(
                  prayerName: 'İmsak',
                  prayerTime: DateTime.parse('${currentDate.toString().split(' ')[0]} ${prayerTimesForDate.data.timings.fajr}'),
                  isMissed: true,
                ),
                PrayerStatus(
                  prayerName: 'Öğle',
                  prayerTime: DateTime.parse('${currentDate.toString().split(' ')[0]} ${prayerTimesForDate.data.timings.dhuhr}'),
                  isMissed: true,
                ),
                PrayerStatus(
                  prayerName: 'İkindi',
                  prayerTime: DateTime.parse('${currentDate.toString().split(' ')[0]} ${prayerTimesForDate.data.timings.asr}'),
                  isMissed: true,
                ),
                PrayerStatus(
                  prayerName: 'Akşam',
                  prayerTime: DateTime.parse('${currentDate.toString().split(' ')[0]} ${prayerTimesForDate.data.timings.maghrib}'),
                  isMissed: true,
                ),
                PrayerStatus(
                  prayerName: 'Yatsı',
                  prayerTime: DateTime.parse('${currentDate.toString().split(' ')[0]} ${prayerTimesForDate.data.timings.isha}'),
                  isMissed: true,
                ),
              ]);
            }
          }
        }
      } else {
        // For same day, mark prayers as missed if they occurred between last login and now
        for (var status in statuses) {
          if (status.prayerTime.isAfter(lastLogin) && 
              status.prayerTime.isBefore(now) && 
              !status.isCompleted) {
            status = status.copyWith(isMissed: true);
          }
        }
      }
    }

    // Save updated statuses
    await savePrayerStatus(statuses);
    // Update last login time
    await saveLastLogin();
  }

  // Helper method to get prayer times for a specific date
  Future<PrayerTimesResponse?> _getPrayerTimesForDate(DateTime date) async {
    try {
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final response = await http.get(
        Uri.parse('https://api.aladhan.com/v1/timingsByCity?city=Kayseri&country=Turkey&method=13&date=$formattedDate'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PrayerTimesResponse.fromJson(jsonData);
      }
    } catch (e) {
      print('Error fetching prayer times for date: $e');
    }
    return null;
  }

  // Mark a prayer as completed
  Future<void> markPrayerAsCompleted(String prayerName) async {
    final statuses = await getPrayerStatus();
    final now = DateTime.now();
    
    for (var i = 0; i < statuses.length; i++) {
      if (statuses[i].prayerName == prayerName && 
          !statuses[i].isCompleted && 
          !statuses[i].isMissed) {
        statuses[i] = statuses[i].copyWith(
          isCompleted: true,
          completedAt: now,
        );
        break;
      }
    }

    await savePrayerStatus(statuses);
  }
} 