// Gaze detail screen. Displays patient info as read-only text.
// An 'Update' button in the header opens a bottom sheet that
// allows editing and writes changes back to the DB.

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:google_fonts/google_fonts.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/db/database_provider.dart';
import 'package:kensa_9gaze/repositories/gaze_text_overlays_repository.dart';
import 'package:kensa_9gaze/repositories/gaze_slots_repository.dart';
import 'package:kensa_9gaze/repositories/gazes_repository.dart';
import 'package:kensa_9gaze/screens/gaze_detail/update_gaze_sheet.dart';
import 'package:kensa_9gaze/screens/gaze_detail/widgets/gaze_direction_grid.dart';
import 'package:kensa_9gaze/services/gaze_exporter.dart';

/// Detail view for a single [Gaze] entry.
///
/// Displays patient info read-only. The Update button opens
/// [UpdateGazeSheet] which pops back with the refreshed [Gaze]
/// so this screen updates in place without a route push.
class GazeDetailScreen extends StatefulWidget {
  const GazeDetailScreen({super.key, required this.gaze});

  final Gaze gaze;

  @override
  State<GazeDetailScreen> createState() => _GazeDetailScreenState();
}

class _GazeDetailScreenState extends State<GazeDetailScreen> {
  late final GazesRepository _repo;
  late final GazeSlotsRepository _slotsRepo;
  late final GazeTextOverlaysRepository _overlayRepo;

  /// Mutable local copy; updated when the sheet returns a new row.
  late Gaze _current;

  late bool _compactMode;
  late bool _dualPrimary;

  /// Guard against concurrent flag writes.
  bool _flagsLoading = false;

  /// Guard against concurrent export calls.
  bool _exporting = false;
  bool _exportSuccessFlash = false;

  /// Whether the grid is in drag-reorder edit mode.
  bool _isEditMode = false;

  /// Guard against concurrent save-edits calls.
  bool _savingEdits = false;

  /// Callback set by the grid to let this screen trigger commitEdits.
  VoidCallback? _commitEdits;

  /// Slot key updates captured from grid commit.
  Map<int, String> _pendingSlotChanges = {};

  /// Local overlay drafts used only in edit mode.
  List<_OverlayDraft> _overlayDrafts = [];
  int _overlayLocalIdSeed = -1;
  int? _selectedOverlayId;
  double _scaleStart = 1.0;

  @override
  void initState() {
    super.initState();
    _repo = GazesRepository(appDatabase);
    _slotsRepo = GazeSlotsRepository(appDatabase);
    _overlayRepo = GazeTextOverlaysRepository(appDatabase);
    _current = widget.gaze;
    _compactMode = _current.isCompact;
    _dualPrimary = _current.isDoublePrimary;
  }

  /// Persists both flag values to the DB, updating local state
  /// optimistically so the UI responds instantly.
  ///
  /// The two flags are mutually exclusive: enabling one forces the
  /// other off. This is enforced here so both the DB write and the
  /// local state stay consistent regardless of which toggle fired.
  Future<void> _handleFlagChanged({bool? compact, bool? doublePrimary}) async {
    if (_flagsLoading) return;

    // Mutual exclusion: turning one on always turns the other off.
    late final bool nextCompact;
    late final bool nextDouble;
    if (compact != null) {
      nextCompact = compact;
      nextDouble = compact ? false : _dualPrimary;
    } else if (doublePrimary != null) {
      nextDouble = doublePrimary;
      nextCompact = doublePrimary ? false : _compactMode;
    } else {
      nextCompact = _compactMode;
      nextDouble = _dualPrimary;
    }

    setState(() {
      _compactMode = nextCompact;
      _dualPrimary = nextDouble;
      _flagsLoading = true;
    });

    await _repo.updateFlags(
      _current.id,
      isCompact: nextCompact,
      isDoublePrimary: nextDouble,
    );

    if (mounted) setState(() => _flagsLoading = false);
  }

  /// Renders the 3×3 collage and saves it to the device gallery.
  ///
  /// Fetches all slot rows for the current gaze, delegates rendering
  /// to [GazeExporter], and shows a SnackBar with the result.
  Future<void> _handleSaveToGallery() async {
    if (_exporting) return;
    setState(() {
      _exporting = true;
      _exportSuccessFlash = false;
    });

    try {
      final slots = await _slotsRepo.getAllForGaze(_current.id);
      final overlays = await _overlayRepo.getForGaze(_current.id);
      final result = await GazeExporter.export(
        gaze: _current,
        slots: slots,
        overlays: overlays,
      );

      if (!mounted) return;
      if (result.success) {
        setState(() => _exportSuccessFlash = true);
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() => _exportSuccessFlash = false);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'Export failed: ${result.error}',
              style: GoogleFonts.bricolageGrotesque(color: kWhite),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// Enters or exits edit mode. On exit without save, the grid
  /// discards pending changes automatically via [isEditMode] flip.
  Future<void> _handleToggleEditMode() async {
    if (_savingEdits) return;
    if (_isEditMode) {
      setState(() {
        _isEditMode = false;
        _overlayDrafts = [];
        _selectedOverlayId = null;
        _pendingSlotChanges = {};
      });
      return;
    }
    final rows = await _overlayRepo.getForGaze(_current.id);
    if (!mounted) return;
    setState(() {
      _isEditMode = true;
      _overlayDrafts = rows
          .map(
            (r) => _OverlayDraft(
              localId: r.id,
              text: r.content,
              x: r.x,
              y: r.y,
              scale: r.scale,
              textColor: r.textColor,
              bgColor: r.bgColor,
              zIndex: r.zIndex,
            ),
          )
          .toList();
      _selectedOverlayId = _overlayDrafts.isEmpty
          ? null
          : _overlayDrafts.last.localId;
      _pendingSlotChanges = {};
    });
  }

  void _captureSlotEditChanges(Map<int, String> changes) {
    _pendingSlotChanges = changes;
  }

  Future<void> _handleSaveAllEdits() async {
    if (_savingEdits) return;
    _commitEdits?.call();
    setState(() => _savingEdits = true);
    try {
      if (_pendingSlotChanges.isNotEmpty) {
        await _slotsRepo.reorderSlots(_pendingSlotChanges);
      }
      final overlayRows = _overlayDrafts
          .asMap()
          .entries
          .map(
            (entry) => GazeTextOverlaysCompanion.insert(
              gazeId: _current.id,
              content: Value(entry.value.text),
              x: Value(entry.value.x),
              y: Value(entry.value.y),
              scale: Value(entry.value.scale),
              textColor: Value(entry.value.textColor),
              bgColor: Value(entry.value.bgColor),
              zIndex: Value(entry.key),
              updatedAt: Value(DateTime.now()),
            ),
          )
          .toList();
      await _overlayRepo.replaceAllForGaze(_current.id, overlayRows);
    } finally {
      if (mounted) {
        setState(() {
          _savingEdits = false;
          _isEditMode = false;
          _overlayDrafts = [];
          _selectedOverlayId = null;
          _pendingSlotChanges = {};
        });
      }
    }
  }

  /// Opens the update sheet and refreshes [_current] on save.
  Future<void> _handleOpenUpdateSheet() async {
    final updated = await showModalBottomSheet<Gaze>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => UpdateGazeSheet(gaze: _current),
    );

    if (updated != null && mounted) {
      setState(() => _current = updated);
    }
  }

  void _handleAddOverlay() {
    if (!_isEditMode) return;
    final draft = _OverlayDraft(
      localId: _overlayLocalIdSeed--,
      text: 'Text',
      x: 0.5,
      y: 0.5,
      scale: 1.0,
      textColor: 0xFFFFFFFF,
      bgColor: 0xAA000000,
      zIndex: _overlayDrafts.length,
    );
    setState(() {
      _overlayDrafts = [..._overlayDrafts, draft];
      _selectedOverlayId = draft.localId;
    });
  }

  void _handleDeleteOverlay() {
    final id = _selectedOverlayId;
    if (id == null) return;
    setState(() {
      _overlayDrafts = _overlayDrafts.where((o) => o.localId != id).toList();
      _selectedOverlayId = _overlayDrafts.isEmpty
          ? null
          : _overlayDrafts.last.localId;
    });
  }

  _OverlayDraft? get _selectedOverlay {
    final id = _selectedOverlayId;
    if (id == null) return null;
    for (final ov in _overlayDrafts) {
      if (ov.localId == id) return ov;
    }
    return null;
  }

  Widget _buildOverlayLayer(double gridWidth, double gridHeight) {
    final overlays = _isEditMode ? _overlayDrafts : null;
    if (_isEditMode) {
      return Stack(
        children: overlays!.map((ov) {
          final isSelected = ov.localId == _selectedOverlayId;
          final left = (ov.x * gridWidth).clamp(0.0, gridWidth - 24);
          final top = (ov.y * gridHeight).clamp(0.0, gridHeight - 24);
          // Keep text scale proportional to grid width so export can
          // mirror it 1:1 by using the same width ratio.
          final fontSize = (gridWidth * 0.04) * ov.scale;
          return Positioned(
            left: left,
            top: top,
            child: GestureDetector(
              onTap: () => setState(() => _selectedOverlayId = ov.localId),
              onScaleStart: (_) => _scaleStart = ov.scale,
              onScaleUpdate: (d) {
                setState(() {
                  ov.scale = (_scaleStart * d.scale).clamp(0.5, 4.0);
                  ov.x = (ov.x + d.focalPointDelta.dx / gridWidth).clamp(
                    0.0,
                    1.0,
                  );
                  ov.y = (ov.y + d.focalPointDelta.dy / gridHeight).clamp(
                    0.0,
                    1.0,
                  );
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: ov.bgColor != null
                      ? Color(ov.bgColor!)
                      : Colors.transparent,
                  border: isSelected
                      ? Border.all(color: kAccentBlue, width: 1.5)
                      : null,
                ),
                child: Text(
                  ov.text,
                  style: GoogleFonts.bricolageGrotesque(
                    color: Color(ov.textColor),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }
    return StreamBuilder<List<GazeTextOverlay>>(
      stream: _overlayRepo.watchForGaze(_current.id),
      builder: (_, snap) {
        final rows = snap.data ?? const <GazeTextOverlay>[];
        return Stack(
          children: rows.map((ov) {
            final left = (ov.x * gridWidth).clamp(0.0, gridWidth - 24);
            final top = (ov.y * gridHeight).clamp(0.0, gridHeight - 24);
            return Positioned(
              left: left,
              top: top,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: ov.bgColor != null
                      ? Color(ov.bgColor!)
                      : Colors.transparent,
                ),
                child: Text(
                  ov.content,
                  style: GoogleFonts.bricolageGrotesque(
                    color: Color(ov.textColor),
                    fontSize: (gridWidth * 0.04) * ov.scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEditBottomPanel() {
    const textSwatches = <int>[
      0xFFFFFFFF,
      0xFF000000,
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF,
      0xFFFFFF00,
    ];
    const bgSwatches = <int?>[
      null,
      0xAA000000,
      0xAAFFFFFF,
      0xAAFF0000,
      0xAA00FF00,
      0xAA0000FF,
    ];
    final selected = _selectedOverlay;
    final screenH = MediaQuery.of(context).size.height;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        // Lift panel above keyboard.
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: kDarkBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Hard cap prevents RenderFlex overflow on small heights.
              maxHeight: screenH * 0.4,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _handleAddOverlay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDarkBlue,
                        foregroundColor: kWhite,
                        side: BorderSide(color: kWhite.withValues(alpha: 0.2)),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Text'),
                    ),
                    const SizedBox(width: 8),
                    if (selected != null)
                      ElevatedButton.icon(
                        onPressed: _handleDeleteOverlay,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDarkBlue,
                          foregroundColor: kWhite,
                          side: BorderSide(
                            color: kWhite.withValues(alpha: 0.2),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete'),
                      ),
                  ],
                ),
                if (selected != null) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    key: ValueKey(selected.localId),
                    initialValue: selected.text,
                    onChanged: (v) {
                      selected.text = v;
                      setState(() {});
                    },
                    style: GoogleFonts.bricolageGrotesque(color: kWhite),
                    decoration: const InputDecoration(
                      hintText: 'Overlay text',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: textSwatches
                        .map(
                          (c) => _SwatchDot(
                            color: Color(c),
                            selected: selected.textColor == c,
                            onTap: () {
                              selected.textColor = c;
                              setState(() {});
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: bgSwatches
                        .map(
                          (c) => _SwatchDot(
                            color: c == null ? Colors.transparent : Color(c),
                            showBorder: true,
                            selected: selected.bgColor == c,
                            onTap: () {
                              selected.bgColor = c;
                              setState(() {});
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Drag to move. Pinch selected text to scale.',
                    style: GoogleFonts.bricolageGrotesque(
                      color: kWhite.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _isEditMode
          ? _buildEditBottomPanel()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ).copyWith(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _exporting ? null : _handleSaveToGallery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentBlue,
                      foregroundColor: kWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_exporting)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kWhite,
                            ),
                          )
                        else if (_exportSuccessFlash)
                          const Icon(
                            Icons.check_circle_outline,
                            color: kWhite,
                            size: 24,
                          )
                        else
                          const Icon(
                            Icons.download_for_offline_outlined,
                            color: kWhite,
                            size: 24,
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _exporting
                                ? 'Exporting…'
                                : (_exportSuccessFlash
                                      ? 'Exported successfully'
                                      : 'Save to Gallery'),
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kWhite,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isEditMode
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back,
                      color: _isEditMode
                          ? kWhite.withValues(alpha: 0.3)
                          : kWhite,
                      size: 24,
                    ),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gaze Details',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: kWhite,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const Spacer(),
                  // Edit / Save button.
                  _savingEdits
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kWhite,
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: _isEditMode
                              ? _handleSaveAllEdits
                              : _handleToggleEditMode,
                          style: TextButton.styleFrom(
                            backgroundColor: _isEditMode
                                ? kAccentBlue
                                : kWhite.withValues(alpha: 0.08),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            _isEditMode ? 'Save' : 'Edit',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kWhite,
                            ),
                          ),
                        ),
                  if (_isEditMode) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _handleToggleEditMode,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 14,
                          color: kWhite.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ] else
                    const SizedBox(width: 8),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── 3×3 gaze direction grid ───────────────────────
            GazeDirectionGrid(
              gazeId: _current.id,
              isDoublePrimary: _dualPrimary,
              isCompact: _compactMode,
              isEditMode: _isEditMode,
              onDoublePrimaryEnabled: () =>
                  _handleFlagChanged(doublePrimary: true),
              onSaveEdits: _captureSlotEditChanges,
              onCommitEditsBound: (fn) => _commitEdits = fn,
              overlayBuilder: _buildOverlayLayer,
            ),

            // ── Sections below greyed out in edit mode ────────
            Expanded(
              child: AnimatedOpacity(
                opacity: _isEditMode ? 0.25 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: _isEditMode,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),

                        // ── Settings island ───────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ).add(const EdgeInsets.only(top: 16)),
                            decoration: BoxDecoration(
                              color: kDarkBlue,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _ToggleRow(
                                    label: 'Compact Mode?',
                                    value: _compactMode,
                                    onChanged: (v) =>
                                        _handleFlagChanged(compact: v),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  color: kWhite.withValues(alpha: 0.08),
                                ),
                                Expanded(
                                  child: _ToggleRow(
                                    label: 'Dual Primary?',
                                    value: _dualPrimary,
                                    onChanged: (v) =>
                                        _handleFlagChanged(doublePrimary: v),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Patient Info card ─────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: kDarkBlue,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Opacity(
                                      opacity: 0.5,
                                      child: Text(
                                        'Patient Info',
                                        style: GoogleFonts.bricolageGrotesque(
                                          fontSize: 12,
                                          color: kWhite,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: _handleOpenUpdateSheet,
                                      style: TextButton.styleFrom(
                                        backgroundColor: kBlack,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Update',
                                        style: GoogleFonts.bricolageGrotesque(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: kWhite,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _current.name,
                                  style: GoogleFonts.bricolageGrotesque(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: kWhite,
                                  ),
                                ),
                                if (_current.notes != null) ...[
                                  const SizedBox(height: 4),
                                  Opacity(
                                    opacity: 0.75,
                                    child: Text(
                                      _current.notes!,
                                      style: GoogleFonts.bricolageGrotesque(
                                        fontSize: 14,
                                        color: kWhite,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
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

/// A label with a No/Yes switch displayed in a compact row.
///
/// Shows the [label] above a row containing the current value
/// text ("No" / "Yes") and a [Switch] aligned to the right.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: kWhite.withValues(alpha: 0.4),
          ),
        ),
        Row(
          children: [
            Text(
              value ? 'Yes' : 'No',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kWhite,
              ),
            ),
            const Spacer(),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: kAccentBlue,
              activeTrackColor: kAccentBlue.withValues(alpha: 0.3),
              inactiveThumbColor: kWhite.withValues(alpha: 0.4),
              inactiveTrackColor: kWhite.withValues(alpha: 0.1),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverlayDraft {
  _OverlayDraft({
    required this.localId,
    required this.text,
    required this.x,
    required this.y,
    required this.scale,
    required this.textColor,
    required this.bgColor,
    required this.zIndex,
  });

  final int localId;
  String text;
  double x;
  double y;
  double scale;
  int textColor;
  int? bgColor;
  int zIndex;
}

class _SwatchDot extends StatelessWidget {
  const _SwatchDot({
    required this.color,
    required this.selected,
    this.onTap,
    this.showBorder = false,
  });

  final Color color;
  final bool selected;
  final VoidCallback? onTap;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? kAccentBlue
                : (showBorder
                      ? kWhite.withValues(alpha: 0.25)
                      : Colors.transparent),
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}
