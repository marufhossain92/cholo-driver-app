import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:cholo_driver_app/authentication/login_screen.dart';
import 'package:cholo_driver_app/global/global.dart';
import 'package:cholo_driver_app/mainScreens/main_screen.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({super.key});

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  startTimer() {
    Timer(const Duration(seconds: 7), () async {
      if (fAuth.currentUser != null) {
        //await was present before
        currentFirebaseUser = fAuth.currentUser;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const MainScreen()),
        );
      } else {
        // Send user to home screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => LoginScreen()),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();

    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AvatarGlow(
                glowColor: Colors.blue,
                endRadius: 90.0,
                duration: const Duration(milliseconds: 2000),
                repeat: true,
                showTwoGlows: true,
                repeatPauseDuration: const Duration(milliseconds: 100),
                child: Material(
                  elevation: 8.0,
                  shape: const CircleBorder(),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey[100],
                    radius: 40.0,
                    child: Image.asset(
                      'images/car_ios.png',
                      height: 60,
                    ),
                  ),
                ),
              ),

              DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 20.0,
                ),
                child: AnimatedTextKit(
                  animatedTexts: [
                    WavyAnimatedText('Cholo'),
                    WavyAnimatedText('Ride Sharing'),
                  ],
                  isRepeatingAnimation: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
