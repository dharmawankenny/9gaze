// How the onboarding tour was started (auto first-run vs settings replay).

/// Distinguishes automatic eligibility from manual replay.
enum OnboardingLaunchMode {
  /// First install path: respects prefs and empty gazes table.
  automatic,

  /// Settings → Restart tutorial: bypasses gaze-count block.
  manualReplay,
}
