import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'missed_prayers_screen.dart';
import 'fasting_tracker_screen.dart';
import 'reading_tracker_screen.dart';
import 'settings_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prayer Times App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/missed-prayers': (context) => MissedPrayersScreen(),
        '/fasting-tracker': (context) => FastingTrackerScreen(),
        '/reading-tracker': (context) => ReadingTrackerScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}