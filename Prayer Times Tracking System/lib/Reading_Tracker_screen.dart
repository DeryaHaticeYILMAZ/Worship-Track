import 'package:flutter/material.dart';

class ReadingTrackerScreen extends StatefulWidget {
  @override
  _ReadingTrackerScreenState createState() => _ReadingTrackerScreenState();
}

class _ReadingTrackerScreenState extends State<ReadingTrackerScreen> {
  List<Map<String, dynamic>> readings = [
    {"name": "Surah Al-Fatiha", "date": "10/03/2024", "completed": true},
    {"name": "Surah Yasin", "date": "12/03/2024", "completed": false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reading Tracker"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Reading List:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: readings.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text("${readings[index]["name"]} - ${readings[index]["date"]}"),
                      trailing: Checkbox(
                        value: readings[index]["completed"],
                        onChanged: (bool? value) {
                          setState(() {
                            readings[index]["completed"] = value;
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
