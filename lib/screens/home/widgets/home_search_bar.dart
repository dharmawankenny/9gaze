// Pill-shaped search bar with a people-search icon.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kensa_9gaze/app/theme.dart';

/// Renders a rounded search bar with a leading person-search
/// icon and placeholder text, both at 50% opacity white.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final hintColor = kWhite.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: kSearchBg,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            Icon(Icons.person_search, color: hintColor, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Search by name...',
                style: GoogleFonts.bricolageGrotesque(
                  color: hintColor,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
