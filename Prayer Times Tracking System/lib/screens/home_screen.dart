import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/prayer_status_service.dart';
import '../models/prayer_times.dart';
import '../models/prayer_status.dart';
import '../services/diyanet_service.dart';
import 'historical_prayer_times.dart';
import 'missed_prayers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PrayerStatusService _prayerStatusService = PrayerStatusService();
  final DiyanetService _diyanetService = DiyanetService();
  PrayerTimes? _prayerTimes;
  PrayerStatus? _todayStatus;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final prayerTimes = await _diyanetService.getPrayerTimes();
      final todayStatus = await _prayerStatusService.getPrayerStatusForDate(DateTime.now());

      setState(() {
        _prayerTimes = prayerTimes;
        _todayStatus = todayStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Namaz vakitleri yüklenirken bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePrayerStatus(String prayer) async {
    if (_todayStatus == null) {
      _todayStatus = PrayerStatus(date: DateTime.now());
    }

    switch (prayer) {
      case 'Sabah':
        _todayStatus!.fajrPrayed = !_todayStatus!.fajrPrayed;
        break;
      case 'Öğle':
        _todayStatus!.dhuhrPrayed = !_todayStatus!.dhuhrPrayed;
        break;
      case 'İkindi':
        _todayStatus!.asrPrayed = !_todayStatus!.asrPrayed;
        break;
      case 'Akşam':
        _todayStatus!.maghribPrayed = !_todayStatus!.maghribPrayed;
        break;
      case 'Yatsı':
        _todayStatus!.ishaPrayed = !_todayStatus!.ishaPrayed;
        break;
    }

    try {
      await _prayerStatusService.updatePrayerStatus(_todayStatus!);
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  bool _isPrayerPrayed(String prayer) {
    if (_todayStatus == null) return false;
    switch (prayer) {
      case 'Sabah':
        return _todayStatus!.fajrPrayed;
      case 'Öğle':
        return _todayStatus!.dhuhrPrayed;
      case 'İkindi':
        return _todayStatus!.asrPrayed;
      case 'Akşam':
        return _todayStatus!.maghribPrayed;
      case 'Yatsı':
        return _todayStatus!.ishaPrayed;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Namaz Vakitleri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrayerTimes,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Namaz Vakitleri',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Geçmiş Namazlar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoricalPrayerTimes(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded),
              title: const Text('Kılınmayan Namazlar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MissedPrayersScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPrayerTimes,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _prayerTimes == null
                  ? const Center(child: Text('Namaz vakitleri yüklenemedi'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bugün: ${DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(_prayerTimes!.date)}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 24),
                          _buildPrayerCard('Sabah', _prayerTimes!.fajr),
                          _buildPrayerCard('Öğle', _prayerTimes!.dhuhr),
                          _buildPrayerCard('İkindi', _prayerTimes!.asr),
                          _buildPrayerCard('Akşam', _prayerTimes!.maghrib),
                          _buildPrayerCard('Yatsı', _prayerTimes!.isha),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MissedPrayersScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.warning_amber_rounded),
                              label: const Text('Kılınmayan Namazlar'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                textStyle: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildPrayerCard(String name, String time) {
    final isPrayed = _isPrayerPrayed(name);
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: Text(name),
        subtitle: Text(time),
        trailing: IconButton(
          icon: Icon(
            isPrayed ? Icons.check_circle : Icons.check_circle_outline,
            color: isPrayed ? Colors.green : Colors.grey,
          ),
          onPressed: () => _togglePrayerStatus(name),
        ),
      ),
    );
  }
} 