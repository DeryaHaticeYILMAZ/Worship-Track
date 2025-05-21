// lib/services/quran_reading_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quran_reading_record.dart';

class QuranReadingService {
  static const String _baseUrl = 'http://10.0.2.2:5000';

  Future<int> getDailyGoal(String email) async {
    final response = await http.get(Uri.parse('$_baseUrl/quran_goal?email=$email'));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['daily_goal'] is int
          ? decoded['daily_goal']
          : int.tryParse(decoded['daily_goal'].toString()) ?? 1;
    } else {
      throw Exception('Failed to load daily goal');
    }
  }

  Future<void> setDailyGoal(String email, DateTime date, int goal) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/quran_goal'),
      body: {
        'email': email,
        'date': date.toIso8601String().split('T')[0],
        'daily_goal': goal.toString(),
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to set daily goal');
    }
  }


  Future<List<QuranReadingRecord>> getReadingRecords(String email) async {
    final response = await http.get(Uri.parse('$_baseUrl/quran_reading?email=$email'));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['reading_records'] ?? [];
      return data.map((item) => QuranReadingRecord.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load reading records');
    }
  }

  Future<void> setPagesReadAndGoal(String email, DateTime date, int pagesRead, int dailyGoal) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/quran_reading'),
      body: {
        'email': email,
        'date': date.toIso8601String().split('T')[0],
        'pages_read': pagesRead.toString(),
        'daily_goal': dailyGoal.toString(),
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to set pages read and goal');
    }

    // Günlük hedefi ayrıca güncelle (quran_goal tablosu)
    DateTime today = DateTime.now();
    await setDailyGoal(email, today, dailyGoal);

  }
}