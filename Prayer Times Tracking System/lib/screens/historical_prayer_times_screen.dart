import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/prayer_times.dart';
import '../models/prayer_status.dart';
import '../services/diyanet_service.dart';
import '../services/prayer_status_service.dart';

class HistoricalPrayerTimesScreen extends StatefulWidget {
  const HistoricalPrayerTimesScreen({Key? key}) : super(key: key);

  @override
  State<HistoricalPrayerTimesScreen> createState() => _HistoricalPrayerTimesScreenState();
}

class _HistoricalPrayerTimesScreenState extends State<HistoricalPrayerTimesScreen> {
  final DiyanetService _diyanetService = DiyanetService();
  final PrayerStatusService _statusService = PrayerStatusService();
  List<PrayerTimes> _prayerTimes = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadHistoricalPrayerTimes();
  }

  Future<void> _loadHistoricalPrayerTimes() async {
    setState(() => _isLoading = true);

    try {
      // Son 7 günün namaz vakitlerini getir
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));
      
      _prayerTimes = await _diyanetService.getHistoricalPrayerTimes(startDate, endDate);
      
      // Her gün için namaz durumlarını yükle
      for (var prayerTime in _prayerTimes) {
        final status = await _statusService.getPrayerStatusForDate(prayerTime.date);
        if (status != null) {
          prayerTime.fajrPrayed = status.fajrPrayed;
          prayerTime.dhuhrPrayed = status.dhuhrPrayed;
          prayerTime.asrPrayed = status.asrPrayed;
          prayerTime.maghribPrayed = status.maghribPrayed;
          prayerTime.ishaPrayed = status.ishaPrayed;
        }
      }

      setState(() => _isLoading = false);
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadHistoricalPrayerTimes();
    }
  }

  String _getPrayerStatus(PrayerTimes prayerTime) {
    int prayedCount = 0;
    if (prayerTime.fajrPrayed) prayedCount++;
    if (prayerTime.dhuhrPrayed) prayedCount++;
    if (prayerTime.asrPrayed) prayedCount++;
    if (prayerTime.maghribPrayed) prayedCount++;
    if (prayerTime.ishaPrayed) prayedCount++;
    return '$prayedCount/5 Namaz Kılındı';
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Namazlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistoricalPrayerTimes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prayerTimes.isEmpty
              ? const Center(
                  child: Text('Namaz vakitleri bulunamadı'),
                )
              : ListView.builder(
                  itemCount: _prayerTimes.length,
                  itemBuilder: (context, index) {
                    final prayerTime = _prayerTimes[index];
                    final date = _formatDate(prayerTime.date);
                    final status = _getPrayerStatus(prayerTime);

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ExpansionTile(
                        title: Text(date),
                        subtitle: Text(
                          status,
                          style: TextStyle(
                            color: status.startsWith('5') ? Colors.green : Colors.orange,
                          ),
                        ),
                        children: [
                          _buildPrayerTile(prayerTime, 'Sabah', prayerTime.fajr, prayerTime.fajrPrayed),
                          _buildPrayerTile(prayerTime, 'Öğle', prayerTime.dhuhr, prayerTime.dhuhrPrayed),
                          _buildPrayerTile(prayerTime, 'İkindi', prayerTime.asr, prayerTime.asrPrayed),
                          _buildPrayerTile(prayerTime, 'Akşam', prayerTime.maghrib, prayerTime.maghribPrayed),
                          _buildPrayerTile(prayerTime, 'Yatsı', prayerTime.isha, prayerTime.ishaPrayed),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildPrayerTile(PrayerTimes prayerTime, String name, String time, bool prayed) {
    return ListTile(
      leading: Icon(
        prayed ? Icons.check_circle : Icons.access_time,
        color: prayed ? Colors.green : Colors.orange,
      ),
      title: Text(name),
      subtitle: Text(time),
    );
  }
} 