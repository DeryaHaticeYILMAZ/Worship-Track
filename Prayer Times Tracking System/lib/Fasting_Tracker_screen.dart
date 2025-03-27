import 'package:flutter/material.dart';
import 'services/database_service.dart';

class FastingTrackerScreen extends StatefulWidget {
  @override
  _FastingTrackerScreenState createState() => _FastingTrackerScreenState();
}

class _FastingTrackerScreenState extends State<FastingTrackerScreen> {
  List<Map<String, dynamic>> fastingRecords = [];
  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _loadFastingRecords();
  }

  Future<void> _loadFastingRecords() async {
    try {
      final records = await _databaseService.getFastingRecords();
      setState(() {
        fastingRecords = records;
      });
    } catch (e) {
      print('Kayıtları yükleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıtlar yüklenirken bir hata oluştu')),
      );
    }
  }

  Future<void> _updateFastingRecord(int id, bool completed) async {
    try {
      await _databaseService.updateFastingRecord(id, completed);
      await _loadFastingRecords();
    } catch (e) {
      print('Kayıt güncelleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt güncellenirken bir hata oluştu')),
      );
    }
  }

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
                  final record = fastingRecords[index];
                  return Card(
                    child: ListTile(
                      title: Text("${record["date"]} - ${record["type"]}"),
                      trailing: Checkbox(
                        value: record["completed"],
                        onChanged: (bool? value) {
                          if (value != null) {
                            _updateFastingRecord(record["id"], value);
                          }
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Yeni kayıt ekleme dialogu buraya eklenecek
        },
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _databaseService.close();
    super.dispose();
  }
}
