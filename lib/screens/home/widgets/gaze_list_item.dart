// Single row in the gaze list. Supports slide-left-to-delete
// via Dismissible, guarded by a confirmation dialog.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/db/app_database.dart';

/// Formats a [DateTime] as "DD/MM/YYYY HH:mm".
final _kDateFmt = DateFormat('dd/MM/yyyy HH:mm');

/// A single dismissible gaze row.
///
/// Sliding left reveals a red delete background. The swipe
/// triggers [onDeleteConfirmed] only after the user confirms
/// the action in an [AlertDialog]; otherwise the item snaps
/// back via [confirmDismiss].
class GazeListItem extends StatelessWidget {
  const GazeListItem({
    super.key,
    required this.gaze,
    required this.onDeleteConfirmed,
  });

  final Gaze gaze;

  /// Called when the user confirms deletion. The caller owns
  /// the actual DB delete so the list can refresh reactively.
  final VoidCallback onDeleteConfirmed;

  /// Shows a confirmation dialog and returns true only when
  /// the user taps "Delete".
  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete gaze?',
          style: GoogleFonts.bricolageGrotesque(
            color: kWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will permanently remove "${gaze.name}" and cannot '
          'be undone.',
          style: GoogleFonts.bricolageGrotesque(
            color: kWhite.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.bricolageGrotesque(
                color: kWhite.withValues(alpha: 0.5),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.bricolageGrotesque(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = gaze.updatedAt;
    final formattedDate = _kDateFmt.format(timestamp);

    return Dismissible(
      key: ValueKey(gaze.id),
      direction: DismissDirection.endToStart,
      // Snap back if user cancels; call the delete callback
      // only on confirmation so the Stream rebuild removes
      // the tile cleanly.
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDeleteConfirmed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: kSearchBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gaze.name,
              style: GoogleFonts.bricolageGrotesque(
                color: kWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last edited: $formattedDate',
              style: GoogleFonts.bricolageGrotesque(
                color: kWhite.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
