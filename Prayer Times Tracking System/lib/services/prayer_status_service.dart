import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/prayer_status.dart';

class PrayerStatusService {
  static const String _prayerStatusesKey = 'prayer_statuses';
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'prayer_statuses.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE prayer_statuses(
            date TEXT PRIMARY KEY,
            fajr_prayed INTEGER,
            dhuhr_prayed INTEGER,
            asr_prayed INTEGER,
            maghrib_prayed INTEGER,
            isha_prayed INTEGER
          )
        ''');
      },
    );
  }

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
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('prayer_statuses');
    
    return List.generate(maps.length, (i) {
      return PrayerStatus(
        date: DateTime.parse(maps[i]['date']),
        fajrPrayed: maps[i]['fajr_prayed'] == 1,
        dhuhrPrayed: maps[i]['dhuhr_prayed'] == 1,
        asrPrayed: maps[i]['asr_prayed'] == 1,
        maghribPrayed: maps[i]['maghrib_prayed'] == 1,
        ishaPrayed: maps[i]['isha_prayed'] == 1,
      );
    });
  }

  // Belirli bir tarihteki namaz durumunu güncelle
  Future<void> updatePrayerStatus(PrayerStatus status) async {
    final db = await database;
    await db.insert(
      'prayer_statuses',
      {
        'date': status.date.toIso8601String(),
        'fajr_prayed': status.fajrPrayed ? 1 : 0,
        'dhuhr_prayed': status.dhuhrPrayed ? 1 : 0,
        'asr_prayed': status.asrPrayed ? 1 : 0,
        'maghrib_prayed': status.maghribPrayed ? 1 : 0,
        'isha_prayed': status.ishaPrayed ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Belirli bir tarihteki namaz durumunu sil
  Future<void> deletePrayerStatus(DateTime date) async {
    final db = await database;
    await db.delete(
      'prayer_statuses',
      where: 'date = ?',
      whereArgs: [date.toIso8601String()],
    );
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

  Future<PrayerStatus?> getPrayerStatusForDate(DateTime date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'prayer_statuses',
      where: 'date = ?',
      whereArgs: [date.toIso8601String()],
    );

    if (maps.isEmpty) return null;

    return PrayerStatus(
      date: DateTime.parse(maps[0]['date']),
      fajrPrayed: maps[0]['fajr_prayed'] == 1,
      dhuhrPrayed: maps[0]['dhuhr_prayed'] == 1,
      asrPrayed: maps[0]['asr_prayed'] == 1,
      maghribPrayed: maps[0]['maghrib_prayed'] == 1,
      ishaPrayed: maps[0]['isha_prayed'] == 1,
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
} 