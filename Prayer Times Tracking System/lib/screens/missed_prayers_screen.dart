import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/prayer_status_service.dart';
import '../models/prayer_times.dart';
import '../models/prayer_status.dart';
import '../services/diyanet_service.dart';

class MissedPrayersScreen extends StatefulWidget {
  const MissedPrayersScreen({super.key});

  @override
  State<MissedPrayersScreen> createState() => _MissedPrayersScreenState();
}

class _MissedPrayersScreenState extends State<MissedPrayersScreen> {
  final PrayerStatusService _prayerStatusService = PrayerStatusService();
  final DiyanetService _diyanetService = DiyanetService();
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  List<PrayerTimes> _missedPrayers = [];

  @override
  void initState() {
    super.initState();
    _loadMissedPrayers();
  }

  Future<void> _loadMissedPrayers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prayerTimes = await _diyanetService.getHistoricalPrayerTimes(_startDate, _endDate);
      final statuses = await _prayerStatusService.getAllPrayerStatuses();
      
      List<PrayerTimes> missedPrayers = [];
      
      for (var prayerTime in prayerTimes) {
        final matchingStatus = statuses.where((s) => 
          DateFormat('yyyy-MM-dd').format(s.date) == 
          DateFormat('yyyy-MM-dd').format(prayerTime.date)
        ).toList();

        if (matchingStatus.isEmpty) {
          // Eğer o gün için hiç kayıt yoksa, tüm namazları kılınmamış say
          missedPrayers.add(prayerTime);
        } else {
          final status = matchingStatus.first;
          // Eğer herhangi bir namaz kılınmamışsa, o günü listeye ekle
          if (!status.fajrPrayed || !status.dhuhrPrayed || 
              !status.asrPrayed || !status.maghribPrayed || 
              !status.ishaPrayed) {
            missedPrayers.add(prayerTime);
          }
        }
      }

      setState(() {
        _missedPrayers = missedPrayers;
        _isLoading = false;
      });
    } catch (e) {
      print('Hata: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kılınmayan namazlar yüklenirken bir hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _loadMissedPrayers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kılınmayan Namazlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _missedPrayers.isEmpty
              ? const Center(
                  child: Text('Seçilen tarih aralığında kılınmayan namaz bulunmuyor.'),
                )
              : ListView.builder(
                  itemCount: _missedPrayers.length,
                  itemBuilder: (context, index) {
                    final prayerTime = _missedPrayers[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(
                          DateFormat('dd MMMM yyyy, EEEE', 'tr_TR')
                              .format(prayerTime.date),
                        ),
                        subtitle: Text(
                          'Sabah: ${prayerTime.fajr}\n'
                          'Öğle: ${prayerTime.dhuhr}\n'
                          'İkindi: ${prayerTime.asr}\n'
                          'Akşam: ${prayerTime.maghrib}\n'
                          'Yatsı: ${prayerTime.isha}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () async {
                            try {
                              final status = PrayerStatus(
                                date: prayerTime.date,
                                fajrPrayed: true,
                                dhuhrPrayed: true,
                                asrPrayed: true,
                                maghribPrayed: true,
                                ishaPrayed: true,
                              );
                              await _prayerStatusService.updatePrayerStatus(status);
                              await _loadMissedPrayers();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Namazlar kılındı olarak işaretlendi'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Hata oluştu: $e'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 