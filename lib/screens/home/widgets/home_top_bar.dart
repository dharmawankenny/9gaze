// Top bar widget displaying the 9Gaze logo and primary icon.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kensa_9gaze/app/theme.dart';

/// Renders the screen title "9Gaze" on the left and the
/// primary SVG icon on the right.
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
          SvgPicture.asset('assets/icons/primary.svg', width: 48, height: 48),
        ],
      ),
    );
  }
}
