import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, String> prayerTimes = {};
  Map<String, bool?> prayerStatus = {
    'Fajr': null,
    'Dhuhr': null,
    'Asr': null,
    'Maghrib': null,
    'Isha': null,
  };

  String? userEmail;

  @override
  void initState() {
    super.initState();
    loadEmailAndPrayerTimes();
  }

  Future<void> loadEmailAndPrayerTimes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail');
    });
    loadManualPrayerTimes();
  }

  void loadManualPrayerTimes() {
    setState(() {
      prayerTimes = {
        'Fajr': '05:15',
        'Dhuhr': '12:30',
        'Asr': '15:45',
        'Maghrib': '18:20',
        'Isha': '20:00',
      };
    });
  }

  void askPrayerStatus(String prayerName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Did you pray $prayerName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Yes"),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        prayerStatus[prayerName] = result;
      });

      if (!result) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await http.post(
          Uri.parse('http://10.0.2.2:5000/missed_prayers'),
          body: {
            'email': userEmail!,
            'prayer_name': prayerName,
            'date': today,
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Prayer Times"),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('isLoggedIn');
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      "Today's Prayers",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 10),
                    ...prayerTimes.entries.map((entry) {
                      final name = entry.key;
                      final time = entry.value;
                      final status = prayerStatus[name];

                      return ListTile(
                        title: Text(name),
                        subtitle: Text(time),
                        leading: Icon(
                          status == null
                              ? Icons.help_outline
                              : status
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: status == null
                              ? Colors.grey
                              : status!
                              ? Colors.green
                              : Colors.red,
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => askPrayerStatus(name),
                          child: Text("Did you pray?"),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/missed-prayers');
              },
              icon: Icon(Icons.error, color: Colors.white),
              label: Text('Missed Prayers'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/calendar');
              },
              icon: Icon(Icons.calendar_today, color: Colors.white),
              label: Text('Prayer Calendar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}