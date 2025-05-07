import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'services/prayer_times_service.dart';
import 'models/prayer_times_response.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, String> prayerTimes = {};
  Map<String, bool?> prayerStatus = {
    'Fajr': null,
    'Dhuhr': null,
    'Asr': null,
    'Maghrib': null,
    'Isha': null,
  };

  String? userEmail;
  bool _isLoading = true;
  String? _errorMessage;
  final PrayerTimesService _prayerTimesService = PrayerTimesService();

  String? dismissedPrayerPrompt;
  bool _dialogShown = false;

  // Helper to check if a prayer time has passed
  bool _hasPrayerTimePassed(String time) {
    final now = TimeOfDay.now();
    final parts = time.split(":");
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    if (now.hour > hour) return true;
    if (now.hour == hour && now.minute >= minute) return true;
    return false;
  }

  // Find the next pending prayer that is due
  String? getNextPendingPrayer() {
    for (var entry in prayerTimes.entries) {
      final name = entry.key;
      final time = entry.value;
      final status = prayerStatus[name];
      if (status != true && _hasPrayerTimePassed(time)) {
        if (dismissedPrayerPrompt != name) {
          return name;
        }
      }
    }
    return null;
  }

  List<String> getAllPendingPrayers() {
    final now = TimeOfDay.now();
    List<String> pending = [];
    for (var entry in prayerTimes.entries) {
      final name = entry.key;
      final time = entry.value;
      final status = prayerStatus[name];
      if (status == null) { // Sadece hiç işaretlenmemişler
        final parts = time.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final prayerTime = TimeOfDay(hour: hour, minute: minute);
        if (now.hour > prayerTime.hour || (now.hour == prayerTime.hour && now.minute >= prayerTime.minute)) {
          pending.add(name);
        }
      }
    }
    return pending;
  }

  Future<void> showPendingPrayersDialogsSequentially() async {
    while (true) {
      List<String> pendingPrayers = getAllPendingPrayers();
      if (pendingPrayers.isEmpty) break;
      // Sıradaki ilk pending namazı sor
      await askPrayerStatus(pendingPrayers.first);
      await _loadInitialData();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData().then((_) => showPendingPrayersDialogsSequentially());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    showPendingPrayersDialogsSequentially();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Load user email
      SharedPreferences prefs = await SharedPreferences.getInstance();
      userEmail = prefs.getString('userEmail');

      // Fetch prayer times
      final prayerTimesResponse = await _prayerTimesService.getPrayerTimes();

      // Fetch missed prayers for today
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final missedResponse = await http.get(
        Uri.parse('http://10.0.2.2:5000/missed_prayers?email=$userEmail'),
      );
      Map<String, bool?> newPrayerStatus = {
        'Fajr': null,
        'Dhuhr': null,
        'Asr': null,
        'Maghrib': null,
        'Isha': null,
      };
      if (missedResponse.statusCode == 200) {
        final data = jsonDecode(missedResponse.body);
        final List missedPrayers = data['missed_prayers'];
        for (var name in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
          final records = missedPrayers.where((prayer) {
            String dateStr = prayer['date'];
            DateTime date;
            try {
              date = DateFormat('EEE, dd MMM yyyy HH:mm:ss zzz', 'en_US').parse(dateStr);
            } catch (_) {
              date = DateTime.tryParse(dateStr) ?? DateTime.now();
            }
            final formatted = DateFormat('yyyy-MM-dd').format(date);
            return formatted == today && prayer['prayer_name'] == name;
          }).toList();

          if (records.isEmpty) {
            newPrayerStatus[name] = null; // Soru işareti
          } else if (records.any((p) => p['completed'] == 1)) {
            newPrayerStatus[name] = true; // Tik
          } else {
            newPrayerStatus[name] = false; // Çarpı
          }
        }
      }

      setState(() {
        prayerTimes = {
          'Fajr': prayerTimesResponse.data.timings.fajr,
          'Dhuhr': prayerTimesResponse.data.timings.dhuhr,
          'Asr': prayerTimesResponse.data.timings.asr,
          'Maghrib': prayerTimesResponse.data.timings.maghrib,
          'Isha': prayerTimesResponse.data.timings.isha,
        };
        // Only update if we have info from backend, otherwise keep previous
        prayerStatus = newPrayerStatus;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> checkAndMarkMissedPrayers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastCheckedDate = prefs.getString('lastCheckedDate');
    DateTime now = DateTime.now();
    DateTime lastCheck = lastCheckedDate != null
        ? DateTime.parse(lastCheckedDate)
        : now;

    // Only check up to today (not future)
    for (DateTime day = lastCheck;
        !day.isAfter(now);
        day = day.add(Duration(days: 1))) {
      final prayerTimesResponse = await _prayerTimesService.getPrayerTimesForDate(day);
      final timings = prayerTimesResponse.data.timings;
      final prayers = {
        'Fajr': timings.fajr,
        'Dhuhr': timings.dhuhr,
        'Asr': timings.asr,
        'Maghrib': timings.maghrib,
        'Isha': timings.isha,
      };
      for (var entry in prayers.entries) {
        final prayerName = entry.key;
        final prayerTimeStr = entry.value;
        // Parse time string to DateTime
        DateTime prayerDateTime = DateTime.parse(
          "${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')} "
          + prayerTimeStr,
        );
        // If the prayer time has passed
        if (now.isAfter(prayerDateTime)) {
          // If not marked as completed (local check only for today)
          if (day.year == now.year && day.month == now.month && day.day == now.day) {
            if (prayerStatus[prayerName] != true) {
              await http.post(
                Uri.parse('http://10.0.2.2:5000/missed_prayers'),
                body: {
                  'email': userEmail ?? '',
                  'prayer_name': prayerName,
                  'date': "${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}"
                },
              );
            }
          } else {
            // For previous days, always mark as missed (unless you have a way to check completion)
            await http.post(
              Uri.parse('http://10.0.2.2:5000/missed_prayers'),
              body: {
                'email': userEmail ?? '',
                'prayer_name': prayerName,
                'date': "${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}"
              },
            );
          }
        }
      }
    }
    await prefs.setString('lastCheckedDate', now.toIso8601String());
  }

  Future<void> askPrayerStatus(String prayerName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Did you pray $prayerName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Yes"),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        prayerStatus[prayerName] = result;
      });

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (result) {
        // YES: Önce missed_prayers'a ekle, sonra complete et
        await http.post(
          Uri.parse('http://10.0.2.2:5000/missed_prayers'),
          body: {
            'email': userEmail!,
            'prayer_name': prayerName,
            'date': today,
          },
        );
        await http.post(
          Uri.parse('http://10.0.2.2:5000/complete_missed_prayer'),
          body: {
            'email': userEmail!,
            'prayer_name': prayerName,
            'date': today,
          },
        );
      } else {
        // NO: Mark as missed in backend
        await http.post(
          Uri.parse('http://10.0.2.2:5000/missed_prayers'),
          body: {
            'email': userEmail!,
            'prayer_name': prayerName,
            'date': today,
          },
        );
      }
      // Prayer status değişti, ekrana yansıt
      await _loadInitialData();
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
            onPressed: _loadInitialData,
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('isLoggedIn');
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Fetching prayer times...'),
                            ],
                          ),
                        )
                      : _errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline, 
                                       color: Colors.red, 
                                       size: 48),
                                  SizedBox(height: 16),
                                  Text(
                                    'Error: $_errorMessage',
                                    style: TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadInitialData,
                                    child: Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Today's Prayers",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    Text(
                                      'Kayseri, Turkey',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      if (prayerTimes.isNotEmpty)
                                        ...prayerTimes.entries.map((entry) {
                                          final name = entry.key;
                                          final time = entry.value;
                                          final status = prayerStatus[name];

                                          return Card(
                                            elevation: 2,
                                            margin: EdgeInsets.symmetric(vertical: 4),
                                            child: ListTile(
                                              title: Text(
                                                name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Text(
                                                time,
                                                style: TextStyle(
                                                  color: Colors.yellow.shade800,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              leading: Icon(
                                                status == null
                                                    ? Icons.help_outline
                                                    : status
                                                        ? Icons.check_circle
                                                        : Icons.cancel,
                                                color: status == null
                                                    ? Colors.grey
                                                    : status!
                                                        ? Colors.green
                                                        : Colors.red,
                                              ),
                                              trailing: ElevatedButton(
                                                onPressed: () => askPrayerStatus(name),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue.shade700,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: Text("Did you pray?"),
                                              ),
                                            ),
                                          );
                                        }).toList()
                                      else
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            "Prayer times are not available. Please check your internet connection or location settings.",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                                          ),
                                        ),
                                      SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.pushNamed(context, '/missed-prayers');
                  if (result == true) {
                    _loadInitialData();
                  }
                },
                icon: Icon(Icons.error, color: Colors.white),
                label: Text('Missed Prayers'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/calendar');
                },
                icon: Icon(Icons.calendar_today, color: Colors.white),
                label: Text('Prayer Calendar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}