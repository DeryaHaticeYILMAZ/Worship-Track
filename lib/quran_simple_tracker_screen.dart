import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DailyQuranRecord {
  final DateTime date;
  int goal;
  int pagesRead;

  DailyQuranRecord({
    required this.date,
    required this.goal,
    required this.pagesRead,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'goal': goal,
    'pagesRead': pagesRead,
  };

  factory DailyQuranRecord.fromJson(Map<String, dynamic> json) => DailyQuranRecord(
    date: DateTime.parse(json['date']),
    goal: json['goal'],
    pagesRead: json['pagesRead'],
  );
}

class QuranSimpleTrackerScreen extends StatefulWidget {
  const QuranSimpleTrackerScreen({Key? key}) : super(key: key);

  @override
  State<QuranSimpleTrackerScreen> createState() => _QuranSimpleTrackerScreenState();
}

class _QuranSimpleTrackerScreenState extends State<QuranSimpleTrackerScreen> {
  int _goal = 0;
  int _pagesRead = 0;
  bool _loaded = false;
  late TextEditingController _goalController;
  late TextEditingController _pagesReadController;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController();
    _pagesReadController = TextEditingController();
    _loadToday();
  }

  Future<void> _loadToday() async {
    final today = DateTime.now();
    final record = await loadRecord(today);
    setState(() {
      _goal = record?.goal ?? 0;
      _pagesRead = record?.pagesRead ?? 0;
      _goalController.text = _goal > 0 ? _goal.toString() : '';
      _pagesReadController.text = _pagesRead > 0 ? _pagesRead.toString() : '';
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final today = DateTime.now();
    final goalText = _goalController.text.trim();
    final pagesText = _pagesReadController.text.trim();
    if (goalText.isEmpty || pagesText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen her iki alanı da doldurunuz!')),
      );
      return;
    }
    final goal = int.tryParse(goalText);
    final pages = int.tryParse(pagesText);
    if (goal == null || pages == null || goal <= 0 || pages < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen geçerli bir sayı giriniz!')),
      );
      return;
    }
    final record = DailyQuranRecord(date: today, goal: goal, pagesRead: pages);
    await saveRecord(record);
    setState(() {
      _goal = goal;
      _pagesRead = pages;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved!')),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    _pagesReadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final metGoal = _pagesRead >= _goal && _goal > 0;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: "Back",
        ),
        title: Text(
          'Quran Simple Tracker',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Color(0xFF20613A),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set your goal for today:'),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Goal (pages)'),
              controller: _goalController,
            ),
            const SizedBox(height: 16),
            const Text('How many pages did you read?'),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Pages read'),
              controller: _pagesReadController,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Result:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Icon(
              metGoal ? Icons.check_circle : Icons.cancel,
              color: metGoal ? Colors.green : Colors.red,
              size: 48,
            ),
            Text(
              metGoal ? 'Goal met!' : 'Goal not met',
              style: TextStyle(fontSize: 18, color: metGoal ? Colors.green : Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

// Persistence helpers
Future<void> saveRecord(DailyQuranRecord record) async {
  final prefs = await SharedPreferences.getInstance();
  final key = record.date.toIso8601String().split('T')[0];
  prefs.setString(key, jsonEncode(record.toJson()));
}

Future<DailyQuranRecord?> loadRecord(DateTime date) async {
  final prefs = await SharedPreferences.getInstance();
  final key = date.toIso8601String().split('T')[0];
  final jsonString = prefs.getString(key);
  if (jsonString == null) return null;
  return DailyQuranRecord.fromJson(jsonDecode(jsonString));
} 