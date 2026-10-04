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
  final GlobalKey detailTapFilledSlotKey = GlobalKey();
  final GlobalKey slotEditorGesturesKey = GlobalKey();
  final GlobalKey slotEditorUndoRedoKey = GlobalKey();
  final GlobalKey slotEditorToolsKey = GlobalKey();
  final GlobalKey slotEditorSaveKey = GlobalKey();
  final GlobalKey detailBulkEditButtonKey = GlobalKey();
  final GlobalKey detailEditMenuKey = GlobalKey();
  final GlobalKey detailRepositionKey = GlobalKey();
  final GlobalKey detailRepositionPickKey = GlobalKey();
  final GlobalKey detailRepositionSaveKey = GlobalKey();
  final GlobalKey detailRearrangeKey = GlobalKey();
  final GlobalKey detailRearrangePickKey = GlobalKey();
  final GlobalKey detailRearrangeSaveKey = GlobalKey();
  final GlobalKey detailTextPickKey = GlobalKey();
  final GlobalKey detailTextAddKey = GlobalKey();
  final GlobalKey detailTextCoachKey = GlobalKey();
  final GlobalKey detailTextSaveKey = GlobalKey();
  final GlobalKey detailTextDoneKey = GlobalKey();

  OnboardingLaunchMode _launchMode = OnboardingLaunchMode.automatic;
  OnboardingStep? _currentStep;
  bool _isActive = false;
  OnboardingStep? _showcaseStartedForStep;
  OnboardingBulkFocus? _showcaseStartedFocus;
  OnboardingBulkFocus _bulkFocus = OnboardingBulkFocus.primary;
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

  /// Active highlight inside a bulk-edit step.
  OnboardingBulkFocus get bulkFocus => _bulkFocus;

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

  /// Moves the highlight within the current bulk-edit step.
  void setBulkFocus(OnboardingBulkFocus focus) {
    if (_bulkFocus == focus) return;
    _bulkFocus = focus;
    _showcaseStartedForStep = null;
    _showcaseStartedFocus = null;
    notifyListeners();
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
      OnboardingStep.detailTapFilledSlot => detailTapFilledSlotKey,
      OnboardingStep.slotEditorGestures => slotEditorGesturesKey,
      OnboardingStep.slotEditorUndoRedo => slotEditorUndoRedoKey,
      OnboardingStep.slotEditorTools => slotEditorToolsKey,
      OnboardingStep.slotEditorSave => slotEditorSaveKey,
      OnboardingStep.detailBulkEditButton => detailBulkEditButtonKey,
      OnboardingStep.detailEditMenu => detailEditMenuKey,
      OnboardingStep.detailReposition => switch (_bulkFocus) {
        OnboardingBulkFocus.pickMode => detailRepositionPickKey,
        OnboardingBulkFocus.save => detailRepositionSaveKey,
        _ => detailRepositionKey,
      },
      OnboardingStep.detailRearrange => switch (_bulkFocus) {
        OnboardingBulkFocus.pickMode => detailRearrangePickKey,
        OnboardingBulkFocus.save => detailRearrangeSaveKey,
        _ => detailRearrangeKey,
      },
      OnboardingStep.detailText => switch (_bulkFocus) {
        OnboardingBulkFocus.pickMode => detailTextPickKey,
        OnboardingBulkFocus.coach => detailTextCoachKey,
        OnboardingBulkFocus.save => detailTextSaveKey,
        OnboardingBulkFocus.exit => detailTextDoneKey,
        OnboardingBulkFocus.primary => detailTextAddKey,
      },
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
    _showcaseStartedFocus = null;
    _bulkFocus = OnboardingBulkFocus.primary;
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
    _showcaseStartedFocus = null;
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
    _showcaseStartedFocus = null;
    _bulkFocus = OnboardingBulkFocus.primary;
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
    final focus = _bulkFocus;
    if (_showcaseStartedForStep == step && _showcaseStartedFocus == focus) {
      return;
    }
    final key = keyFor(step);
    if (key == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isActive || _currentStep != step || _bulkFocus != focus) {
        return;
      }
      if (_showcaseStartedForStep == step && _showcaseStartedFocus == focus) {
        return;
      }
      try {
        ShowcaseView.get().startShowCase([key]);
        _showcaseStartedForStep = step;
        _showcaseStartedFocus = focus;
      } catch (e) {
        debugPrint('Onboarding showcase start failed: $e');
        _showcaseStartedForStep = null;
        _showcaseStartedFocus = null;
        if (attempt < 8) {
          _scheduleShowcaseStart(attempt: attempt + 1);
        }
      }
    });
  }

  /// Dismisses any active showcase overlay.
  void dismissShowcase() {
    _showcaseStartedForStep = null;
    _showcaseStartedFocus = null;
    try {
      ShowcaseView.get().dismiss();
    } catch (_) {}
  }
}
