// Wraps a widget with a showcase tooltip when onboarding is on [step].

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/l10n/app_localizations.dart';
import 'package:kensa_9gaze/services/onboarding/onboarding_controller.dart';
import 'package:kensa_9gaze/services/onboarding/onboarding_strings.dart';
import 'package:kensa_9gaze/services/onboarding/onboarding_step.dart';
import 'package:kensa_9gaze/widgets/onboarding/onboarding_scope.dart';
import 'package:kensa_9gaze/widgets/onboarding/onboarding_skip_tour_button.dart';
import 'package:showcaseview/showcaseview.dart';

/// Highlights [child] during onboarding when [step] is active.
class OnboardingTarget extends StatelessWidget {
  const OnboardingTarget({
    super.key,
    required this.step,
    required this.child,
    this.onTargetTap,
    this.onAdvance,
    this.isShown,
    this.forceTapToAdvance = false,
    this.tooltipPosition,
    this.targetBorderRadius,
    this.targetPadding,
    this.enableAutoScroll = false,
    this.scrollAlignment = 0.5,
  });

  final OnboardingStep step;
  final Widget child;

  /// Called when the user taps the target on tap-to-advance steps.
  final VoidCallback? onTargetTap;

  /// Replaces the default Next handler for this target.
  final VoidCallback? onAdvance;

  /// Extra gate when several targets share one step.
  final bool Function(OnboardingController onboarding)? isShown;

  /// Treats this target as tap-to-advance even if the step is not.
  final bool forceTapToAdvance;

  /// Overrides the default tooltip side for this target.
  final TooltipPosition? tooltipPosition;

  final BorderRadius? targetBorderRadius;
  final EdgeInsets? targetPadding;

  /// Scrolls the target into view before the tooltip is shown.
  final bool enableAutoScroll;

  /// Viewport alignment used when [enableAutoScroll] is true.
  final double scrollAlignment;

  @override
  Widget build(BuildContext context) {
    final onboarding = OnboardingScope.maybeOf(context);
    if (onboarding == null ||
        !onboarding.isActive ||
        onboarding.currentStep != step) {
      return child;
    }
    if (isShown != null && !isShown!(onboarding)) return child;

    final l10n = AppLocalizations.of(context)!;
    final copy = OnboardingStrings.forStep(
      l10n,
      step,
      focus: onboarding.bulkFocus,
    );
    final tapToAdvance =
        forceTapToAdvance || OnboardingStrings.isTapToAdvance(step);
    final waitsForAction =
        !forceTapToAdvance && OnboardingStrings.waitsForAction(step);
    final resolvedTooltipPosition =
        tooltipPosition ?? OnboardingStrings.tooltipPositionFor(step);
    final key = onboarding.keyFor(step);
    if (key == null) return child;

    void handleAdvance() {
      ShowcaseView.get().dismiss();
      onboarding.clearShowcaseSession();
      if (onAdvance != null) {
        onAdvance!();
        return;
      }
      onboarding.advanceExplainStep();
    }

    return Showcase.withWidget(
      key: key,
      targetBorderRadius: targetBorderRadius ?? BorderRadius.circular(16),
      targetPadding: targetPadding ?? EdgeInsets.zero,
      overlayColor: kBlack,
      overlayOpacity: 0.85,
      tooltipPosition: resolvedTooltipPosition,
      disableMovingAnimation: true,
      toolTipSlideEndDistance: 0,
      toolTipMargin: step == OnboardingStep.homeEmptyList ? 20 : 16,
      targetTooltipGap: step == OnboardingStep.homeEmptyList ? 20 : 10,
      enableAutoScroll: enableAutoScroll,
      scrollAlignment: scrollAlignment,
      onBarrierClick: () {
        onboarding.requestSkipTour(context);
      },
      disableDefaultTargetGestures: false,
      disposeOnTap: tapToAdvance ? true : null,
      onTargetClick: tapToAdvance
          ? () {
              ShowcaseView.get().dismiss();
              onboarding.clearShowcaseSession();
              onTargetTap?.call();
            }
          : null,
      container: _OnboardingTooltipCard(
        step: step,
        onboarding: onboarding,
        title: copy.title,
        body: copy.body,
        showAdvanceButton: !tapToAdvance && !waitsForAction,
        onAdvance: handleAdvance,
        onSkip: () => onboarding.requestSkipTour(context),
      ),
      child: child,
    );
  }
}

/// Tooltip card styled for the 9Gaze dark theme.
class _OnboardingTooltipCard extends StatefulWidget {
  const _OnboardingTooltipCard({
    required this.step,
    required this.onboarding,
    required this.title,
    required this.body,
    required this.showAdvanceButton,
    required this.onAdvance,
    required this.onSkip,
  });

  final OnboardingStep step;
  final OnboardingController onboarding;
  final String title;
  final String body;
  final bool showAdvanceButton;
  final VoidCallback onAdvance;
  final VoidCallback onSkip;

  @override
  State<_OnboardingTooltipCard> createState() => _OnboardingTooltipCardState();
}

class _OnboardingTooltipCardState extends State<_OnboardingTooltipCard> {
  @override
  void initState() {
    super.initState();
    if (widget.step == OnboardingStep.createName) {
      widget.onboarding.addListener(_onOnboardingChanged);
    }
  }

  @override
  void dispose() {
    if (widget.step == OnboardingStep.createName) {
      widget.onboarding.removeListener(_onOnboardingChanged);
    }
    super.dispose();
  }

  void _onOnboardingChanged() {
    if (widget.step == OnboardingStep.createName) {
      setState(() {});
    }
  }

  bool get _advanceEnabled {
    if (widget.step == OnboardingStep.createName) {
      return widget.onboarding.createNameAdvanceEnabled;
    }
    return OnboardingStrings.isAdvanceEnabled(widget.step);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cardWidth = (MediaQuery.sizeOf(context).width - 40).clamp(
      240.0,
      360.0,
    );

    return SizedBox(
      width: cardWidth,
      child: Material(
        color: kDarkBlue,
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: kWhite,
                        height: 1.25,
                      ),
                    ),
                  ),
                  OnboardingSkipTourButton(onSkip: widget.onSkip),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.body,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: kWhite.withValues(alpha: 0.75),
                  height: 1.4,
                ),
              ),
              if (widget.showAdvanceButton) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _advanceEnabled ? widget.onAdvance : null,
                    style: TextButton.styleFrom(
                      backgroundColor: kAccentBlue,
                      disabledBackgroundColor: kAccentBlue.withValues(
                        alpha: 0.35,
                      ),
                      foregroundColor: kWhite,
                      disabledForegroundColor: kWhite.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Text(
                      l10n.onboardingNext,
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
