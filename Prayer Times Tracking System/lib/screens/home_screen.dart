import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/prayer_service.dart';
import '../services/prayer_status_service.dart';
import '../models/prayer_times.dart';
import '../models/prayer_status.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PrayerService _prayerService = PrayerService();
  final PrayerStatusService _prayerStatusService = PrayerStatusService();
  PrayerTimes? _prayerTimes;
  PrayerStatus? _todayStatus;
  bool _isLoading = true;
  String _nextPrayer = "";
  String _nextPrayerTime = "";

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final prayerTimes = await _prayerService.getPrayerTimes();
      final nextPrayerInfo = prayerTimes.getNextPrayer().split(' - ');
      final todayStatus = await _prayerStatusService.getPrayerStatusForDate(DateTime.now());

      setState(() {
        _prayerTimes = prayerTimes;
        _todayStatus = todayStatus;
        _nextPrayer = nextPrayerInfo[0];
        _nextPrayerTime = nextPrayerInfo[1];
        _isLoading = false;
      });
    } catch (e) {
      print('Namaz vakitleri yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Namaz vakitleri yüklenemedi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _togglePrayerStatus(String prayer) async {
    if (_todayStatus == null) {
      _todayStatus = PrayerStatus(date: DateTime.now());
    }

    setState(() {
      switch (prayer.toLowerCase()) {
        case 'fajr':
          _todayStatus!.fajrPrayed = !_todayStatus!.fajrPrayed;
          break;
        case 'dhuhr':
          _todayStatus!.dhuhrPrayed = !_todayStatus!.dhuhrPrayed;
          break;
        case 'asr':
          _todayStatus!.asrPrayed = !_todayStatus!.asrPrayed;
          break;
        case 'maghrib':
          _todayStatus!.maghribPrayed = !_todayStatus!.maghribPrayed;
          break;
        case 'isha':
          _todayStatus!.ishaPrayed = !_todayStatus!.ishaPrayed;
          break;
      }
    });

    try {
      await _prayerStatusService.updatePrayerStatus(_todayStatus!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Namaz durumu güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Namaz durumu güncellenemedi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
            icon: Icon(Icons.refresh),
            onPressed: _loadPrayerTimes,
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
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
                            "$_nextPrayer - $_nextPrayerTime",
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
                            label: Text("Namaz Kıldınız mı?"),
                            onPressed: () => _togglePrayerStatus(_nextPrayer),
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
                      children: _prayerTimes == null
                          ? []
                          : [
                              prayerTile("Fajr", _prayerTimes!.fajr, _todayStatus?.fajrPrayed ?? false),
                              prayerTile("Dhuhr", _prayerTimes!.dhuhr, _todayStatus?.dhuhrPrayed ?? false),
                              prayerTile("Asr", _prayerTimes!.asr, _todayStatus?.asrPrayed ?? false),
                              prayerTile("Maghrib", _prayerTimes!.maghrib, _todayStatus?.maghribPrayed ?? false),
                              prayerTile("Isha", _prayerTimes!.isha, _todayStatus?.ishaPrayed ?? false),
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
      onTap: () => _togglePrayerStatus(name),
    );
  }
} 