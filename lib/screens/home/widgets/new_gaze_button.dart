// Sticky bottom "New Gaze" action button.
//
// When [showFace] is true (i.e. at least one gaze exists) the
// animated face icon is shown on the left. When false the label
// is centred without the icon so the empty-state layout stays
// clean.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/widgets/animated_gaze_face.dart';

/// Full-width pill-shaped button pinned to the bottom of the
/// screen.
///
/// Pass [showFace] = true to render the animated gaze face on
/// the left (shown only when the gazes list is non-empty).
class NewGazeButton extends StatelessWidget {
  const NewGazeButton({super.key, this.onPressed, this.showFace = false});

  final VoidCallback? onPressed;

  /// Whether to show the animated gaze face on the left side
  /// of the button. Should be true only when entries exist.
  final bool showFace;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ).copyWith(bottom: 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onPressed ?? () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentBlue,
              foregroundColor: kWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Row(
              mainAxisAlignment: showFace
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (showFace) ...[
                  // Eye cut-out colour matches button background
                  // so the pupils appear as transparent holes.
                  AnimatedGazeFace(size: 28, eyeColor: kAccentBlue),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    'New Gaze',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kWhite,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
                const Icon(Icons.arrow_forward, color: kWhite, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
