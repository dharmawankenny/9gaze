// Closing dialog for the last step of the onboarding tour.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/l10n/app_localizations.dart';

/// Thanks the user and ends the tour when they tap Done.
class OnboardingCompleteDialog {
  OnboardingCompleteDialog._();

  /// Shows the ready dialog. Returns when Done is tapped.
  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: const Color(0xFF0A0A0A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              l10n.onboardingCompleteTitle,
              style: GoogleFonts.bricolageGrotesque(
                color: kWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              l10n.onboardingCompleteBody,
              style: GoogleFonts.bricolageGrotesque(
                color: kWhite.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: kAccentBlue,
                  foregroundColor: kWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text(
                  l10n.done,
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
