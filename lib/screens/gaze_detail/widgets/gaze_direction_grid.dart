// 3×3 gaze direction grid for the Gaze Detail screen.
//
// Each cell shows either the user's captured photo (via GazeSlotImage)
// or a faded static gaze-face placeholder. Tapping a cell opens the
// pick-image → ML detect → editor pipeline if empty, or opens the
// editor directly if the slot is already filled.
//
// The centre cell has special dual-primary behaviour when
// [isDoublePrimary] is true: it renders as two equal halves
// side-by-side — left for [SlotKey.primary], right for
// [SlotKey.primarySecondary]. Each half is independently tappable.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/db/database_provider.dart';
import 'package:kensa_9gaze/models/slot_key.dart';
import 'package:kensa_9gaze/repositories/gaze_slots_repository.dart';
import 'package:kensa_9gaze/screens/slot_editor/slot_editor_screen.dart';
import 'package:kensa_9gaze/services/face_aligner.dart';
import 'package:kensa_9gaze/services/image_storage.dart';
import 'package:kensa_9gaze/widgets/animated_gaze_face.dart';
import 'package:kensa_9gaze/widgets/gaze_slot_image.dart';

/// Full-width 3×3 grid of tappable gaze-direction cells.
///
/// Uses [Wrap] + [LayoutBuilder] identical to the original
/// [GazeDirectionGrid] so that each cell is exactly 1/3 of the
/// available width and 1:1 square. Reacts to the slot stream for
/// [gazeId] so newly captured photos appear instantly.
class GazeDirectionGrid extends StatefulWidget {
  const GazeDirectionGrid({
    super.key,
    required this.gazeId,
    this.isDoublePrimary = false,
    this.isCompact = false,
  });

  /// ID of the parent [Gaze] row.
  final int gazeId;

  /// When true, the centre cell splits into two half-cells.
  final bool isDoublePrimary;

  /// When true, each cell uses a 2:1 (landscape) aspect ratio.
  final bool isCompact;

  @override
  State<GazeDirectionGrid> createState() => _GazeDirectionGridState();
}

class _GazeDirectionGridState extends State<GazeDirectionGrid> {
  late final GazeSlotsRepository _slotsRepo;
  late Stream<List<GazeSlot>> _stream;

  /// Tracks which slots are being set up to prevent double-taps.
  final Set<SlotKey> _pickingInProgress = {};

  @override
  void initState() {
    super.initState();
    _slotsRepo = GazeSlotsRepository(appDatabase);
    _stream = _slotsRepo.watchAllForGaze(widget.gazeId);
  }

  @override
  void didUpdateWidget(GazeDirectionGrid old) {
    super.didUpdateWidget(old);
    if (old.gazeId != widget.gazeId) {
      _stream = _slotsRepo.watchAllForGaze(widget.gazeId);
    }
  }

  // ── Slot pick pipeline ───────────────────────────────────────

  Future<void> _handleCellTap(
    BuildContext context,
    SlotKey key,
    GazeSlot? existing,
  ) async {
    if (_pickingInProgress.contains(key)) return;

    if (existing != null) {
      await _openEditor(context, key, existing);
      return;
    }

    setState(() => _pickingInProgress.add(key));
    try {
      await _pickAndCreateSlot(context, key);
    } finally {
      if (mounted) setState(() => _pickingInProgress.remove(key));
    }
  }

  Future<void> _pickAndCreateSlot(
    BuildContext context,
    SlotKey key,
  ) async {
    // Capture navigator before async gaps.
    final nav = Navigator.of(context);

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (picked == null || !mounted) return;

    final relPath = await ImageStorage.copySlotImage(
      sourcePath: picked.path,
      gazeId: widget.gazeId,
      slotKey: key.name,
    );

    final absPath = await ImageStorage.resolveAbsPath(relPath);
    final bytes = await File(absPath).readAsBytes();
    final dims = _parseImageDimensions(bytes);
    final srcW = dims?.$1 ?? 1080;
    final srcH = dims?.$2 ?? 1080;

    final eyes = await FaceAligner.detectEyes(absPath);
    final AutoFit autoFit;
    if (eyes != null) {
      autoFit = FaceAligner.computeAutoFit(
        eyes: eyes,
        sourceWidth: srcW,
        sourceHeight: srcH,
      );
    } else {
      autoFit = AutoFit.identity;
    }

    await _slotsRepo.upsert(
      gazeId: widget.gazeId,
      key: key,
      imagePath: relPath,
      sourceWidth: srcW,
      sourceHeight: srcH,
      translateX: autoFit.translateX,
      translateY: autoFit.translateY,
      scale: autoFit.scale,
      rotation: autoFit.rotation,
      eyeLeftX: eyes?.leftX,
      eyeLeftY: eyes?.leftY,
      eyeRightX: eyes?.rightX,
      eyeRightY: eyes?.rightY,
    );

    final created = await _slotsRepo.getOne(widget.gazeId, key);
    if (created != null && mounted) {
      await _openEditorWithNav(nav, key, created);
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    SlotKey key,
    GazeSlot slot,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => SlotEditorScreen(
          slot: slot,
          gazeId: widget.gazeId,
          slotKey: key,
          isCompact: widget.isCompact,
        ),
      ),
    );
  }

  Future<void> _openEditorWithNav(
    NavigatorState nav,
    SlotKey key,
    GazeSlot slot,
  ) async {
    await nav.push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => SlotEditorScreen(
          slot: slot,
          gazeId: widget.gazeId,
          slotKey: key,
          isCompact: widget.isCompact,
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: StreamBuilder<List<GazeSlot>>(
        stream: _stream,
        builder: (context, snapshot) {
          final slots = snapshot.data ?? [];
          final slotMap = {for (final s in slots) s.slotKey: s};

          // LayoutBuilder + Wrap mirrors the original working grid.
          // Wrap gives each child its requested size and wraps rows,
          // so each SizedBox(size, size) is guaranteed square.
          return LayoutBuilder(
            builder: (context, constraints) {
              final cellSize = constraints.maxWidth / 3;
              final cellHeight =
                  widget.isCompact ? cellSize / 2 : cellSize;

              Widget buildCell(SlotKey key) {
                final existing = slotMap[key.name];

                if (key == SlotKey.primary &&
                    widget.isDoublePrimary) {
                  return _DualPrimaryCell(
                    size: cellSize,
                    height: cellHeight,
                    primarySlot: slotMap[SlotKey.primary.name],
                    secondarySlot:
                        slotMap[SlotKey.primarySecondary.name],
                    pickingPrimary: _pickingInProgress
                        .contains(SlotKey.primary),
                    pickingSecondary: _pickingInProgress
                        .contains(SlotKey.primarySecondary),
                    onTapPrimary: () => _handleCellTap(
                      context,
                      SlotKey.primary,
                      slotMap[SlotKey.primary.name],
                    ),
                    onTapSecondary: () => _handleCellTap(
                      context,
                      SlotKey.primarySecondary,
                      slotMap[SlotKey.primarySecondary.name],
                    ),
                  );
                }

                return _GazeCell(
                  key: ValueKey(key.name),
                  direction: kSlotKeyToDirection[key]!,
                  slotKey: key,
                  size: cellSize,
                  height: cellHeight,
                  slot: existing,
                  isPicking: _pickingInProgress.contains(key),
                  onTap: () =>
                      _handleCellTap(context, key, existing),
                );
              }

              return Wrap(
                children: kGridSlotOrder
                    .map(buildCell)
                    .toList(),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Standard single-slot cell ────────────────────────────────────

class _GazeCell extends StatelessWidget {
  const _GazeCell({
    super.key,
    required this.direction,
    required this.slotKey,
    required this.size,
    required this.height,
    required this.onTap,
    this.slot,
    this.isPicking = false,
  });

  final GazeDirection direction;
  final SlotKey slotKey;

  /// Width of this cell (= height when not compact → 1:1 square).
  final double size;

  /// Height of this cell. Equals [size] for standard mode.
  final double height;
  final GazeSlot? slot;
  final bool isPicking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPicking ? null : onTap,
      child: SizedBox(
        width: size,
        height: height,
        child: ColoredBox(
          color: kDarkBlue.withValues(alpha: 0.5),
          child: isPicking
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: kWhite,
                    ),
                  ),
                )
              : slot != null
              ? _FilledCell(
                  slot: slot!,
                  size: size,
                  height: height,
                  label: kSlotKeyLabel[slotKey] ?? '',
                )
              : _EmptyCell(
                  direction: direction,
                  size: size,
                  height: height,
                  label: kSlotKeyLabel[slotKey] ?? '',
                ),
        ),
      ),
    );
  }
}

// ── Dual-primary centre cell ─────────────────────────────────────

class _DualPrimaryCell extends StatelessWidget {
  const _DualPrimaryCell({
    required this.size,
    required this.height,
    required this.onTapPrimary,
    required this.onTapSecondary,
    this.primarySlot,
    this.secondarySlot,
    this.pickingPrimary = false,
    this.pickingSecondary = false,
  });

  final double size;
  final double height;
  final GazeSlot? primarySlot;
  final GazeSlot? secondarySlot;
  final bool pickingPrimary;
  final bool pickingSecondary;
  final VoidCallback onTapPrimary;
  final VoidCallback onTapSecondary;

  @override
  Widget build(BuildContext context) {
    final halfW = size / 2;

    return SizedBox(
      width: size,
      height: height,
      child: Row(
        children: [
          GestureDetector(
            onTap: pickingPrimary ? null : onTapPrimary,
            child: SizedBox(
              width: halfW,
              height: height,
              child: ColoredBox(
                color: kDarkBlue.withValues(alpha: 0.5),
                child: pickingPrimary
                    ? const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kWhite,
                          ),
                        ),
                      )
                    : primarySlot != null
                    ? _FilledCell(
                        slot: primarySlot!,
                        size: halfW,
                        height: height,
                        label: 'Primary',
                      )
                    : _EmptyCell(
                        direction: GazeDirection.primary,
                        size: halfW,
                        height: height,
                        label: 'Primary',
                      ),
              ),
            ),
          ),
          Container(width: 1, height: height, color: kBlack),
          GestureDetector(
            onTap: pickingSecondary ? null : onTapSecondary,
            child: SizedBox(
              width: halfW - 1,
              height: height,
              child: ColoredBox(
                color: kDarkBlue.withValues(alpha: 0.5),
                child: pickingSecondary
                    ? const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kWhite,
                          ),
                        ),
                      )
                    : secondarySlot != null
                    ? _FilledCell(
                        slot: secondarySlot!,
                        size: halfW - 1,
                        height: height,
                        label: 'Primary 2',
                      )
                    : _EmptyCell(
                        direction: GazeDirection.primary,
                        size: halfW - 1,
                        height: height,
                        label: 'Primary 2',
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cell content helpers ─────────────────────────────────────────

/// Cell content when the slot has a captured photo.
class _FilledCell extends StatelessWidget {
  const _FilledCell({
    required this.slot,
    required this.size,
    required this.height,
    required this.label,
  });

  final GazeSlot slot;
  final double size;
  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GazeSlotImage(
          slot: slot,
          renderSize: Size(size, height),
        ),
        Positioned(
          bottom: 6,
          left: 0,
          right: 0,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 7,
              color: kWhite.withValues(alpha: 0.7),
              shadows: [
                const Shadow(blurRadius: 4, color: Colors.black54),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Cell content when no photo has been captured yet.
class _EmptyCell extends StatelessWidget {
  const _EmptyCell({
    required this.direction,
    required this.size,
    required this.height,
    required this.label,
  });

  final GazeDirection direction;
  final double size;
  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Base face size on the smaller dimension (height) so compact
    // mode (height = size/2) never overflows its cell.
    final faceSize = height * 0.45;

    return ClipRect(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.25,
              child: AnimatedGazeFace.static(
                direction: direction,
                size: faceSize,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 8,
                color: kWhite.withValues(alpha: 0.25),
              ),
            ),
            Text(
              'Tap to add',
              textAlign: TextAlign.center,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 7,
                color: kWhite.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Image header helpers ─────────────────────────────────────────

/// Extracts (width, height) from JPEG or PNG raw bytes by reading
/// only the image header. Returns null if format is unrecognised.
(int, int)? _parseImageDimensions(List<int> bytes) {
  if (bytes.length > 4 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8) {
    return _parseJpegDimensions(bytes);
  }
  if (bytes.length > 24 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50) {
    final w = (bytes[16] << 24) |
        (bytes[17] << 16) |
        (bytes[18] << 8) |
        bytes[19];
    final h = (bytes[20] << 24) |
        (bytes[21] << 16) |
        (bytes[22] << 8) |
        bytes[23];
    return (w, h);
  }
  return null;
}

/// Scans a JPEG byte array for SOF0/SOF1/SOF2 markers.
(int, int)? _parseJpegDimensions(List<int> bytes) {
  var i = 2;
  while (i < bytes.length - 8) {
    if (bytes[i] != 0xFF) break;
    final marker = bytes[i + 1];
    final segLen = (bytes[i + 2] << 8) | bytes[i + 3];
    if (marker == 0xC0 ||
        marker == 0xC1 ||
        marker == 0xC2) {
      final h = (bytes[i + 5] << 8) | bytes[i + 6];
      final w = (bytes[i + 7] << 8) | bytes[i + 8];
      return (w, h);
    }
    i += 2 + segLen;
  }
  return null;
}
