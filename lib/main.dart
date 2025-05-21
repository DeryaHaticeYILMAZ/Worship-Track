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
import 'quran_reading_tracker_screen.dart';
import 'quran_simple_tracker_screen.dart';
import 'package:google_fonts/google_fonts.dart';

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
            debugShowCheckedModeBanner: false,
            title: 'DeenTrack',
            theme: ThemeData(
              primaryColor: Color(0xFF20613A),
              scaffoldBackgroundColor: Colors.white,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Color(0xFF20613A),
                primary: Color(0xFF20613A),
                secondary: Color(0xFFC9A14A),
                background: Colors.white,
                onPrimary: Colors.white,
                onSecondary: Color(0xFF20613A),
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Color(0xFF20613A),
                foregroundColor: Colors.white,
                iconTheme: IconThemeData(color: Color(0xFF20613A)),
                titleTextStyle: GoogleFonts.merriweather(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              textTheme: GoogleFonts.merriweatherTextTheme(
                Theme.of(context).textTheme,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF20613A),
                  foregroundColor: Colors.white,
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Color(0xFFC9A14A),
                foregroundColor: Color(0xFF20613A),
              ),
            ),
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
              '/quran-reading-tracker': (context) => QuranReadingTrackerScreen(),
              '/quran-simple-tracker': (context) => QuranSimpleTrackerScreen(),
            },
          );
        }
      },
    );
  }
}
