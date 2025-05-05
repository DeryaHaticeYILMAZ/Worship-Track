import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/prayer_times.dart';
import '../models/prayer_status.dart';
import '../services/prayer_service.dart';
import '../services/prayer_status_service.dart';
import 'historical_prayer_times_screen.dart';
import 'missed_prayers_screen.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({Key? key}) : super(key: key);

  @override
  _PrayerTimesScreenState createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final PrayerService _prayerService = PrayerService();
  final PrayerStatusService _prayerStatusService = PrayerStatusService();
  PrayerTimes? _prayerTimes;
  bool _isLoading = true;

  // Define theme colors
  static const primaryColor = Color(0xFF1E88E5);
  static const accentColor = Color(0xFF64B5F6);
  static const backgroundColor = Color(0xFFF5F5F5);
  static const cardColor = Colors.white;
  static const textColor = Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    setState(() => _isLoading = true);
    try {
      final prayerTimes = await _prayerService.getPrayerTimes();
      
      // Load prayer status from database
      final status = await _prayerStatusService.getPrayerStatusForDate(prayerTimes.date);
      if (status != null) {
        prayerTimes.fajrPrayed = status.fajrPrayed;
        prayerTimes.dhuhrPrayed = status.dhuhrPrayed;
        prayerTimes.asrPrayed = status.asrPrayed;
        prayerTimes.maghribPrayed = status.maghribPrayed;
        prayerTimes.ishaPrayed = status.ishaPrayed;
      }

      setState(() {
        _prayerTimes = prayerTimes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _togglePrayerStatus(String prayer) async {
    if (_prayerTimes == null) return;

    setState(() {
      switch (prayer) {
        case 'fajr':
          _prayerTimes!.fajrPrayed = !_prayerTimes!.fajrPrayed;
          break;
        case 'dhuhr':
          _prayerTimes!.dhuhrPrayed = !_prayerTimes!.dhuhrPrayed;
          break;
        case 'asr':
          _prayerTimes!.asrPrayed = !_prayerTimes!.asrPrayed;
          break;
        case 'maghrib':
          _prayerTimes!.maghribPrayed = !_prayerTimes!.maghribPrayed;
          break;
        case 'isha':
          _prayerTimes!.ishaPrayed = !_prayerTimes!.ishaPrayed;
          break;
      }
    });

    try {
      // Save prayer status to database
      final status = PrayerStatus(
        date: _prayerTimes!.date,
        fajrPrayed: _prayerTimes!.fajrPrayed,
        dhuhrPrayed: _prayerTimes!.dhuhrPrayed,
        asrPrayed: _prayerTimes!.asrPrayed,
        maghribPrayed: _prayerTimes!.maghribPrayed,
        ishaPrayed: _prayerTimes!.ishaPrayed,
      );
      
      await _prayerStatusService.updatePrayerStatus(status);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _prayerTimes!.isPrayerPrayed(prayer) ? 'Namaz kılındı olarak işaretlendi' : 'Namaz kılınmadı olarak işaretlendi'
            ),
            backgroundColor: _prayerTimes!.isPrayerPrayed(prayer) ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Namaz durumu güncellenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: backgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: primaryColor,
                image: DecorationImage(
                  image: AssetImage('assets/images/mosque.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    primaryColor.withOpacity(0.6),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Namaz Takip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'İbadetlerinizi takip edin',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.check_circle_outline, color: primaryColor),
              title: Text('Kılınan Namazlar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoricalPrayerTimesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.warning_amber_rounded, color: Colors.orange),
              title: Text('Kılınmayan Namazlar'),
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
            Divider(),
            ListTile(
              leading: Icon(Icons.settings, color: textColor),
              title: Text('Ayarlar'),
              onTap: () {
                // TODO: Implement settings
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        cardTheme: CardTheme(
          color: cardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(
            'Namaz Vakitleri',
            style: TextStyle(color: Colors.white),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadPrayerTimes,
            ),
          ],
        ),
        drawer: _buildDrawer(),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
            : _prayerTimes == null
                ? Center(
                    child: Text(
                      'Namaz vakitleri yüklenemedi',
                      style: TextStyle(color: textColor),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [primaryColor.withOpacity(0.1), backgroundColor],
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    DateFormat('dd MMMM yyyy', 'tr_TR')
                                        .format(_prayerTimes!.date),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    'Bugünün Namaz Vakitleri',
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildPrayerCard('Sabah', _prayerTimes!.fajr, 'fajr',
                              _prayerTimes!.fajrPrayed),
                          _buildPrayerCard('Öğle', _prayerTimes!.dhuhr, 'dhuhr',
                              _prayerTimes!.dhuhrPrayed),
                          _buildPrayerCard('İkindi', _prayerTimes!.asr, 'asr',
                              _prayerTimes!.asrPrayed),
                          _buildPrayerCard('Akşam', _prayerTimes!.maghrib,
                              'maghrib', _prayerTimes!.maghribPrayed),
                          _buildPrayerCard('Yatsı', _prayerTimes!.isha, 'isha',
                              _prayerTimes!.ishaPrayed),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildPrayerCard(String title, String time, String prayer, bool isPrayed) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isPrayed
                ? [Colors.green.withOpacity(0.1), Colors.white]
                : [Colors.red.withOpacity(0.1), Colors.white],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPrayed ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPrayed ? Icons.check_circle : Icons.cancel,
              color: isPrayed ? Colors.green : Colors.red,
              size: 28,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          subtitle: Text(
            time,
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.7),
            ),
          ),
          trailing: ElevatedButton(
            onPressed: () => _togglePrayerStatus(prayer),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPrayed ? Colors.red : Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              isPrayed ? 'Kılınmadı' : 'Kılındı',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 