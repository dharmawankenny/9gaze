// Confirmation dialog before the user skips the onboarding tour.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/l10n/app_localizations.dart';

/// Asks the user to confirm skipping the tour.
class OnboardingSkipConfirmDialog {
  OnboardingSkipConfirmDialog._();

  /// Returns true when the user confirms skip.
  ///
  /// Uses the nearest navigator so the dialog appears above modal sheets.
  static Future<bool> show(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.onboardingSkipConfirmTitle,
          style: GoogleFonts.bricolageGrotesque(
            color: kWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          l10n.onboardingSkipConfirmBody,
          style: GoogleFonts.bricolageGrotesque(
            color: kWhite.withValues(alpha: 0.7),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.bricolageGrotesque(
                color: kWhite.withValues(alpha: 0.5),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.onboardingSkipTour,
              style: GoogleFonts.bricolageGrotesque(
                color: kAccentBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }
}
