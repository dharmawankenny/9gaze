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
      _ => (title: l10n.appTitle, body: ''),
    };
  }

  /// Whether the tooltip Next button is enabled for [step].
  static bool isAdvanceEnabled(OnboardingStep step) => true;

  /// Steps where the user must tap the highlighted widget.
  static bool isTapToAdvance(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.homeCreateButton || OnboardingStep.createSubmit => true,
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
      OnboardingStep.createSubmit =>
        TooltipPosition.top,
      _ => null,
    };
  }
}
