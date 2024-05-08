import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_locker/Home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late BuildContext storedContext; // Store the context here

  @override
  void initState() {
    super.initState();

    // Store the context when the widget is created
    storedContext = context;

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        storedContext,
        MaterialPageRoute(builder: (context) => const SecondSplashScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(seconds: 1),
          child: Image(
            key: UniqueKey(), // Key to identify changes in children for AnimatedSwitcher
            image: AssetImage('assets/logo.jpg'),
          ),
        ),
      ),
    );
  }
}

class SecondSplashScreen extends StatefulWidget {
  const SecondSplashScreen({Key? key}) : super(key: key);

  @override
  State<SecondSplashScreen> createState() => _SecondSplashScreenState();
}

class _SecondSplashScreenState extends State<SecondSplashScreen> {
  bool _showHomeScreen = false;

  @override
  void initState() {
    super.initState();

    // Start a timer to show the home screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      setState(() {
        _showHomeScreen = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(seconds: 1),
          child: _showHomeScreen
              ? const HomeScreen()
              : Image.network(
            'https://img.lovepik.com/photo/45009/7677.jpg_wh860.jpg',
            key: UniqueKey(), // Key to identify changes in children for AnimatedSwitcher
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}
