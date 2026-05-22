// State machine for the onboarding tour (eligibility, steps, completion).

import 'package:flutter/foundation.dart';

import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/repositories/gazes_repository.dart';
import 'package:kensa_9gaze/services/onboarding/onboarding_launch_mode.dart';
import 'package:kensa_9gaze/services/onboarding/onboarding_prefs.dart';
import 'package:kensa_9gaze/services/onboarding/onboarding_step.dart';

/// Drives onboarding step state and first-run eligibility.
class OnboardingController extends ChangeNotifier {
  OnboardingController(this._db);

  final AppDatabase _db;

  OnboardingLaunchMode _launchMode = OnboardingLaunchMode.automatic;
  OnboardingStep? _currentStep;
  bool _isActive = false;

  /// How this tour was started.
  OnboardingLaunchMode get launchMode => _launchMode;

  /// Current step when [_isActive]; null when idle.
  OnboardingStep? get currentStep => _currentStep;

  /// True while a tour is in progress (welcome through complete).
  bool get isActive => _isActive;

  /// Checks prefs + gaze count; returns true if welcome should show.
  Future<bool> startIfEligible() async {
    if (!await _shouldShowAutomaticOnboarding()) {
      return false;
    }
    _launchMode = OnboardingLaunchMode.automatic;
    _currentStep = OnboardingStep.welcome;
    _isActive = true;
    notifyListeners();
    return true;
  }

  /// Whether the automatic tour should run on this launch.
  Future<bool> _shouldShowAutomaticOnboarding() async {
    if (await OnboardingPrefs.isCompleted()) {
      return false;
    }
    final count = await GazesRepository(_db).count();
    if (count > 0) {
      await OnboardingPrefs.markCompleted();
      return false;
    }
    return true;
  }

  /// Moves to [step] or the next step in sequence.
  void advance({OnboardingStep? step}) {
    if (!_isActive) return;

    if (step != null) {
      _currentStep = step;
    } else if (_currentStep != null) {
      final index = OnboardingStep.values.indexOf(_currentStep!);
      if (index < OnboardingStep.values.length - 1) {
        _currentStep = OnboardingStep.values[index + 1];
      }
    }
    notifyListeners();
  }

  /// Skips the tour and persists completion.
  Future<void> skip() async {
    await complete();
  }

  /// Ends the tour and marks onboarding complete in prefs.
  Future<void> complete() async {
    await OnboardingPrefs.markCompleted();
    _isActive = false;
    _currentStep = null;
    notifyListeners();
  }

  /// Starts showcase for [currentStep]. No-op until Phase 2 (showcaseview).
  void startShowcaseForCurrentStep() {
    // Implemented in Phase 2 with showcaseview.
  }

  /// Dismisses any active showcase overlay. No-op until Phase 2.
  void dismissShowcase() {
    // Implemented in Phase 2 with showcaseview.
  }
}
