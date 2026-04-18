// App-wide theme definition and color constants for 9Gaze.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kAccentBlue = Color(0xFF003BFF);
const kWhite = Color(0xFFFAFAFA);
const kBlack = Color(0xFF000000);
const kSearchBg = Color(0xFF000926);

/// Centralized theme configuration for the 9Gaze app.
class AppTheme {
  AppTheme._();

  /// Dark theme used as the single app-wide theme.
  static ThemeData get darkTheme {
    final base = ThemeData.dark();

    return base.copyWith(
      scaffoldBackgroundColor: kBlack,
      colorScheme: const ColorScheme.dark(
        primary: kAccentBlue,
        surface: kBlack,
        onSurface: kWhite,
      ),
      textTheme: GoogleFonts.bricolageGrotesqueTextTheme(
        base.textTheme.apply(bodyColor: kWhite, displayColor: kWhite),
      ),
    );
  }
}
