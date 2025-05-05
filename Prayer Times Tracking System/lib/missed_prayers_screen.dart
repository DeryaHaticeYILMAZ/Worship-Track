import 'package:flutter/material.dart';

class MissedPrayersScreen extends StatefulWidget {
  @override
  _MissedPrayersScreenState createState() => _MissedPrayersScreenState();
}

class _MissedPrayersScreenState extends State<MissedPrayersScreen> {
  List<String> missedPrayers = [
    "Fajr - 10/03/2024",
    "Asr - 12/03/2024",
    "Isha - 15/03/2024",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Missed Prayers"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Missed Prayer List:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: missedPrayers.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(missedPrayers[index]),
                      trailing: IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          setState(() {
                            missedPrayers.removeAt(index);
                          });
                        },
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
