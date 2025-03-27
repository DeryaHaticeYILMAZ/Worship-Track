import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_status.dart';

class PrayerStatusService {
  static const String _prayerStatusesKey = 'prayer_statuses';

  // Tüm namaz durumlarını kaydet
  Future<void> savePrayerStatuses(List<PrayerStatus> statuses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusesJson = statuses.map((status) => status.toJson()).toList();
      await prefs.setString(_prayerStatusesKey, json.encode(statusesJson));
    } catch (e) {
      print('Error saving prayer statuses: $e');
      rethrow;
    }
  }

  // Tüm namaz durumlarını getir
  Future<List<PrayerStatus>> getAllPrayerStatuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusesJson = prefs.getString(_prayerStatusesKey);
      
      if (statusesJson == null || statusesJson.isEmpty) {
        return [];
      }

      final List<dynamic> decodedList = json.decode(statusesJson);
      return decodedList.map((json) => PrayerStatus.fromJson(json)).toList();
    } catch (e) {
      print('Error getting prayer statuses: $e');
      return [];
    }
  }

  // Belirli bir tarihteki namaz durumlarını getir
  Future<PrayerStatus?> getPrayerStatusForDate(DateTime date) async {
    try {
      final statuses = await getAllPrayerStatuses();
      return statuses.firstWhere(
        (status) => status.date.year == date.year &&
                    status.date.month == date.month &&
                    status.date.day == date.day,
        orElse: () => PrayerStatus(
          date: date,
          fajrPrayed: false,
          dhuhrPrayed: false,
          asrPrayed: false,
          maghribPrayed: false,
          ishaPrayed: false,
        ),
      );
    } catch (e) {
      print('Error getting prayer status for date: $e');
      return null;
    }
  }

  // Belirli bir tarihteki namaz durumunu güncelle
  Future<void> updatePrayerStatus(PrayerStatus status) async {
    try {
      final statuses = await getAllPrayerStatuses();
      final index = statuses.indexWhere(
        (s) => s.date.year == status.date.year &&
                s.date.month == status.date.month &&
                s.date.day == status.date.day,
      );

      if (index != -1) {
        statuses[index] = status;
      } else {
        statuses.add(status);
      }

      await savePrayerStatuses(statuses);
    } catch (e) {
      print('Error updating prayer status: $e');
      rethrow;
    }
  }

  // Belirli bir tarihteki namaz durumunu sil
  Future<void> deletePrayerStatus(DateTime date) async {
    try {
      final statuses = await getAllPrayerStatuses();
      statuses.removeWhere(
        (status) => status.date.year == date.year &&
                    status.date.month == date.month &&
                    status.date.day == date.day,
      );
      await savePrayerStatuses(statuses);
    } catch (e) {
      print('Error deleting prayer status: $e');
      rethrow;
    }
  }

  // Tüm namaz durumlarını sil
  Future<void> deleteAllPrayerStatuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prayerStatusesKey);
    } catch (e) {
      print('Error deleting all prayer statuses: $e');
      rethrow;
    }
  }
} 