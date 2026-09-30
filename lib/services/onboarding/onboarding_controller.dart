// State machine for the onboarding tour (eligibility, steps, completion).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/models/slot_key.dart';
import 'package:kensa_9gaze/repositories/gazes_repository.dart';
import 'package:kensa_9gaze/services/onboarding/onboarding_launch_mode.dart';
import 'package:kensa_9gaze/services/onboarding/onboarding_prefs.dart';
import 'package:kensa_9gaze/services/onboarding/onboarding_step.dart';
import 'package:kensa_9gaze/widgets/onboarding/onboarding_skip_confirm_dialog.dart';

/// Drives onboarding step state and first-run eligibility.
class OnboardingController extends ChangeNotifier {
  OnboardingController(this._db);

  final AppDatabase _db;

  static bool _showcaseRegistered = false;

  final GlobalKey homeEmptyListKey = GlobalKey();
  final GlobalKey homeCreateButtonKey = GlobalKey();
  final GlobalKey createNameKey = GlobalKey();
  final GlobalKey createNotesKey = GlobalKey();
  final GlobalKey createSubmitKey = GlobalKey();
  final GlobalKey detailSlotsGridKey = GlobalKey();
  final GlobalKey detailPickSlotKey = GlobalKey();
  final GlobalKey detailAutoAlignKey = GlobalKey();
  final GlobalKey detailFineTuneIntroKey = GlobalKey();
  final GlobalKey detailCompactDualKey = GlobalKey();
  final GlobalKey detailInfoEditKey = GlobalKey();

  OnboardingLaunchMode _launchMode = OnboardingLaunchMode.automatic;
  OnboardingStep? _currentStep;
  bool _isActive = false;
  OnboardingStep? _showcaseStartedForStep;
  bool _skipConfirmShowing = false;
  bool _createNameAdvanceEnabled = false;
  SlotKey? _tutorialSlotKey;

  /// Registers [ShowcaseView] once per process.
  static void ensureShowcaseRegistered() {
    if (_showcaseRegistered) return;
    ShowcaseView.register(
      disableBarrierInteraction: true,
      disableMovingAnimation: true,
      disableScaleAnimation: true,
      overlayOpacity: 0.85,
    );
    _showcaseRegistered = true;
  }

  /// How this tour was started.
  OnboardingLaunchMode get launchMode => _launchMode;

  /// Current step when [_isActive]; null when idle.
  OnboardingStep? get currentStep => _currentStep;

  /// True while a tour is in progress (welcome through complete).
  bool get isActive => _isActive;

  /// Whether Next is enabled on the create-name onboarding step.
  bool get createNameAdvanceEnabled => _createNameAdvanceEnabled;

  /// Slot filled during the photo-pick step, reused by later highlights.
  SlotKey? get tutorialSlotKey => _tutorialSlotKey;

  /// Updates Next availability while the user types a gaze name.
  void setCreateNameAdvanceEnabled(bool enabled) {
    if (_createNameAdvanceEnabled == enabled) return;
    _createNameAdvanceEnabled = enabled;
    notifyListeners();
  }

  /// Remembers the first slot filled during the photo-pick step.
  void rememberTutorialSlot(SlotKey key) {
    _tutorialSlotKey = key;
  }

  /// GlobalKey for a showcase [step], or null when that step has no target yet.
  GlobalKey? keyFor(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.homeEmptyList => homeEmptyListKey,
      OnboardingStep.homeCreateButton => homeCreateButtonKey,
      OnboardingStep.createName => createNameKey,
      OnboardingStep.createNotes => createNotesKey,
      OnboardingStep.createSubmit => createSubmitKey,
      OnboardingStep.detailSlotsGrid => detailSlotsGridKey,
      OnboardingStep.detailPickSlot => detailPickSlotKey,
      OnboardingStep.detailAutoAlign => detailAutoAlignKey,
      OnboardingStep.detailFineTuneIntro => detailFineTuneIntroKey,
      OnboardingStep.detailCompactDual => detailCompactDualKey,
      OnboardingStep.detailInfoEdit => detailInfoEditKey,
      _ => null,
    };
  }

  /// Checks prefs + gaze count; returns true if welcome should show.
  Future<bool> startIfEligible() async {
    if (_isActive) return false;
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
  ///
  /// Debug builds ignore the completed flag when no gazes are saved,
  /// so the tour can be replayed without clearing app storage.
  Future<bool> _shouldShowAutomaticOnboarding() async {
    final count = await GazesRepository(_db).count();
    if (count > 0) {
      await OnboardingPrefs.markCompleted();
      return false;
    }
    if (kDebugMode) return true;
    if (await OnboardingPrefs.isCompleted()) return false;
    return true;
  }

  /// Moves to [step] or the next step in sequence.
  void advance({OnboardingStep? step}) {
    if (!_isActive) return;

    _showcaseStartedForStep = null;
    if (step != null) {
      _currentStep = step;
    } else if (_currentStep != null) {
      final index = OnboardingStep.values.indexOf(_currentStep!);
      if (index < OnboardingStep.values.length - 1) {
        _currentStep = OnboardingStep.values[index + 1];
      }
    }
    if (_currentStep != OnboardingStep.createName) {
      _createNameAdvanceEnabled = false;
    }
    notifyListeners();
  }

  /// After a tooltip Next tap; advances and shows the next showcase.
  void advanceExplainStep() {
    advance();
    startShowcaseForCurrentStep();
  }

  /// Clears per-step showcase guard so the next step can start.
  void clearShowcaseSession() {
    _showcaseStartedForStep = null;
  }

  /// Shows skip confirmation; completes onboarding if confirmed.
  Future<void> requestSkipTour(BuildContext context) async {
    if (!_isActive || _skipConfirmShowing) return;
    _skipConfirmShowing = true;
    try {
      final confirmed = await OnboardingSkipConfirmDialog.show(context);
      if (!context.mounted || !_isActive) return;
      if (confirmed) {
        await skip();
      }
    } finally {
      _skipConfirmShowing = false;
    }
  }

  /// Skips the tour and persists completion.
  Future<void> skip() async {
    dismissShowcase();
    await complete();
  }

  /// Ends the tour and marks onboarding complete in prefs.
  Future<void> complete() async {
    dismissShowcase();
    await OnboardingPrefs.markCompleted();
    _isActive = false;
    _currentStep = null;
    _showcaseStartedForStep = null;
    _createNameAdvanceEnabled = false;
    _tutorialSlotKey = null;
    notifyListeners();
  }

  /// Starts showcase for [currentStep] when a [GlobalKey] is registered.
  void startShowcaseForCurrentStep() {
    _scheduleShowcaseStart(attempt: 0);
  }

  /// Retries for a few frames when the target is not mounted yet.
  void _scheduleShowcaseStart({required int attempt}) {
    if (!_isActive || _currentStep == null) return;

    final step = _currentStep!;
    if (_showcaseStartedForStep == step) return;
    final key = keyFor(step);
    if (key == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isActive || _currentStep != step) return;
      if (_showcaseStartedForStep == step) return;
      try {
        ShowcaseView.get().startShowCase([key]);
        _showcaseStartedForStep = step;
      } catch (e) {
        debugPrint('Onboarding showcase start failed: $e');
        _showcaseStartedForStep = null;
        if (attempt < 8) {
          _scheduleShowcaseStart(attempt: attempt + 1);
        }
      }
    });
  }

  /// Dismisses any active showcase overlay.
  void dismissShowcase() {
    _showcaseStartedForStep = null;
    try {
      ShowcaseView.get().dismiss();
    } catch (_) {}
  }
}
