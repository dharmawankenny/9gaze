// Persists whether the first-run onboarding tour was finished or skipped.

import 'package:shared_preferences/shared_preferences.dart';

/// Local preference keys for the onboarding tour.
class OnboardingPrefs {
  OnboardingPrefs._();

  static const String completedKey = 'onboarding_completed_v1';

  /// True when the user completed or skipped the auto tour.
  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(completedKey) ?? false;
  }

  /// Marks onboarding done so the auto tour does not start again.
  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(completedKey, true);
  }

  /// Clears completion (dev/QA only). Does not delete gazes.
  static Future<void> clearForDev() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(completedKey);
  }
}
