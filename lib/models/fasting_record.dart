import 'package:flutter/material.dart';

class FastingRecord {
  final DateTime date;
  bool completed;

  FastingRecord({
    required this.date,
    this.completed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'completed': completed,
    };
  }

  factory FastingRecord.fromJson(Map<String, dynamic> json) {
    return FastingRecord(
      date: DateTime.parse(json['date']),
      completed: json['completed'],
    );
  }
} 