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
  ///
  /// [focus] selects the mode-button copy before a bulk-edit mode opens.
  static OnboardingCopy forStep(
    AppLocalizations l10n,
    OnboardingStep step, {
    OnboardingBulkFocus focus = OnboardingBulkFocus.primary,
  }) {
    if (focus == OnboardingBulkFocus.pickMode) {
      final pickCopy = _pickModeCopy(l10n, step);
      if (pickCopy != null) return pickCopy;
    }
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
      OnboardingStep.detailBulkEditButton => (
        title: l10n.onboardingDetailEditTitle,
        body: l10n.onboardingDetailEditBody,
      ),
      OnboardingStep.detailEditMenu => (
        title: l10n.onboardingDetailEditMenuTitle,
        body: l10n.onboardingDetailEditMenuBody,
      ),
      OnboardingStep.detailReposition => (
        title: l10n.onboardingDetailRepositionTitle,
        body: l10n.onboardingDetailRepositionBody,
      ),
      OnboardingStep.detailRearrange => (
        title: l10n.onboardingDetailRearrangeTitle,
        body: l10n.onboardingDetailRearrangeBody,
      ),
      OnboardingStep.detailText => (
        title: l10n.onboardingDetailTextTitle,
        body: l10n.onboardingDetailTextBody,
      ),
      OnboardingStep.detailExport => (
        title: l10n.onboardingDetailExportTitle,
        body: l10n.onboardingDetailExportBody,
      ),
      OnboardingStep.complete => (
        title: l10n.onboardingCompleteTitle,
        body: l10n.onboardingCompleteBody,
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
      OnboardingStep.slotEditorSave ||
      OnboardingStep.detailBulkEditButton ||
      OnboardingStep.detailExport => true,
      _ => false,
    };
  }

  /// Steps that advance from a real action, with no Next button.
  static bool waitsForAction(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.slotEditorGestures ||
      OnboardingStep.slotEditorUndoRedo ||
      OnboardingStep.detailReposition ||
      OnboardingStep.detailRearrange => true,
      _ => false,
    };
  }

  /// Copy for the mode button, before that edit mode is open.
  static OnboardingCopy? _pickModeCopy(
    AppLocalizations l10n,
    OnboardingStep step,
  ) {
    return switch (step) {
      OnboardingStep.detailReposition => (
        title: l10n.onboardingDetailPickRepositionTitle,
        body: l10n.onboardingDetailPickRepositionBody,
      ),
      OnboardingStep.detailRearrange => (
        title: l10n.onboardingDetailPickRearrangeTitle,
        body: l10n.onboardingDetailPickRearrangeBody,
      ),
      OnboardingStep.detailText => (
        title: l10n.onboardingDetailPickTextTitle,
        body: l10n.onboardingDetailPickTextBody,
      ),
      _ => null,
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
      OnboardingStep.slotEditorSave ||
      OnboardingStep.detailBulkEditButton ||
      OnboardingStep.detailReposition ||
      OnboardingStep.detailRearrange => TooltipPosition.bottom,
      OnboardingStep.detailEditMenu ||
      OnboardingStep.detailText ||
      OnboardingStep.detailExport => TooltipPosition.top,
      _ => null,
    };
  }
}
