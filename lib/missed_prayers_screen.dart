import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MissedPrayersScreen extends StatefulWidget {
  @override
  _MissedPrayersScreenState createState() => _MissedPrayersScreenState();
}

class _MissedPrayersScreenState extends State<MissedPrayersScreen> {
  List<Map<String, dynamic>> missedPrayers = [];
  String? userEmail;

  @override
  void initState() {
    super.initState();
    loadEmailAndFetch();
  }

  Future<void> loadEmailAndFetch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userEmail = prefs.getString('userEmail');
    fetchMissedPrayers();
  }

  Future<void> fetchMissedPrayers() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/missed_prayers?email=$userEmail'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        missedPrayers = List<Map<String, dynamic>>.from(data['missed_prayers']);
      });
    } else {
      print('Missed prayers fetch error: ${response.body}');
    }
  }

  Future<void> markPrayerCompleted(String prayerName, String rawDate) async {
    try {
      DateTime parsedDate = DateFormat('EEE, dd MMM yyyy HH:mm:ss zzz', 'en_US').parse(rawDate);
      final formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);

      print("--- GÖNDERİLEN ---");
      print("email: $userEmail");
      print("prayer_name: $prayerName");
      print("date: $formattedDate");

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/missed_prayers'),
        body: {
          'email': userEmail!,
          'prayer_name': prayerName,
          'date': formattedDate,
        },
      );

      print("Sunucudan gelen cevap: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          missedPrayers.removeWhere(
                (prayer) => prayer['prayer_name'] == prayerName && prayer['date'] == rawDate,
          );
        });
      } else {
        print('Mark complete failed: ${response.body}');
      }
    } catch (e) {
      print('Date parse hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Missed Prayers'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: missedPrayers.isEmpty
          ? Center(child: Text("No missed prayers!"))
          : ListView.builder(
        itemCount: missedPrayers.length,
        itemBuilder: (context, index) {
          final prayer = missedPrayers[index];
          return ListTile(
            leading: Icon(Icons.error_outline, color: Colors.red),
            title: Text(prayer['prayer_name']),
            subtitle: Text("Date: ${prayer['date']}"),
            trailing: IconButton(
              icon: Icon(Icons.check, color: Colors.green),
              tooltip: "Mark as prayed",
              onPressed: () => markPrayerCompleted(
                prayer['prayer_name'],
                prayer['date'],
              ),
            ),
          );
        },
      ),
    );
  }
}