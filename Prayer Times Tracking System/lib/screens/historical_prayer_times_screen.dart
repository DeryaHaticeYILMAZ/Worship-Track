import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HistoricalPrayerTimesScreen extends StatefulWidget {
  const HistoricalPrayerTimesScreen({Key? key}) : super(key: key);

  @override
  _HistoricalPrayerTimesScreenState createState() =>
      _HistoricalPrayerTimesScreenState();
}

class _HistoricalPrayerTimesScreenState extends State<HistoricalPrayerTimesScreen> {
  List<Map<String, dynamic>> _prayerHistory = [];
  bool _isLoading = true;

  static const primaryColor = Color(0xFF1E88E5);
  static const backgroundColor = Color(0xFFF5F5F5);
  static const textColor = Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _loadPrayerHistory();
  }

  Future<void> _loadPrayerHistory() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStatuses = prefs.getString('prayer_statuses') ?? '{}';
      final Map<String, dynamic> statusesMap = json.decode(savedStatuses);

      List<Map<String, dynamic>> history = [];
      statusesMap.forEach((date, status) {
        final prayers = [
          {'name': 'Sabah', 'key': 'fajr'},
          {'name': 'Öğle', 'key': 'dhuhr'},
          {'name': 'İkindi', 'key': 'asr'},
          {'name': 'Akşam', 'key': 'maghrib'},
          {'name': 'Yatsı', 'key': 'isha'},
        ];

        List<Map<String, dynamic>> dayPrayers = [];
        for (var prayer in prayers) {
          dayPrayers.add({
            'name': prayer['name'],
            'performed': status[prayer['key']] ?? false,
          });
        }

        history.add({
          'date': date,
          'prayers': dayPrayers,
        });
      });

      // Sort by date, most recent first
      history.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        _prayerHistory = history;
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
            'Namaz Geçmişi',
            style: TextStyle(color: Colors.white),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadPrayerHistory,
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
            : _prayerHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: primaryColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Henüz namaz geçmişi bulunmamaktadır',
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
                      itemCount: _prayerHistory.length,
                      itemBuilder: (context, index) {
                        final dayHistory = _prayerHistory[index];
                        final date = DateTime.parse(dayHistory['date']);
                        final formattedDate =
                            DateFormat('dd MMMM yyyy', 'tr_TR').format(date);

                        return Card(
                          margin: EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: primaryColor,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: dayHistory['prayers'].length,
                                itemBuilder: (context, prayerIndex) {
                                  final prayer = dayHistory['prayers'][prayerIndex];
                                  return ListTile(
                                    leading: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: prayer['performed']
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        prayer['performed']
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: prayer['performed']
                                            ? Colors.green
                                            : Colors.red,
                                        size: 24,
                                      ),
                                    ),
                                    title: Text(
                                      prayer['name'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                    subtitle: Text(
                                      prayer['performed']
                                          ? 'Kılındı'
                                          : 'Kılınmadı',
                                      style: TextStyle(
                                        color: prayer['performed']
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
} 