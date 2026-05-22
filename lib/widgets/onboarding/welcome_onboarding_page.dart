// Full-screen welcome step for the first-run onboarding tour.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/l10n/app_localizations.dart';
import 'package:kensa_9gaze/widgets/animated_gaze_face.dart';

/// Step 1: animated face, title, description, and Next CTA.
class WelcomeOnboardingPage extends StatelessWidget {
  const WelcomeOnboardingPage({
    super.key,
    required this.onNext,
  });

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(flex: 2),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: kWhite, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: const AnimatedGazeFace(
                size: 72,
                stepDuration: Duration(milliseconds: 800),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.onboardingWelcomeTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: kWhite,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.onboardingWelcomeBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: kWhite.withValues(alpha: 0.75),
                height: 1.45,
              ),
            ),
            const Spacer(flex: 3),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentBlue,
                  foregroundColor: kWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.onboardingNext,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
