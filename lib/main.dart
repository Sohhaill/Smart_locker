import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_locker/Home_screen.dart';
import 'package:smart_locker/Splash_screen.dart';
import 'package:smart_locker/Screen2.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyAzxJa3tIqs7_MM6EYcmkhVe2UOl8z_EIo",
        appId: "1:913256556954:android:de76f1d7ed23c4001a3223",
        messagingSenderId: "913256556954",
        projectId: "final-project-bab20"
    ),
  );
  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Specify the initial route or the home widget
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        // Add more routes for other screens if needed
        //'/home': (context) => const Screen2(),
      },
    );
  }
}
