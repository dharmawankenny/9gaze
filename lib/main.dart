// Entry point for the 9Gaze Flutter application.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/screens/home/home_screen.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const NineGazeApp());
}

/// Root application widget that wires up the dark theme
/// and launches the home screen.
class NineGazeApp extends StatelessWidget {
  const NineGazeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '9Gaze',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
