import 'package:flutter/material.dart';
import '../services/prayer_tracking_service.dart';
import '../models/prayer_status.dart';

class MissedPrayersScreen extends StatefulWidget {
  @override
  _MissedPrayersScreenState createState() => _MissedPrayersScreenState();
}

class _MissedPrayersScreenState extends State<MissedPrayersScreen> {
  final PrayerTrackingService _prayerTrackingService = PrayerTrackingService();
  List<PrayerStatus> _missedPrayers = [];

  @override
  void initState() {
    super.initState();
    _loadMissedPrayers();
  }

  Future<void> _loadMissedPrayers() async {
    final allPrayers = await _prayerTrackingService.getPrayerStatus();
    setState(() {
      _missedPrayers = allPrayers.where((prayer) => prayer.isMissed).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Missed Prayers'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: _missedPrayers.isEmpty
          ? Center(
              child: Text(
                'No missed prayers',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _missedPrayers.length,
              itemBuilder: (context, index) {
                final prayer = _missedPrayers[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      prayer.prayerName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Missed on ${prayer.prayerTime.toString().split(' ')[0]}',
                      style: TextStyle(color: Colors.red),
                    ),
                    trailing: Icon(Icons.error_outline, color: Colors.red),
                  ),
                );
              },
            ),
    );
  }
} 