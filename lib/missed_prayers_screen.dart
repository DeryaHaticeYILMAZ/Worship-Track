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

  // New fields for manual completion
  DateTime selectedDate = DateTime.now();
  String selectedPrayer = 'Fajr';
  final List<String> prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  bool isCompleting = false;

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
        missedPrayers = List<Map<String, dynamic>>.from(data['missed_prayers'])
            .where((prayer) => prayer['completed'] == 0)
            .toList()
          ..sort((a, b) {
            final dateA = DateFormat('EEE, dd MMM yyyy HH:mm:ss zzz', 'en_US').parse(a['date']);
            final dateB = DateFormat('EEE, dd MMM yyyy HH:mm:ss zzz', 'en_US').parse(b['date']);
            return dateB.compareTo(dateA); // büyükten küçüğe
          });
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
        Uri.parse('http://10.0.2.2:5000/complete_missed_prayer'),
        body: {
          'email': userEmail!,
          'prayer_name': prayerName,
          'date': formattedDate,
        },
      );

      print("Sunucudan gelen cevap: \\${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          missedPrayers.removeWhere(
                (prayer) => prayer['prayer_name'] == prayerName && prayer['date'] == rawDate,
          );
        });
        Navigator.pop(context, true);
      } else {
        print('Mark complete failed: \\${response.body}');
      }
    } catch (e) {
      print('Date parse hatası: $e');
    }
  }

  Future<void> markAnyPrayerCompleted() async {
    setState(() { isCompleting = true; });
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/complete_missed_prayer'),
      body: {
        'email': userEmail ?? '',
        'prayer_name': selectedPrayer,
        'date': formattedDate,
      },
    );
    setState(() { isCompleting = false; });
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked $selectedPrayer on $formattedDate as completed!')),
      );
      fetchMissedPrayers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as completed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: "Back",
          ),
          title: Text(
            'Missed Prayers',
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
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 100,
                          maxWidth: constraints.maxWidth < 350 ? constraints.maxWidth : 150,
                        ),
                        child: InkWell(
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() { selectedDate = picked; });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Select Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 80,
                          maxWidth: constraints.maxWidth < 350 ? constraints.maxWidth : 120,
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedPrayer,
                          items: prayers.map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() { selectedPrayer = val; });
                          },
                          decoration: InputDecoration(
                            labelText: 'Prayer',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 100,
                          maxWidth: constraints.maxWidth < 350 ? constraints.maxWidth : 140,
                        ),
                        child: ElevatedButton(
                          onPressed: isCompleting ? null : markAnyPrayerCompleted,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF20613A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            textStyle: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          child: isCompleting
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('Completed', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: missedPrayers.isEmpty
                  ? Center(child: Text("No missed prayers!"))
                  : ListView.builder(
                      itemCount: missedPrayers.length,
                      itemBuilder: (context, index) {
                        final prayer = missedPrayers[index];
                        return ListTile(
                          leading: Icon(Icons.error_outline, color: Color(0xFFC9A14A)),
                          title: Text(prayer['prayer_name'], style: TextStyle(color: Color(0xFF20613A), fontWeight: FontWeight.bold)),
                          subtitle: Text("Date: \\${prayer['date']}"),
                          trailing: IconButton(
                            icon: Icon(Icons.check, color: Color(0xFF20613A)),
                            tooltip: "Mark as prayed",
                            onPressed: () => markPrayerCompleted(
                              prayer['prayer_name'],
                              prayer['date'],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
