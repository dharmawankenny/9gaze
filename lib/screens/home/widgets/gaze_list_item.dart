// Single row in the gaze list. Supports slide-left-to-delete
// via Dismissible, guarded by a confirmation dialog. The full
// row area is tappable via InkWell to navigate to the detail
// screen.
//
// The 96x96 thumbnail on the left renders a 3x3 micro-grid
// showing each slot's captured photo (via GazeSlotImage) when
// available, falling back to a faded static gaze-face icon.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/db/database_provider.dart';
import 'package:kensa_9gaze/models/slot_key.dart';
import 'package:kensa_9gaze/repositories/gaze_slots_repository.dart';
import 'package:kensa_9gaze/screens/gaze_detail/gaze_detail_screen.dart';
import 'package:kensa_9gaze/widgets/animated_gaze_face.dart';
import 'package:kensa_9gaze/widgets/gaze_slot_image.dart';

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

  /// Pushes [GazeDetailScreen] for this gaze entry.
  void _handleTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GazeDetailScreen(gaze: gaze)),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _GazeThumbnailGrid(gazeId: gaze.id),
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

// ── Thumbnail grid ───────────────────────────────────────────────

/// 3×3 micro-grid of 32×32 px slot thumbnails.
///
/// Streams slot data for [gazeId] so newly added photos appear
/// in the list without a full rebuild. Falls back to the static
/// gaze-face icon for unfilled slots.
class _GazeThumbnailGrid extends StatefulWidget {
  const _GazeThumbnailGrid({required this.gazeId});

  final int gazeId;

  @override
  State<_GazeThumbnailGrid> createState() => _GazeThumbnailGridState();
}

class _GazeThumbnailGridState extends State<_GazeThumbnailGrid> {
  late final Stream<List<GazeSlot>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = GazeSlotsRepository(appDatabase).watchAllForGaze(widget.gazeId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GazeSlot>>(
      stream: _stream,
      builder: (context, snapshot) {
        final slots = snapshot.data ?? [];
        final slotMap = {for (final s in slots) s.slotKey: s};

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _thumbnailRow(slotMap, [
              SlotKey.dextroelevation,
              SlotKey.elevation,
              SlotKey.levoelevation,
            ]),
            _thumbnailRow(slotMap, [
              SlotKey.dextroversion,
              SlotKey.primary,
              SlotKey.levoversion,
            ]),
            _thumbnailRow(slotMap, [
              SlotKey.dextrodepression,
              SlotKey.depression,
              SlotKey.levodepression,
            ]),
          ],
        );
      },
    );
  }

  Row _thumbnailRow(Map<String, GazeSlot> slotMap, List<SlotKey> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((k) {
        final slot = slotMap[k.name];
        return _ThumbnailCell(direction: kSlotKeyToDirection[k]!, slot: slot);
      }).toList(),
    );
  }
}

/// A single 32×32 thumbnail cell: photo if slot filled, icon if not.
class _ThumbnailCell extends StatelessWidget {
  const _ThumbnailCell({required this.direction, this.slot});

  final GazeDirection direction;
  final GazeSlot? slot;

  @override
  Widget build(BuildContext context) {
    const cellSize = 32.0;

    if (slot != null) {
      return SizedBox(
        width: cellSize,
        height: cellSize,
        child: GazeSlotImage(
          slot: slot!,
          renderSize: const Size(cellSize, cellSize),
        ),
      );
    }

    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: Center(
        child: Opacity(
          opacity: 0.1,
          child: AnimatedGazeFace.static(direction: direction, size: 16),
        ),
      ),
    );
  }
}
