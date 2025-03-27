import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/historical_prayer_times_screen.dart';
import 'screens/missed_prayers_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prayer Times Tracker',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/historical': (context) => const HistoricalPrayerTimesScreen(),
        '/missed': (context) => const MissedPrayersScreen(),
      },
    );
  }
}