import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/prayer_times.dart';
import '../services/diyanet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HistoricalPrayerTimes extends StatefulWidget {
  const HistoricalPrayerTimes({Key? key}) : super(key: key);

  @override
  _HistoricalPrayerTimesState createState() => _HistoricalPrayerTimesState();
}

class _HistoricalPrayerTimesState extends State<HistoricalPrayerTimes> {
  final DiyanetService _diyanetService = DiyanetService();
  List<PrayerTimes> _historicalPrayerTimes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistoricalPrayerTimes();
  }

  Future<void> _loadHistoricalPrayerTimes() async {
    setState(() => _isLoading = true);
    
    try {
      // Load saved prayer statuses
      final prefs = await SharedPreferences.getInstance();
      final savedStatuses = prefs.getString('prayer_statuses') ?? '{}';
      Map<String, dynamic> statusesMap;
      try {
        statusesMap = Map<String, dynamic>.from(json.decode(savedStatuses));
      } catch (e) {
        print('Error parsing saved statuses: $e');
        statusesMap = {};
      }

      // Get last 7 days of prayer times
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final prayerTimes = await _diyanetService.getHistoricalPrayerTimes(sevenDaysAgo, now);

      // Apply saved statuses to prayer times
      for (var prayerTime in prayerTimes) {
        final dateKey = DateFormat('yyyy-MM-dd').format(prayerTime.date);
        if (statusesMap.containsKey(dateKey)) {
          try {
            final status = Map<String, dynamic>.from(statusesMap[dateKey]);
            prayerTime.fajrPrayed = status['fajr'] ?? false;
            prayerTime.dhuhrPrayed = status['dhuhr'] ?? false;
            prayerTime.asrPrayed = status['asr'] ?? false;
            prayerTime.maghribPrayed = status['maghrib'] ?? false;
            prayerTime.ishaPrayed = status['isha'] ?? false;
          } catch (e) {
            print('Error parsing status for date $dateKey: $e');
          }
        }
      }

      setState(() {
        _historicalPrayerTimes = prayerTimes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _togglePrayerStatus(PrayerTimes prayerTime, String prayer) async {
    setState(() {
      switch (prayer) {
        case 'fajr':
          prayerTime.fajrPrayed = !prayerTime.fajrPrayed;
          break;
        case 'dhuhr':
          prayerTime.dhuhrPrayed = !prayerTime.dhuhrPrayed;
          break;
        case 'asr':
          prayerTime.asrPrayed = !prayerTime.asrPrayed;
          break;
        case 'maghrib':
          prayerTime.maghribPrayed = !prayerTime.maghribPrayed;
          break;
        case 'isha':
          prayerTime.ishaPrayed = !prayerTime.ishaPrayed;
          break;
      }
    });

    try {
      // Save updated statuses
      final prefs = await SharedPreferences.getInstance();
      final savedStatuses = prefs.getString('prayer_statuses') ?? '{}';
      Map<String, dynamic> statusesMap;
      try {
        statusesMap = Map<String, dynamic>.from(json.decode(savedStatuses));
      } catch (e) {
        print('Error parsing saved statuses: $e');
        statusesMap = {};
      }
      
      final dateKey = DateFormat('yyyy-MM-dd').format(prayerTime.date);
      statusesMap[dateKey] = {
        'fajr': prayerTime.fajrPrayed,
        'dhuhr': prayerTime.dhuhrPrayed,
        'asr': prayerTime.asrPrayed,
        'maghrib': prayerTime.maghribPrayed,
        'isha': prayerTime.ishaPrayed,
      };

      await prefs.setString('prayer_statuses', json.encode(statusesMap));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: Namaz durumu kaydedilemedi - $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Namaz Kayıtları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistoricalPrayerTimes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _historicalPrayerTimes.length,
              itemBuilder: (context, index) {
                final prayerTime = _historicalPrayerTimes[index];
                final date = DateFormat('dd MMMM yyyy', 'tr_TR').format(prayerTime.date);
                
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ExpansionTile(
                    title: Text(date),
                    children: [
                      _buildPrayerTile(prayerTime, 'Sabah', 'fajr', prayerTime.fajr, prayerTime.fajrPrayed),
                      _buildPrayerTile(prayerTime, 'Öğle', 'dhuhr', prayerTime.dhuhr, prayerTime.dhuhrPrayed),
                      _buildPrayerTile(prayerTime, 'İkindi', 'asr', prayerTime.asr, prayerTime.asrPrayed),
                      _buildPrayerTile(prayerTime, 'Akşam', 'maghrib', prayerTime.maghrib, prayerTime.maghribPrayed),
                      _buildPrayerTile(prayerTime, 'Yatsı', 'isha', prayerTime.isha, prayerTime.ishaPrayed),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPrayerTile(PrayerTimes prayerTime, String title, String prayer, String time, bool isPrayed) {
    return ListTile(
      title: Text(title),
      subtitle: Text(time),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPrayed ? Icons.check_circle : Icons.cancel,
            color: isPrayed ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _togglePrayerStatus(prayerTime, prayer),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPrayed ? Colors.red : Colors.green,
            ),
            child: Text(
              isPrayed ? 'Kılınmadı' : 'Kılındı',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
} 