import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String nextPrayer = "Fajr";
  String nextPrayerTime = "05:15 AM";

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
                      "Next Prayer",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "$nextPrayer - $nextPrayerTime",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(Icons.check_circle_outline),
                      label: Text("Did you pray?"),
                      onPressed: () {
                        // Kullanıcıdan evet/hayır sorusu göster
                      },
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            Text(
              "Today's Prayers",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  prayerTile("Fajr", "05:15 AM", true),
                  prayerTile("Dhuhr", "12:30 PM", false),
                  prayerTile("Asr", "15:45 PM", false),
                  prayerTile("Maghrib", "18:20 PM", false),
                  prayerTile("Isha", "20:00 PM", false),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget prayerTile(String name, String time, bool completed) {
    return ListTile(
      leading: Icon(
        completed ? Icons.check_circle : Icons.cancel,
        color: completed ? Colors.green : Colors.red,
      ),
      title: Text(name),
      subtitle: Text(time),
      trailing: Icon(Icons.keyboard_arrow_right),
      onTap: () {
        // Detay veya onay ekranı açılabilir
      },
    );
  }
}
