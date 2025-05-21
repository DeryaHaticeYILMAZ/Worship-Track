import 'package:flutter/material.dart';
import 'services/fasting_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class FastingTrackerScreen extends StatefulWidget {
  const FastingTrackerScreen({Key? key}) : super(key: key);

  @override
  State<FastingTrackerScreen> createState() => _FastingTrackerScreenState();
}

class _FastingTrackerScreenState extends State<FastingTrackerScreen> {
  final FastingService _fastingService = FastingService();
  String? _userEmail;
  bool _loading = true;
  Map<DateTime, bool> _fastingDays = {};
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    // 2025 Ramazan: 1 Mart 2025 - 30 Mart 2025
    _startDate = DateTime(2025, 3, 1);
    _endDate = DateTime(2025, 3, 30);
    _loadUserAndFastingRecords();
  }

  Future<void> _loadUserAndFastingRecords() async {
    setState(() { _loading = true; });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('userEmail');
    if (email == null) {
      setState(() { _userEmail = null; _loading = false; });
      return;
    }
    _userEmail = email;
    await _loadFastingRecords();
  }

  Future<void> _loadFastingRecords() async {
    if (_userEmail == null) {
      setState(() { _loading = false; });
      return;
    }
    try {
      final records = await _fastingService.getFastingRecords(_userEmail!);
      Map<DateTime, bool> fastingMap = {
        for (var record in records)
          DateTime(record.date.year, record.date.month, record.date.day): record.completed
      };
      setState(() {
        _fastingDays = fastingMap;
        _loading = false;
      });
    } catch (e) {
      print('Fasting günleri yüklenirken hata: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _toggleFastingDay(DateTime day) async {
    if (_userEmail == null) return;
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final currentState = _fastingDays[normalizedDay] ?? false;
    
    try {
      setState(() { _loading = true; });
      await _fastingService.updateFastingRecord(_userEmail!, normalizedDay, !currentState);
      await _loadFastingRecords();
    } catch (e) {
      print('Fasting günü güncellenirken hata: $e');
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int dayCount = _endDate.difference(_startDate).inDays + 1;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: EdgeInsets.only(left: 8),
          child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
        ),
        title: Text(
          'Ramadan 2025 Fasting ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 0.5),
        ),
        backgroundColor: Color(0xFF20613A),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              itemCount: dayCount,
              itemBuilder: (context, index) {
                final day = _startDate.add(Duration(days: index));
                final normalizedDay = DateTime(day.year, day.month, day.day);
                final isFasted = _fastingDays.entries.any((entry) =>
                  entry.key.year == normalizedDay.year &&
                  entry.key.month == normalizedDay.month &&
                  entry.key.day == normalizedDay.day &&
                  entry.value == true
                );
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isFasted ? Colors.green : Colors.red,
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('d MMMM yyyy').format(day)),
                        SizedBox(height: 4),
                        Text(
                          isFasted ? '✅ Fasted' : '❌ Not fasted',
                          style: TextStyle(
                            color: isFasted ? Colors.green : Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        isFasted ? Icons.check_circle : Icons.cancel,
                        color: isFasted ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      onPressed: _loading ? null : () => _toggleFastingDay(day),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
