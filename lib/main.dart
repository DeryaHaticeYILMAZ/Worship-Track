import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'calendar_screen.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'register_page.dart';
import 'missed_prayers_screen.dart';
import 'fasting_tracker_screen.dart';
import 'reading_tracker_screen.dart';
import 'settings_screen.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Future<Widget> _getStartScreen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      return HomeScreen();
    } else {
      return LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getStartScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(home: SplashScreen());
        } else {
          return MaterialApp(
            title: 'Prayer App',
            theme: ThemeData(primarySwatch: Colors.blue),
            home: snapshot.data,
            routes: {
              '/home': (context) => HomeScreen(),
              '/login': (context) => LoginScreen(),
              '/register': (context) => RegisterScreen(),
              '/missed-prayers': (context) => MissedPrayersScreen(),
              '/fasting-tracker': (context) => FastingTrackerScreen(),
              '/reading-tracker': (context) => ReadingTrackerScreen(),
              '/calendar': (context) => CalendarScreen(),
              '/settings': (context) => SettingsScreen(),
              '/missed-prayers': (context) => MissedPrayersScreen(),
            },
          );
        }
      },
    );
  }
}
