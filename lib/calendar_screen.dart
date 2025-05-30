import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? userEmail;
  List<Map<String, dynamic>> selectedDayPrayers = [];
  Map<DateTime, List<Map<String, dynamic>>> _missedPrayersByDate = {};

  @override
  void initState() {
    super.initState();
    initUserAndLoad();
  }

  Future<void> initUserAndLoad() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userEmail = prefs.getString('userEmail');
    await fetchAllMissedPrayers();
  }

  Future<void> fetchAllMissedPrayers() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/missed_prayers?email=$userEmail'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final allPrayers = List<Map<String, dynamic>>.from(data['missed_prayers']);

      Map<DateTime, List<Map<String, dynamic>>> prayersByDate = {};
      
      for (var prayer in allPrayers) {
        final rawDate = prayer['date'];
        final parsed = DateFormat("EEE, dd MMM yyyy HH:mm:ss zzz", 'en_US').parse(rawDate);
        final date = DateTime(parsed.year, parsed.month, parsed.day);
        
        if (!prayersByDate.containsKey(date)) {
          prayersByDate[date] = [];
        }
        prayersByDate[date]!.add(prayer);
      }

      setState(() {
        _missedPrayersByDate = prayersByDate;
      });
    } else {
      print("Veri çekme hatası: ${response.body}");
    }
  }

  Future<void> fetchPrayersForDate(DateTime date) async {
    final formatted = DateFormat('yyyy-MM-dd').format(date);
    print("===> Seçilen gün: $formatted");
    
    setState(() {
      selectedDayPrayers = _missedPrayersByDate[DateTime(date.year, date.month, date.day)] ?? [];
    });
  }

  bool _hasMissedPrayers(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    final prayers = _missedPrayersByDate[date] ?? [];
    return prayers.any((prayer) => prayer['completed'] != 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: "Back",
        ),
        title: Text(
          'Prayer History by Date',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Color(0xFF20613A),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
              fetchPrayersForDate(selected);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (_hasMissedPrayers(date)) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          Expanded(
            child: selectedDayPrayers.isEmpty
                ? Center(child: Text("No missed prayers for this day."))
                : ListView.builder(
              itemCount: selectedDayPrayers.length,
              itemBuilder: (context, index) {
                final item = selectedDayPrayers[index];
                final isCompleted = item['completed'] == 1;
                final iconColor = isCompleted ? Color(0xFFFFD54F) : Colors.red;

                return ListTile(
                  leading: Icon(Icons.circle, color: iconColor, size: 14),
                  title: Text(item['prayer_name']),
                  subtitle: Text("Date: ${item['date']}"),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}