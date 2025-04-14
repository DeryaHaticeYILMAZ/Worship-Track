import 'package:flutter/material.dart';

class FastingTrackerScreen extends StatefulWidget {
  @override
  _FastingTrackerScreenState createState() => _FastingTrackerScreenState();
}

class _FastingTrackerScreenState extends State<FastingTrackerScreen> {
  List<Map<String, dynamic>> fastingRecords = [
    {"date": "10/03/2024", "type": "Ramadan", "completed": false},
    {"date": "12/03/2024", "type": "Nafl", "completed": true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Fasting Tracker"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Fasting Records:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: fastingRecords.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text("${fastingRecords[index]["date"]} - ${fastingRecords[index]["type"]}"),
                      trailing: Checkbox(
                        value: fastingRecords[index]["completed"],
                        onChanged: (bool? value) {
                          setState(() {
                            fastingRecords[index]["completed"] = value;
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
