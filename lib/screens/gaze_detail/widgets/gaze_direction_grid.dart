// 3×3 gaze direction grid for the Gaze Detail screen.
//
// Normal mode: tapping empty cell opens multi-photo picker;
// tapping filled cell opens SlotEditorScreen.
//
// Edit mode (isEditMode = true): cells become Draggable/DragTarget
// pairs. Dragging one cell onto another swaps their images in a
// local pending map. The parent calls saveEdits() to flush the
// pending swaps to the DB in a single transaction.
//
// The centre cell has special dual-primary behaviour when
// [isDoublePrimary] is true: it splits top-to-bottom into two equal
// compact halves — top for [SlotKey.primary], bottom for
// [SlotKey.primarySecondary]. Each half is independently tappable
// in normal mode and independently draggable/droppable in edit mode.

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

/// Full-width 3×3 grid of tappable / draggable gaze-direction cells.
///
/// Normal mode: tap empty → multi-photo picker; tap filled → editor.
/// Edit mode  : drag a cell onto another to swap their images.
///              Call [saveEdits] on the returned key to flush swaps
///              to the DB.
class GazeDirectionGrid extends StatefulWidget {
  const GazeDirectionGrid({
    super.key,
    required this.gazeId,
    this.isDoublePrimary = false,
    this.isCompact = false,
    this.isEditMode = false,
    this.onDoublePrimaryEnabled,
    this.onSaveEdits,
    this.onCommitEditsBound,
    this.overlayBuilder,
  });

  /// ID of the parent [Gaze] row.
  final int gazeId;

  /// When true, the centre cell splits into two half-cells.
  final bool isDoublePrimary;

  /// When true, each cell uses a 2:1 (landscape) aspect ratio.
  final bool isCompact;

  /// When true, cells are draggable; taps for pick/edit are disabled.
  final bool isEditMode;

  /// Called when a bulk pick fills both primary slots.
  final VoidCallback? onDoublePrimaryEnabled;

  /// Called when the user saves edit-mode reorders.
  ///
  /// Receives a map of slot DB id → desired final slotKey string
  /// for every row that changed position. The parent is responsible
  /// for calling [GazeSlotsRepository.reorderSlots] with this map.
  final void Function(Map<int, String> changes)? onSaveEdits;

  /// Called once during initState with a callback that the parent
  /// can invoke to trigger [commitEdits] from outside the widget.
  final void Function(VoidCallback trigger)? onCommitEditsBound;

  /// Optional top overlay layer rendered above all slot cells.
  ///
  /// Receives grid width and total grid height.
  final Widget Function(double gridWidth, double gridHeight)? overlayBuilder;

  @override
  State<GazeDirectionGrid> createState() => _GazeDirectionGridState();
}

class _GazeDirectionGridState extends State<GazeDirectionGrid> {
  late final GazeSlotsRepository _slotsRepo;
  late Stream<List<GazeSlot>> _stream;

  /// Tracks which slots are being set up to prevent double-taps.
  final Set<SlotKey> _pickingInProgress = {};

  /// Pending slot-key → slot mapping while in edit mode.
  ///
  /// Populated when edit mode is entered (copy of DB state) and
  /// mutated by drag-swap operations. Flushed to DB on save.
  /// Null when not in edit mode.
  Map<SlotKey, GazeSlot?>? _pendingSlotMap;

  /// Which cell the user is currently hovering a drag over.
  SlotKey? _dragOverKey;

  @override
  void initState() {
    super.initState();
    _slotsRepo = GazeSlotsRepository(appDatabase);
    _stream = _slotsRepo.watchAllForGaze(widget.gazeId);
    // Bind the commitEdits trigger so the parent's Save button can
    // call it without needing access to private state.
    widget.onCommitEditsBound?.call(commitEdits);
  }

  @override
  void didUpdateWidget(GazeDirectionGrid old) {
    super.didUpdateWidget(old);
    if (old.gazeId != widget.gazeId) {
      _stream = _slotsRepo.watchAllForGaze(widget.gazeId);
      _pendingSlotMap = null;
    }
    // Re-bind trigger callback when widget instance changes.
    if (old.onCommitEditsBound != widget.onCommitEditsBound) {
      widget.onCommitEditsBound?.call(commitEdits);
    }
    // Entering edit mode: snapshot current DB state into pending map.
    if (!old.isEditMode && widget.isEditMode) {
      _pendingSlotMap = null; // will be set on first stream snapshot
    }
    // Leaving edit mode without saving: discard pending changes.
    if (old.isEditMode && !widget.isEditMode) {
      _pendingSlotMap = null;
      _dragOverKey = null;
    }
  }

  /// Initialises [_pendingSlotMap] from a fresh DB snapshot if not
  /// already set. Called once when edit mode is first rendered.
  void _initPendingIfNeeded(Map<String, GazeSlot> dbSlotMap) {
    if (_pendingSlotMap != null) return;
    _pendingSlotMap = {
      for (final key in _allEditableKeys()) key: dbSlotMap[key.name],
    };
  }

  /// All slot keys that can participate in drag-swap, including the
  /// 10th slot when double-primary is active.
  List<SlotKey> _allEditableKeys() {
    final keys = List<SlotKey>.from(kGridSlotOrder);
    if (widget.isDoublePrimary &&
        !keys.contains(SlotKey.primarySecondary)) {
      keys.add(SlotKey.primarySecondary);
    }
    return keys;
  }

  /// Swaps the slot data for [keyA] and [keyB] in [_pendingSlotMap].
  void _swapPending(SlotKey keyA, SlotKey keyB) {
    if (keyA == keyB) return;
    final map = _pendingSlotMap;
    if (map == null) return;
    final tmp = map[keyA];
    map[keyA] = map[keyB];
    map[keyB] = tmp;
    setState(() => _dragOverKey = null);
  }

  /// Computes pending changes and fires [onSaveEdits] callback.
  ///
  /// Builds a map of slot DB id → desired final slotKey for every
  /// row whose position changed. Clears pending state afterwards.
  void commitEdits() {
    final pending = _pendingSlotMap;
    if (pending == null) return;

    final targetKeyById = <int, String>{};
    for (final entry in pending.entries) {
      final slot = entry.value;
      if (slot == null) continue;
      final targetKey = entry.key.name;
      if (slot.slotKey != targetKey) {
        targetKeyById[slot.id] = targetKey;
      }
    }

    _pendingSlotMap = null;
    if (targetKeyById.isNotEmpty) {
      widget.onSaveEdits?.call(targetKeyById);
    }
  }

  // ── Slot pick pipeline ───────────────────────────────────────

  /// Handles a tap on a grid cell.
  ///
  /// Filled cell → open [SlotEditorScreen] for adjustment/replace.
  /// Empty cell  → open multi-photo picker, auto-fill in order.
  Future<void> _handleCellTap(
    BuildContext context,
    SlotKey key,
    GazeSlot? existing,
    Map<String, GazeSlot> slotMap,
  ) async {
    if (_pickingInProgress.isNotEmpty) return;

    if (existing != null) {
      await _openEditor(context, key, existing);
      return;
    }

    await _pickAndFillSlots(context, key, slotMap);
  }

  /// Computes the ordered list of empty slots available for filling,
  /// starting from [fromKey] in canonical order.
  ///
  /// The canonical order is [kGridSlotOrder] (slots 1–9) followed by
  /// [SlotKey.primarySecondary] (slot 10). Slots already filled are
  /// skipped. The list always starts at [fromKey]'s position.
  List<SlotKey> _emptySlotsFronKey(
    SlotKey fromKey,
    Map<String, GazeSlot> slotMap,
  ) {
    // Full canonical order including the 10th slot at the end.
    final order = [...kGridSlotOrder];
    if (!order.contains(SlotKey.primarySecondary)) {
      order.add(SlotKey.primarySecondary);
    }

    final startIdx = order.indexOf(fromKey);
    // Slots from tapped position to end, then wrap from beginning,
    // filtered to only empty ones.
    final reordered = [
      ...order.sublist(startIdx),
      ...order.sublist(0, startIdx),
    ];
    return reordered
        .where((k) => slotMap[k.name] == null)
        .toList();
  }

  /// Opens multi-photo picker for up to [availableSlots] photos,
  /// then processes each one sequentially, assigning to slots in
  /// canonical order. Never opens the editor — stays on grid.
  Future<void> _pickAndFillSlots(
    BuildContext context,
    SlotKey fromKey,
    Map<String, GazeSlot> slotMap,
  ) async {
    final targetSlots = _emptySlotsFronKey(fromKey, slotMap);
    if (targetSlots.isEmpty) return;

    final picker = ImagePicker();
    // pickMultipleMedia is the only multi-select API on image_picker
    // 1.x. On Android it opens the system photo picker
    // (ACTION_PICK_IMAGES on API 33+, MediaStore on older).
    // The `limit` param is advisory — the picker UI enforces it on
    // API 33+ but may be ignored on older OS versions; we slice the
    // result array ourselves below to stay within targetSlots.length.
    final picked = await picker.pickMultipleMedia(
      limit: targetSlots.length,
    );
    if (picked.isEmpty || !mounted) return;

    // Mark all target slots (up to picked count) as in-progress so
    // the grid shows spinners immediately on each affected cell.
    final assignSlots = targetSlots.take(picked.length).toList();
    setState(() => _pickingInProgress.addAll(assignSlots));

    // If picked count fills both primary slots, enable dual-primary
    // on the parent before processing so the grid layout updates.
    final willFillSecondary =
        assignSlots.contains(SlotKey.primarySecondary);
    if (willFillSecondary && !widget.isDoublePrimary) {
      widget.onDoublePrimaryEnabled?.call();
    }

    // Process each photo sequentially to avoid saturating the ML
    // detector and file system with concurrent operations.
    for (var i = 0; i < assignSlots.length; i++) {
      final key = assignSlots[i];
      final file = picked[i];

      try {
        await _processOneSlot(key: key, sourcePath: file.path);
      } catch (_) {
        // Individual slot failures are silent — the slot stays
        // empty and the user can retry by tapping it again.
      } finally {
        if (mounted) setState(() => _pickingInProgress.remove(key));
      }
    }
  }

  /// Copies [sourcePath] into app storage, runs ML detection, and
  /// upserts the resulting [GazeSlot] row for [key].
  Future<void> _processOneSlot({
    required SlotKey key,
    required String sourcePath,
  }) async {
    final relPath = await ImageStorage.copySlotImage(
      sourcePath: sourcePath,
      gazeId: widget.gazeId,
      slotKey: key.name,
    );

    final absPath = await ImageStorage.resolveAbsPath(relPath);
    final bytes = await File(absPath).readAsBytes();
    final dims = _parseImageDimensions(bytes);
    final srcW = dims?.$1 ?? 1080;
    final srcH = dims?.$2 ?? 1080;

    final eyes = await FaceAligner.detectEyes(absPath);
    final autoFit = eyes != null
        ? FaceAligner.computeAutoFit(
            eyes: eyes,
            sourceWidth: srcW,
            sourceHeight: srcH,
          )
        : AutoFit.identity;

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
  }

  /// Opens [SlotEditorScreen] for manual adjustment of a filled slot.
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

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: StreamBuilder<List<GazeSlot>>(
        stream: _stream,
        builder: (context, snapshot) {
          final dbSlots = snapshot.data ?? [];
          final dbSlotMap = {for (final s in dbSlots) s.slotKey: s};

          // In edit mode: initialise pending map from DB snapshot
          // on first render, then use pending map for display.
          if (widget.isEditMode) {
            _initPendingIfNeeded(dbSlotMap);
          }

          // Displayed slot map: pending in edit mode, DB otherwise.
          final displayMap = widget.isEditMode && _pendingSlotMap != null
              ? {
                  for (final e in _pendingSlotMap!.entries)
                    e.key.name: e.value,
                }
              : dbSlotMap;

          return LayoutBuilder(
            builder: (context, constraints) {
              final cellSize = constraints.maxWidth / 3;
              final cellHeight =
                  widget.isCompact ? cellSize / 2 : cellSize;

              Widget buildCell(SlotKey key) {
                final slot = displayMap[key.name];

                // Dual-primary centre cell.
                if (key == SlotKey.primary && widget.isDoublePrimary) {
                  if (widget.isEditMode) {
                    // In edit mode each half is its own drag target.
                    return _buildDualPrimaryEditCell(
                      cellSize,
                      displayMap,
                    );
                  }
                  return _DualPrimaryCell(
                    size: cellSize,
                    height: cellHeight,
                    primarySlot: displayMap[SlotKey.primary.name],
                    secondarySlot:
                        displayMap[SlotKey.primarySecondary.name],
                    pickingPrimary: _pickingInProgress
                        .contains(SlotKey.primary),
                    pickingSecondary: _pickingInProgress
                        .contains(SlotKey.primarySecondary),
                    onTapPrimary: () => _handleCellTap(
                      context,
                      SlotKey.primary,
                      dbSlotMap[SlotKey.primary.name],
                      dbSlotMap,
                    ),
                    onTapSecondary: () => _handleCellTap(
                      context,
                      SlotKey.primarySecondary,
                      dbSlotMap[SlotKey.primarySecondary.name],
                      dbSlotMap,
                    ),
                  );
                }

                if (widget.isEditMode) {
                  return _buildDragCell(
                    key: key,
                    slot: slot,
                    size: cellSize,
                    height: cellHeight,
                  );
                }

                return _GazeCell(
                  key: ValueKey(key.name),
                  direction: kSlotKeyToDirection[key]!,
                  slotKey: key,
                  size: cellSize,
                  height: cellHeight,
                  slot: slot,
                  isPicking: _pickingInProgress.contains(key),
                  onTap: () => _handleCellTap(
                    context,
                    key,
                    dbSlotMap[key.name],
                    dbSlotMap,
                  ),
                );
              }

              final gridHeight = cellHeight * 3;
              final gridContent = Wrap(
                children: kGridSlotOrder.map(buildCell).toList(),
              );
              if (widget.overlayBuilder == null) {
                return gridContent;
              }
              return SizedBox(
                width: constraints.maxWidth,
                height: gridHeight,
                child: Stack(
                  children: [
                    Positioned.fill(child: gridContent),
                    Positioned.fill(
                      child: widget.overlayBuilder!(
                        constraints.maxWidth,
                        gridHeight,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Builds a single draggable + drop-target cell for edit mode.
  Widget _buildDragCell({
    required SlotKey key,
    required GazeSlot? slot,
    required double size,
    required double height,
  }) {
    final isHoverTarget = _dragOverKey == key;
    final cellContent = _EditModeCell(
      direction: kSlotKeyToDirection[key]!,
      slotKey: key,
      slot: slot,
      size: size,
      height: height,
      isHoverTarget: isHoverTarget,
    );

    return DragTarget<SlotKey>(
      onWillAcceptWithDetails: (details) {
        if (details.data == key) return false;
        setState(() => _dragOverKey = key);
        return true;
      },
      onLeave: (_) => setState(() => _dragOverKey = null),
      onAcceptWithDetails: (details) => _swapPending(details.data, key),
      builder: (_, __, ___) => Draggable<SlotKey>(
        data: key,
        // Ghost shown under the finger while dragging.
        feedback: Opacity(
          opacity: 0.75,
          child: _EditModeCell(
            direction: kSlotKeyToDirection[key]!,
            slotKey: key,
            slot: slot,
            size: size,
            height: height,
            isHoverTarget: false,
          ),
        ),
        // Cell at origin fades while being dragged.
        childWhenDragging: Opacity(opacity: 0.3, child: cellContent),
        child: cellContent,
      ),
    );
  }

  /// Builds the dual-primary centre cell split for edit mode —
  /// two independently draggable/droppable half-cells stacked
  /// top-to-bottom.
  Widget _buildDualPrimaryEditCell(
    double cellSize,
    Map<String, GazeSlot?> displayMap,
  ) {
    final halfH = cellSize / 2;
    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: Column(
        children: [
          _buildDragCell(
            key: SlotKey.primary,
            slot: displayMap[SlotKey.primary.name],
            size: cellSize,
            height: halfH,
          ),
          _buildDragCell(
            key: SlotKey.primarySecondary,
            slot: displayMap[SlotKey.primarySecondary.name],
            size: cellSize,
            height: halfH,
          ),
        ],
      ),
    );
  }
}

// ── Edit-mode draggable cell ─────────────────────────────────────

/// Cell rendered while [GazeDirectionGrid.isEditMode] is true.
///
/// Shows the photo (or empty placeholder) with a drag-handle icon
/// overlay. When [isHoverTarget] is true a highlight border signals
/// the user that dropping here will swap the two cells.
class _EditModeCell extends StatelessWidget {
  const _EditModeCell({
    required this.direction,
    required this.slotKey,
    required this.slot,
    required this.size,
    required this.height,
    required this.isHoverTarget,
  });

  final GazeDirection direction;
  final SlotKey slotKey;
  final GazeSlot? slot;
  final double size;
  final double height;
  final bool isHoverTarget;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background / image.
          ColoredBox(
            color: kDarkBlue.withValues(alpha: 0.5),
            child: slot != null
                ? GazeSlotImage(
                    slot: slot!,
                    renderSize: Size(size, height),
                  )
                : _EmptyCell(
                    direction: direction,
                    size: size,
                    height: height,
                    label: kSlotKeyLabel[slotKey] ?? '',
                  ),
          ),

          // Drag handle icon — top-right corner.
          Positioned(
            top: 4,
            right: 4,
            child: Icon(
              Icons.drag_indicator,
              size: 14,
              color: kWhite.withValues(alpha: 0.6),
            ),
          ),

          // Drop-target highlight overlay.
          if (isHoverTarget)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: kAccentBlue, width: 2),
                color: kAccentBlue.withValues(alpha: 0.15),
              ),
            ),
        ],
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

/// Centre cell that splits top/bottom when [isDoublePrimary] is on.
///
/// Each half is [size] wide and [size/2] tall — identical to a
/// compact-mode cell — and independently tappable.
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

  /// Full cell height (= [size] for non-compact rows).
  final double height;
  final GazeSlot? primarySlot;
  final GazeSlot? secondarySlot;
  final bool pickingPrimary;
  final bool pickingSecondary;
  final VoidCallback onTapPrimary;
  final VoidCallback onTapSecondary;

  @override
  Widget build(BuildContext context) {
    // Each half is half the cell height — equivalent to a compact
    // cell regardless of the outer isCompact flag.
    final halfH = size / 2;

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        children: [
          // ── Top half: primary ───────────────────────────────
          GestureDetector(
            onTap: pickingPrimary ? null : onTapPrimary,
            child: SizedBox(
              width: size,
              height: halfH,
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
                        size: size,
                        height: halfH,
                        label: 'Primary',
                      )
                    : _EmptyCell(
                        direction: GazeDirection.primary,
                        size: size,
                        height: halfH,
                        label: 'Primary',
                      ),
              ),
            ),
          ),
          // ── Bottom half: primary secondary ──────────────────
          GestureDetector(
            onTap: pickingSecondary ? null : onTapSecondary,
            child: SizedBox(
              width: size,
              height: halfH,
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
                        size: size,
                        height: halfH - 1,
                        label: 'Primary 2',
                      )
                    : _EmptyCell(
                        direction: GazeDirection.primary,
                        size: size,
                        height: halfH - 1,
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
///
/// No label overlay — the image speaks for itself. Labels are
/// only shown in the empty-state placeholder.
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

  /// Kept for API symmetry with [_EmptyCell]; not rendered.
  final String label;

  @override
  Widget build(BuildContext context) {
    return GazeSlotImage(slot: slot, renderSize: Size(size, height));
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
  if (bytes.length > 4 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
    return _parseJpegDimensions(bytes);
  }
  if (bytes.length > 24 && bytes[0] == 0x89 && bytes[1] == 0x50) {
    final w =
        (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
    final h =
        (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
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
    if (marker == 0xC0 || marker == 0xC1 || marker == 0xC2) {
      final h = (bytes[i + 5] << 8) | bytes[i + 6];
      final w = (bytes[i + 7] << 8) | bytes[i + 8];
      return (w, h);
    }
    i += 2 + segLen;
  }
  return null;
}
