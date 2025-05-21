import 'package:flutter/material.dart';
import '../services/prayer_times_service.dart';
import '../services/notification_service.dart';
import '../models/prayer_times_response.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PrayerTimesService _prayerTimesService = PrayerTimesService();
  final NotificationService _notificationService = NotificationService();
  PrayerTimesResponse? _prayerTimes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadPrayerTimes();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    _scheduleNextPrayerNotification();
  }

  Future<void> _scheduleNextPrayerNotification() async {
    try {
      final nextPrayer = await _prayerTimesService.getNextPrayerTime();
      if (nextPrayer != null) {
        await _notificationService.schedulePrayerNotification(
          prayerName: nextPrayer['name'],
          prayerTime: nextPrayer['time'],
        );
      }
    } catch (e) {
      print('Failed to schedule notification: $e');
    }
  }

  Future<void> _loadPrayerTimes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prayerTimes = await _prayerTimesService.getPrayerTimes();
      setState(() {
        _prayerTimes = prayerTimes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Namaz Vakitleri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () async {
              await _notificationService.showTestNotification();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prayerTimes == null
              ? const Center(child: Text('Namaz vakitleri yüklenemedi'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    PrayerTimeCard(
                      title: 'İmsak',
                      time: _prayerTimes!.data.timings.fajr,
                    ),
                    PrayerTimeCard(
                      title: 'Öğle',
                      time: _prayerTimes!.data.timings.dhuhr,
                    ),
                    PrayerTimeCard(
                      title: 'İkindi',
                      time: _prayerTimes!.data.timings.asr,
                    ),
                    PrayerTimeCard(
                      title: 'Akşam',
                      time: _prayerTimes!.data.timings.maghrib,
                    ),
                    PrayerTimeCard(
                      title: 'Yatsı',
                      time: _prayerTimes!.data.timings.isha,
                    ),
                  ],
                ),
    );
  }
}

class PrayerTimeCard extends StatelessWidget {
  final String title;
  final String time;

  const PrayerTimeCard({
    super.key,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(title),
        trailing: Text(time),
      ),
    );
  }
} 