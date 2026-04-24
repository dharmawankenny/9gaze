// Single row in the gaze list. Supports slide-left-to-delete
// via Dismissible, guarded by a confirmation dialog. The full
// row area is tappable via InkWell to navigate to the detail
// screen.
//
// The thumbnail on the left renders a 3x3 micro-grid reflecting
// the gaze's layout flags:
//   Standard    : 96×96 container, 32×32 cells.
//   Compact     : 96×48 container, 32×16 cells.
//   Dual-primary: centre cell splits top/bottom into two 32×16
//                 halves inside the standard 96×96 container.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'dart:io';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/db/database_provider.dart';
import 'package:kensa_9gaze/models/slot_key.dart';
import 'package:kensa_9gaze/repositories/gaze_slots_repository.dart';
import 'package:kensa_9gaze/screens/gaze_detail/gaze_detail_screen.dart';
import 'package:kensa_9gaze/services/image_storage.dart';
import 'package:kensa_9gaze/services/thumbnail_renderer.dart';
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
                // ── Gaze direction mosaic thumbnail ──────────
                // Height shrinks to 48 in compact mode.
                Container(
                  width: 96,
                  height: gaze.isCompact ? 48 : 96,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: kDarkBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _GazeThumbnailGrid(gaze: gaze),
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

/// 3×3 micro-grid thumbnail that mirrors the gaze layout flags.
///
/// Compact mode  → 32×16 cells (container is 96×48).
/// Dual-primary  → centre cell splits top/bottom into two 32×16
///                 halves; other cells stay 32×32.
/// Standard      → 32×32 cells (container is 96×96).
class _GazeThumbnailGrid extends StatefulWidget {
  const _GazeThumbnailGrid({required this.gaze});

  final Gaze gaze;

  @override
  State<_GazeThumbnailGrid> createState() => _GazeThumbnailGridState();
}

class _GazeThumbnailGridState extends State<_GazeThumbnailGrid> {
  late final Stream<List<GazeSlot>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = GazeSlotsRepository(appDatabase)
        .watchAllForGaze(widget.gaze.id);
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = widget.gaze.isCompact;
    final isDualPrimary = widget.gaze.isDoublePrimary;

    // Cell width is always 32 px (container = 96 px wide, 3 cols).
    const cellW = 32.0;
    // Compact cells are half-height; standard cells are square.
    final cellH = isCompact ? 16.0 : 32.0;

    return StreamBuilder<List<GazeSlot>>(
      stream: _stream,
      builder: (context, snapshot) {
        final slots = snapshot.data ?? [];
        final slotMap = {for (final s in slots) s.slotKey: s};

        /// Builds one row of three cells, substituting the dual-
        /// primary split widget for [SlotKey.primary] when needed.
        Row buildRow(List<SlotKey> keys) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: keys.map((k) {
              if (k == SlotKey.primary && isDualPrimary) {
                // Top/bottom split: two 32×(cellH/2) stacked cells.
                final halfH = cellH / 2;
                return SizedBox(
                  width: cellW,
                  height: cellH,
                  child: Column(
                    children: [
                      _ThumbnailCell(
                        direction: GazeDirection.primary,
                        slot: slotMap[SlotKey.primary.name],
                        width: cellW,
                        height: halfH,
                      ),
                      _ThumbnailCell(
                        direction: GazeDirection.primary,
                        slot: slotMap[SlotKey.primarySecondary.name],
                        width: cellW,
                        height: halfH,
                      ),
                    ],
                  ),
                );
              }

              return _ThumbnailCell(
                direction: kSlotKeyToDirection[k]!,
                slot: slotMap[k.name],
                width: cellW,
                height: cellH,
              );
            }).toList(),
          );
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildRow([
              SlotKey.dextroelevation,
              SlotKey.elevation,
              SlotKey.levoelevation,
            ]),
            buildRow([
              SlotKey.dextroversion,
              SlotKey.primary,
              SlotKey.levoversion,
            ]),
            buildRow([
              SlotKey.dextrodepression,
              SlotKey.depression,
              SlotKey.levodepression,
            ]),
          ],
        );
      },
    );
  }
}

/// A single thumbnail cell: 32 px thumbnail if slot filled, icon if not.
///
/// Loads the pre-generated _thumb32.jpg file for performance. Falls
/// back to [GazeSlotImage] (full-res render) when the thumbnail has
/// not yet been generated (e.g. for slots created before this update).
class _ThumbnailCell extends StatefulWidget {
  const _ThumbnailCell({
    required this.direction,
    required this.width,
    required this.height,
    this.slot,
  });

  final GazeDirection direction;
  final double width;
  final double height;
  final GazeSlot? slot;

  @override
  State<_ThumbnailCell> createState() => _ThumbnailCellState();
}

class _ThumbnailCellState extends State<_ThumbnailCell> {
  /// Resolved absolute path for _thumb32.jpg, or null while loading.
  String? _thumbPath;

  /// True once the async path resolution has completed.
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _resolveThumbPath();
  }

  @override
  void didUpdateWidget(_ThumbnailCell old) {
    super.didUpdateWidget(old);
    // Re-resolve when the slot changes (e.g. after replace).
    if (old.slot?.imagePath != widget.slot?.imagePath ||
        old.slot?.updatedAt != widget.slot?.updatedAt) {
      _thumbPath = null;
      _resolved = false;
      _resolveThumbPath();
    }
  }

  /// Resolves the absolute filesystem path for the 32 px thumbnail.
  Future<void> _resolveThumbPath() async {
    final slot = widget.slot;
    if (slot == null) {
      if (mounted) setState(() => _resolved = true);
      return;
    }
    final absPath = await ImageStorage.resolveThumbAbsPath(
      slot.imagePath,
      ThumbSize.px32,
    );
    if (mounted) {
      setState(() {
        _thumbPath = absPath;
        _resolved = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;

    // No slot image — show the faint direction icon placeholder.
    if (slot == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: Opacity(
            opacity: 0.1,
            child: AnimatedGazeFace.static(
              direction: widget.direction,
              size: widget.height * 0.5,
            ),
          ),
        ),
      );
    }

    // Path not yet resolved — show an empty box to avoid flicker.
    if (!_resolved) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    final thumbPath = _thumbPath;
    // Thumbnail exists: render as Image.file (much cheaper than
    // full-res dart:ui decode + custom paint).
    if (thumbPath != null && File(thumbPath).existsSync()) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Image.file(
          File(thumbPath),
          key: ValueKey(
            'thumb32_${slot.id}_${slot.updatedAt.millisecondsSinceEpoch}',
          ),
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
          // Disable gapless playback flicker on key changes.
          gaplessPlayback: true,
        ),
      );
    }

    // Fallback: thumbnail not yet generated — use full-res render.
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: GazeSlotImage(
        slot: slot,
        renderSize: Size(widget.width, widget.height),
      ),
    );
  }
}
