// Maps [OnboardingStep] to localized title and body for tooltips.

import 'package:kensa_9gaze/l10n/app_localizations.dart';
import 'package:kensa_9gaze/services/onboarding/onboarding_step.dart';
import 'package:showcaseview/showcaseview.dart';

/// Title and description for an onboarding tooltip.
typedef OnboardingCopy = ({String title, String body});

/// Resolves onboarding copy from [AppLocalizations].
class OnboardingStrings {
  OnboardingStrings._();

  /// Returns title and body for [step].
  static OnboardingCopy forStep(AppLocalizations l10n, OnboardingStep step) {
    return switch (step) {
      OnboardingStep.welcome => (
        title: l10n.onboardingWelcomeTitle,
        body: l10n.onboardingWelcomeBody,
      ),
      OnboardingStep.homeEmptyList => (
        title: l10n.onboardingHomeEmptyTitle,
        body: l10n.onboardingHomeEmptyBody,
      ),
      OnboardingStep.homeCreateButton => (
        title: l10n.onboardingHomeCreateTitle,
        body: l10n.onboardingHomeCreateBody,
      ),
      OnboardingStep.createName => (
        title: l10n.onboardingCreateNameTitle,
        body: l10n.onboardingCreateNameBody,
      ),
      OnboardingStep.createNotes => (
        title: l10n.onboardingCreateNotesTitle,
        body: l10n.onboardingCreateNotesBody,
      ),
      OnboardingStep.createSubmit => (
        title: l10n.onboardingCreateSubmitTitle,
        body: l10n.onboardingCreateSubmitBody,
      ),
      OnboardingStep.detailSlotsGrid => (
        title: l10n.onboardingDetailSlotsTitle,
        body: l10n.onboardingDetailSlotsBody,
      ),
      OnboardingStep.detailPickSlot => (
        title: l10n.onboardingDetailPickTitle,
        body: l10n.onboardingDetailPickBody,
      ),
      OnboardingStep.detailAutoAlign => (
        title: l10n.onboardingDetailAutoAlignTitle,
        body: l10n.onboardingDetailAutoAlignBody,
      ),
      OnboardingStep.detailFineTuneIntro => (
        title: l10n.onboardingDetailFineTuneTitle,
        body: l10n.onboardingDetailFineTuneBody,
      ),
      OnboardingStep.detailCompactDual => (
        title: l10n.onboardingDetailLayoutTitle,
        body: l10n.onboardingDetailLayoutBody,
      ),
      OnboardingStep.detailInfoEdit => (
        title: l10n.onboardingDetailInfoTitle,
        body: l10n.onboardingDetailInfoBody,
      ),
      OnboardingStep.detailTapFilledSlot => (
        title: l10n.onboardingDetailTapSlotTitle,
        body: l10n.onboardingDetailTapSlotBody,
      ),
      OnboardingStep.slotEditorGestures => (
        title: l10n.onboardingSlotGesturesTitle,
        body: l10n.onboardingSlotGesturesBody,
      ),
      OnboardingStep.slotEditorUndoRedo => (
        title: l10n.onboardingSlotUndoTitle,
        body: l10n.onboardingSlotUndoBody,
      ),
      OnboardingStep.slotEditorTools => (
        title: l10n.onboardingSlotToolsTitle,
        body: l10n.onboardingSlotToolsBody,
      ),
      OnboardingStep.slotEditorSave => (
        title: l10n.onboardingSlotSaveTitle,
        body: l10n.onboardingSlotSaveBody,
      ),
      _ => (title: l10n.appTitle, body: ''),
    };
  }

  /// Whether the tooltip Next button is enabled for [step].
  static bool isAdvanceEnabled(OnboardingStep step) => true;

  /// Steps where the user must tap the highlighted widget.
  static bool isTapToAdvance(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.homeCreateButton ||
      OnboardingStep.createSubmit ||
      OnboardingStep.detailPickSlot ||
      OnboardingStep.detailTapFilledSlot ||
      OnboardingStep.slotEditorSave => true,
      _ => false,
    };
  }

  /// Steps that advance from a real action, with no Next button.
  static bool waitsForAction(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.slotEditorGestures ||
      OnboardingStep.slotEditorUndoRedo => true,
      _ => false,
    };
  }

  /// Tooltip placement per step. Avoid forcing top on large center targets.
  static TooltipPosition? tooltipPositionFor(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.homeEmptyList => TooltipPosition.bottom,
      OnboardingStep.homeCreateButton ||
      OnboardingStep.createName ||
      OnboardingStep.createNotes ||
      OnboardingStep.createSubmit => TooltipPosition.top,
      OnboardingStep.detailSlotsGrid ||
      OnboardingStep.detailPickSlot ||
      OnboardingStep.detailAutoAlign ||
      OnboardingStep.detailFineTuneIntro => TooltipPosition.bottom,
      OnboardingStep.detailCompactDual ||
      OnboardingStep.detailInfoEdit ||
      OnboardingStep.slotEditorGestures ||
      OnboardingStep.slotEditorUndoRedo ||
      OnboardingStep.slotEditorTools => TooltipPosition.top,
      OnboardingStep.detailTapFilledSlot ||
      OnboardingStep.slotEditorSave => TooltipPosition.bottom,
      _ => null,
    };
  }
}
