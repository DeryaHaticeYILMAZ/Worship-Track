import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MissedPrayersScreen extends StatefulWidget {
  const MissedPrayersScreen({Key? key}) : super(key: key);

  @override
  _MissedPrayersScreenState createState() => _MissedPrayersScreenState();
}

class _MissedPrayersScreenState extends State<MissedPrayersScreen> {
  List<Map<String, dynamic>> _missedPrayers = [];
  bool _isLoading = true;

  static const primaryColor = Color(0xFF1E88E5);
  static const backgroundColor = Color(0xFFF5F5F5);
  static const textColor = Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _loadMissedPrayers();
  }

  Future<void> _loadMissedPrayers() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStatuses = prefs.getString('prayer_statuses') ?? '{}';
      final Map<String, dynamic> statusesMap = json.decode(savedStatuses);

      List<Map<String, dynamic>> missedPrayers = [];
      statusesMap.forEach((date, status) {
        final prayers = [
          {'name': 'Sabah', 'key': 'fajr'},
          {'name': 'Öğle', 'key': 'dhuhr'},
          {'name': 'İkindi', 'key': 'asr'},
          {'name': 'Akşam', 'key': 'maghrib'},
          {'name': 'Yatsı', 'key': 'isha'},
        ];

        for (var prayer in prayers) {
          if (status[prayer['key']] == false) {
            missedPrayers.add({
              'date': date,
              'prayer': prayer['name'],
            });
          }
        }
      });

      // Sort by date, most recent first
      missedPrayers.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        _missedPrayers = missedPrayers;
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(
            'Kılınmayan Namazlar',
            style: TextStyle(color: Colors.white),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadMissedPrayers,
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
            : _missedPrayers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Kılınmayan namaz bulunmamaktadır',
                          style: TextStyle(
                            fontSize: 18,
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _missedPrayers.length,
                      itemBuilder: (context, index) {
                        final missedPrayer = _missedPrayers[index];
                        final date = DateTime.parse(missedPrayer['date']);
                        final formattedDate =
                            DateFormat('dd MMMM yyyy', 'tr_TR').format(date);

                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              missedPrayer['prayer'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            subtitle: Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
} 