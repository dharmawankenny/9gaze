// Single row in the gaze list. Supports slide-left-to-delete
// via Dismissible, guarded by a confirmation dialog. The full
// row area is tappable via InkWell to navigate to the detail
// screen.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/screens/gaze_detail/gaze_detail_screen.dart';
import 'package:kensa_9gaze/widgets/animated_gaze_face.dart';

/// Formats a [DateTime] as "DD/MM/YYYY HH:mm".
final _kDateFmt = DateFormat('dd/MM/yyyy HH:mm');

/// A single dismissible, tappable gaze row.
///
/// Sliding left reveals a red delete background. The swipe
/// triggers [onDeleteConfirmed] only after the user confirms
/// the action in an [AlertDialog]; otherwise the item snaps
/// back via [confirmDismiss]. Tapping anywhere on the row
/// navigates to [GazeDetailScreen].
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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

  /// Pushes [GazeDetailScreen] for this gaze entry.
  void _handleTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GazeDetailScreen(gaze: gaze),
      ),
    );
  }

  /// Builds a single 3×3 grid cell for the gaze direction mosaic.
  Widget _gazeCell(GazeDirection direction) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Center(
        child: Opacity(
          opacity: 0.1,
          child: AnimatedGazeFace.static(direction: direction, size: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _kDateFmt.format(gaze.updatedAt);

    return Dismissible(
      key: ValueKey(gaze.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDeleteConfirmed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(color: Colors.redAccent),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        // Material + InkWell makes the entire row hittable with a
        // ripple, clipped to the rounded corners.
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _handleTap(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── 3×3 gaze direction mosaic thumbnail ──────
                Container(
                  width: 96,
                  height: 96,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: kDarkBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _gazeCell(GazeDirection.dextroelevation),
                          _gazeCell(GazeDirection.elevation),
                          _gazeCell(GazeDirection.levoelevation),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _gazeCell(GazeDirection.dextroversion),
                          _gazeCell(GazeDirection.primary),
                          _gazeCell(GazeDirection.levoversion),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _gazeCell(GazeDirection.dextrodepression),
                          _gazeCell(GazeDirection.depression),
                          _gazeCell(GazeDirection.levodepression),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Text content ──────────────────────────────
                Expanded(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
