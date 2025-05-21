import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/fasting_record.dart';

DateTime parseFastingDate(String dateStr) {
  try {
    // "Sat, 01 Mar 2025 00:00:00 GMT" gibi stringler için
    return DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US').parseUtc(dateStr);
  } catch (e) {
    try {
      return DateTime.parse(dateStr);
    } catch (e2) {
      throw FormatException('Tarih parse edilemedi: $dateStr');
    }
  }
}

class FastingService {
  static const String _baseUrl = 'http://10.0.2.2:5000'; // Gerekirse değiştir

  Future<List<FastingRecord>> getFastingRecords(String email) async {
    final response = await http.get(Uri.parse('$_baseUrl/fasting?email=$email'));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['fasting_days'] is List) {
        final List<dynamic> data = decoded['fasting_days'];
        print('FASTING RECORDS: $data');
        return data.map((item) => FastingRecord(
          date: parseFastingDate(item['date']),
          completed: item['completed'] == 1 || item['completed'] == true || item['completed'] == '1',
        )).toList();
      } else {
        // If fasting_days is missing or not a list, return empty list
        return [];
      }
    } else {
      throw Exception('Failed to load fasting records');
    }
  }

  Future<void> updateFastingRecord(String email, DateTime date, bool completed) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/fasting'),
      body: {
        'email': email,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'completed': completed ? '1' : '0',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update fasting record');
    }
  }
} 