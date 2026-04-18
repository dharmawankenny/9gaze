// Sticky bottom "New Gaze" action button.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/widgets/animated_gaze_face.dart';

/// Full-width pill-shaped button pinned to the bottom of the
/// screen. Shows the animated gaze face on the left, label in
/// the center, and a forward-arrow icon on the right.
class NewGazeButton extends StatelessWidget {
  const NewGazeButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

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
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Animated face cycles through all 9 gaze
                // directions. Eye cut-out colour matches the
                // button background so the pupils appear as
                // transparent holes.
                AnimatedGazeFace(size: 28, eyeColor: kAccentBlue),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
