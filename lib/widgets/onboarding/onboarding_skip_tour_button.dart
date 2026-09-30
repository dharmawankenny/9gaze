// Skip tour control used inside onboarding tooltips and optional overlays.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/l10n/app_localizations.dart';

/// Compact Skip tour text button for onboarding tooltips.
class OnboardingSkipTourButton extends StatelessWidget {
  const OnboardingSkipTourButton({
    super.key,
    required this.onSkip,
  });

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onSkip,
      style: TextButton.styleFrom(
        foregroundColor: kWhite.withValues(alpha: 0.55),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        AppLocalizations.of(context)!.onboardingSkipTour,
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
