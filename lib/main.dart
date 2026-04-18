// Entry point for the 9Gaze Flutter application.

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/db/database_provider.dart';
import 'package:kensa_9gaze/screens/home/home_screen.dart';

void main() {
  // Preserve the native splash until Flutter signals ready.
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  GoogleFonts.config.allowRuntimeFetching = false;
  // Touch the shared database so the drift executor is
  // constructed eagerly; the actual SQLite file is still
  // opened lazily on the first query.
  appDatabase;

  runApp(const NineGazeApp());
}

/// Removes the native splash after the first frame is drawn.
///
/// Called once from [NineGazeApp] after [runApp] completes its
/// first build so the splash never flashes a blank frame.
void removeSplash() => FlutterNativeSplash.remove();

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
