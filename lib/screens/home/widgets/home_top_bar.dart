// Top bar widget displaying the 9Gaze logo and animated gaze icon.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/widgets/animated_gaze_face.dart';

/// Renders the screen title "9Gaze" on the left and an animated
/// gaze face icon on the right.
///
/// The icon replicates the original primary.svg layout: a 48×48
/// transparent container with a 3px white border at 12px radius,
/// housing a 24×24 animated face centred within it.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '9Gaze',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 48,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -4.8,
              color: kWhite,
            ),
          ),
          // Mirrors the primary.svg bounding box: 48×48, transparent
          // fill, 3px white stroke, 12px border radius.
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
        ],
      ),
    );
  }
}
