// Home header: gaze icon, title, and the settings button.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kensa_9gaze/l10n/app_localizations.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/widgets/animated_gaze_face.dart';

/// Renders the gaze icon, the "9Gaze" title, and a settings button.
///
/// The icon replicates the original primary.svg layout: a 48×48
/// transparent container with a 3px white border at 12px radius,
/// housing a 24×24 animated face centred within it.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.onOpenSettings});

  /// Called when the user taps the settings button.
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: kWhite, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const AnimatedGazeFace.static(
              direction: GazeDirection.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '9Gaze',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 48,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -4.8,
                    color: kWhite,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.settings,
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_outlined, color: kWhite),
          ),
        ],
      ),
    );
  }
}
