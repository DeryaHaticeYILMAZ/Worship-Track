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

  @override
  void initState() {
    super.initState();
    initUserAndLoad();
  }

  Future<void> initUserAndLoad() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userEmail = prefs.getString('userEmail');
    fetchPrayersForDate(_focusedDay);
  }

  Future<void> fetchPrayersForDate(DateTime date) async {
    final formatted = DateFormat('yyyy-MM-dd').format(date);
    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/missed_prayers?email=$userEmail'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final allPrayers = List<Map<String, dynamic>>.from(data['missed_prayers']);
      setState(() {
        selectedDayPrayers = allPrayers.where((entry) => entry['date'].startsWith(formatted)).toList();
      });
    } else {
      print("Veri çekme hatası: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Prayer History by Date"),
        backgroundColor: Colors.blue.shade800,
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
          ),
          Expanded(
            child: selectedDayPrayers.isEmpty
                ? Center(child: Text("No missed prayers for this day."))
                : ListView.builder(
              itemCount: selectedDayPrayers.length,
              itemBuilder: (context, index) {
                final item = selectedDayPrayers[index];
                return ListTile(
                  leading: Icon(Icons.error_outline, color: Colors.red),
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
