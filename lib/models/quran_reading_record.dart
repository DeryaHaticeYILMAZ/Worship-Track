import 'package:intl/intl.dart';

class QuranReadingRecord {
  final DateTime date;
  int pagesRead;
  int? dailyGoal;

  QuranReadingRecord({
    required this.date,
    required this.pagesRead,
    this.dailyGoal,
  });

  factory QuranReadingRecord.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US').parseUtc(json['date']);
    } catch (_) {
      parsedDate = DateTime.tryParse(json['date']) ?? DateTime.now();
    }

    return QuranReadingRecord(
      date: parsedDate,
      pagesRead: json['pages_read'] ?? 0,
      dailyGoal: json['daily_goal'],
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'pages_read': pagesRead,
    'daily_goal': dailyGoal,
  };

  @override
  String toString() {
    return 'QuranReadingRecord(date: '
        '$date, pagesRead: $pagesRead, dailyGoal: $dailyGoal)';
  }
}
