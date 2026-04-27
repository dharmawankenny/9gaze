// Pill-shaped search bar with a people-search icon and live
// text input. Notifies parent of query changes via [onChanged].

import 'package:flutter/material.dart';
import 'package:kensa_9gaze/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kensa_9gaze/app/theme.dart';

/// Rounded search input with a leading person-search icon.
///
/// [controller] and [onChanged] are required so the parent
/// screen can filter the list reactively without duplicating
/// controller ownership.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  /// Text controller owned by the parent.
  final TextEditingController controller;

  /// Called on every keystroke with the current query string.
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final hintColor = kWhite.withValues(alpha: 0.5);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        decoration: BoxDecoration(
          color: kDarkBlue,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            Icon(Icons.person_search, color: hintColor, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: GoogleFonts.bricolageGrotesque(
                  color: kWhite,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: l10n.searchByNameHint,
                  hintStyle: GoogleFonts.bricolageGrotesque(
                    color: hintColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
