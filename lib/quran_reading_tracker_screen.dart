import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/quran_reading_service.dart';
import 'models/quran_reading_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranReadingTrackerScreen extends StatefulWidget {
  const QuranReadingTrackerScreen({Key? key}) : super(key: key);

  @override
  State<QuranReadingTrackerScreen> createState() => _QuranReadingTrackerScreenState();
}

class _QuranReadingTrackerScreenState extends State<QuranReadingTrackerScreen> {
  final QuranReadingService _service = QuranReadingService();
  String? _userEmail;
  int _dailyGoal = 1;
  bool _loading = true;
  Map<DateTime, QuranReadingRecord> _records = {};
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 14));
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    setState(() => _loading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('userEmail');
    if (email == null) {
      setState(() { _userEmail = null; _loading = false; });
      return;
    }
    _userEmail = email;
    await _loadGoalAndRecords();
  }

  Future<void> _loadGoalAndRecords() async {
    if (_userEmail == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final records = await _service.getReadingRecords(_userEmail!);
      print("Backend'den gelen records: $records");
      setState(() {
        _records = {
          for (var r in records)
            DateTime(r.date.year, r.date.month, r.date.day): r
        };
        _loading = false;
      });
    } catch (e) {
      print('Quran Reading Tracker loading error: $e');
      setState(() => _loading = false);
    }
  }


  Future<void> _editDailyGoal(DateTime day) async {
    if (_userEmail == null) return;
    if (day.isBefore(DateTime.now().subtract(Duration(days: 1)))) return;

    final record = _records[day];
    final controller = TextEditingController(text: record?.dailyGoal?.toString() ?? _dailyGoal.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Goal for ${DateFormat('d MMM yyyy').format(day)}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Daily Goal'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      try {
        await _service.setDailyGoal(_userEmail!, day, result);
        await _loadGoalAndRecords();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hedef kaydedilemedi: ' + e.toString())),
          );
        }
      }
    }
  }

  Future<void> _askAndSetPagesRead(DateTime day, bool completed) async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Kaç sayfa okudun?"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Pages read'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              final pages = int.tryParse(controller.text);
              if (pages != null && pages >= 0) {
                Navigator.pop(context, pages);
              }
            },
            child: Text('Save'),
          )
        ],
      ),
    );
    if (result != null) {
      final record = _records[day];
      final goal = record?.dailyGoal ?? _dailyGoal;
      final pages = completed ? result : 0;
      await _service.setPagesReadAndGoal(_userEmail!, day, pages, goal);
      await _loadGoalAndRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _endDate.difference(_startDate).inDays + 1;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: "Back",
        ),
        title: Text(
          'Quran Reading Tracker',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Color(0xFF20613A),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.95,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: days,
              itemBuilder: (context, index) {
                final day = _startDate.add(Duration(days: index));
                final normalizedDay = DateTime(day.year, day.month, day.day);
                final record = _records[normalizedDay];
                final pagesRead = record?.pagesRead ?? 0;
                final dayGoal = record?.dailyGoal ?? _dailyGoal;
                final status = pagesRead >= dayGoal ? '✅' : '❌';
                final isEditable = !normalizedDay.isBefore(DateTime.now());

                return GestureDetector(
                  onTap: isEditable ? () => _editDailyGoal(normalizedDay) : null,
                  child: Card(
                    color: Colors.white,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FittedBox(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              DateFormat('d MMM').format(day),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            Text('Goal: $dayGoal', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            Text('$pagesRead/$dayGoal', style: const TextStyle(fontSize: 12)),
                            Text(status, style: TextStyle(fontSize: 20)),
                            if (dayGoal > 0 && isEditable)
                              FittedBox(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.check_circle, color: Colors.green, size: 20),
                                      onPressed: () => _askAndSetPagesRead(normalizedDay, true),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.cancel, color: Colors.red, size: 20),
                                      onPressed: () => _askAndSetPagesRead(normalizedDay, false),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
