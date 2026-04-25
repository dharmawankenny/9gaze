// Gaze detail screen. Displays patient info as read-only text.
import 'dart:async';
// An 'Update' button in the header opens a bottom sheet that
// allows editing and writes changes back to the DB.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import 'package:kensa_9gaze/services/image_storage.dart';
import 'package:kensa_9gaze/services/thumbnail_renderer.dart';
import 'package:kensa_9gaze/utils/undo_redo_stack.dart';

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

  /// Edit flow stage:
  /// none -> normal view
  /// menu -> choose Rearrange or Add/Update Text
  /// rearrange -> drag-swap mode
  /// text -> text overlay editing mode
  _EditStage _editStage = _EditStage.none;

  /// Guard against concurrent save-edits calls.
  bool _savingEdits = false;

  /// Callback set by the grid to let this screen trigger commitEdits.
  VoidCallback? _commitEdits;
  VoidCallback? _commitReposition;
  VoidCallback? _undoReposition;
  VoidCallback? _redoReposition;
  VoidCallback? _undoRearrange;
  VoidCallback? _redoRearrange;

  /// Undo/redo availability in reposition mode.
  bool _canUndoReposition = false;
  bool _canRedoReposition = false;

  /// Undo/redo availability in rearrange mode.
  bool _canUndoRearrange = false;
  bool _canRedoRearrange = false;

  /// Slot key updates captured from grid commit.
  Map<int, String> _pendingSlotChanges = {};
  Map<int, SlotTransformPatch> _pendingRepositionChanges = {};

  /// Local overlay drafts used only in edit mode.
  List<_OverlayDraft> _overlayDrafts = [];
  List<_OverlayDraft> _overlayTextBaseline = [];
  int _overlayLocalIdSeed = -1;
  int? _selectedOverlayId;

  /// Undo/redo history for text edit mode.
  final UndoRedoStack<_TextEditorSnapshot> _textHistory = UndoRedoStack();
  _TextEditorSnapshot? _textGestureStart;

  /// Controlled input for selected overlay text.
  final TextEditingController _textInputController = TextEditingController();
  int? _textInputOverlayId;
  bool _isSyncingTextInput = false;

  /// Debounce typing so one typing burst becomes one history step.
  Timer? _textInputDebounce;
  _TextEditorSnapshot? _textTypingStart;


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

  @override
  void dispose() {
    _textInputDebounce?.cancel();
    _textInputController.dispose();
    super.dispose();
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
      _current = _current.copyWith(
        isCompact: nextCompact,
        isDoublePrimary: nextDouble,
      );
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

  bool get _isAnyEditMode => _editStage != _EditStage.none;
  bool get _isRepositionMode => _editStage == _EditStage.reposition;
  bool get _isRearrangeMode => _editStage == _EditStage.rearrange;
  bool get _isTextMode => _editStage == _EditStage.text;
  bool get _isEditMenuMode => _editStage == _EditStage.menu;

  /// Enters edit menu (step 1) or exits all edit modes.
  Future<void> _handleToggleEditMode() async {
    if (_savingEdits) return;
    if (_isAnyEditMode) {
      setState(() {
        _editStage = _EditStage.none;
        _overlayDrafts = [];
        _overlayTextBaseline = [];
        _selectedOverlayId = null;
        _textHistory.clear();
        _textGestureStart = null;
        _textInputDebounce?.cancel();
        _textInputDebounce = null;
        _textTypingStart = null;
        _pendingSlotChanges = {};
        _pendingRepositionChanges = {};
      });
      return;
    }
    final rows = await _overlayRepo.getForGaze(_current.id);
    if (!mounted) return;
    setState(() {
      _editStage = _EditStage.menu;
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
      _overlayTextBaseline = _cloneDrafts(_overlayDrafts);
      _selectedOverlayId = _overlayDrafts.isEmpty
          ? null
          : _overlayDrafts.last.localId;
      _textHistory.clear();
      _textGestureStart = null;
      _textInputDebounce?.cancel();
      _textInputDebounce = null;
      _textTypingStart = null;
      _pendingSlotChanges = {};
      _pendingRepositionChanges = {};
    });
  }

  void _captureRepositionChanges(Map<int, SlotTransformPatch> updates) {
    _pendingRepositionChanges = updates;
  }

  void _setStateSafely(VoidCallback fn) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(fn);
      });
      return;
    }
    setState(fn);
  }

  void _capturePendingRepositionChanges(Map<int, SlotTransformPatch> updates) {
    _setStateSafely(() => _pendingRepositionChanges = updates);
  }

  void _handleEnterRepositionMode() {
    if (_savingEdits) return;
    setState(() {
      _pendingRepositionChanges = {};
      _canUndoReposition = false;
      _canRedoReposition = false;
      _editStage = _EditStage.reposition;
    });
  }

  void _handleCancelRepositionMode() {
    if (_savingEdits) return;
    setState(() {
      _pendingRepositionChanges = {};
      _canUndoReposition = false;
      _canRedoReposition = false;
      _editStage = _EditStage.menu;
    });
  }

  Future<void> _handleSaveRepositionMode() async {
    if (_savingEdits) return;
    _commitReposition?.call();
    setState(() => _savingEdits = true);
    try {
      if (_pendingRepositionChanges.isNotEmpty) {
        final slots = await _slotsRepo.getAllForGaze(_current.id);
        final slotById = {for (final s in slots) s.id: s};
        for (final entry in _pendingRepositionChanges.entries) {
          final slot = slotById[entry.key];
          if (slot == null) continue;
          final patch = entry.value;
          if (!_hasTransformChanged(slot, patch)) {
            continue;
          }
          await _slotsRepo.updateTransform(
            slot.id,
            translateX: patch.translateX,
            translateY: patch.translateY,
            scale: patch.scale,
            rotation: patch.rotation,
          );
          try {
            await ImageStorage.generateThumbnails(
              relPath: slot.imagePath,
              params: SlotTransformParams(
                sourceWidth: slot.sourceWidth,
                sourceHeight: slot.sourceHeight,
                translateX: patch.translateX,
                translateY: patch.translateY,
                scale: patch.scale,
                rotation: patch.rotation,
                eyeLeftX: slot.eyeLeftX,
                eyeLeftY: slot.eyeLeftY,
                eyeRightX: slot.eyeRightX,
                eyeRightY: slot.eyeRightY,
              ),
            );
          } catch (_) {}
        }
      }
      if (!mounted) return;
      // Exit reposition mode only after all DB writes + thumbnails complete,
      // so UI stays in full-resolution rendering while save is in-flight.
      setState(() {
        _pendingRepositionChanges = {};
        _canUndoReposition = false;
        _canRedoReposition = false;
        _editStage = _EditStage.menu;
      });
    } finally {
      if (mounted) setState(() => _savingEdits = false);
    }
  }

  bool _hasTransformChanged(GazeSlot slot, SlotTransformPatch patch) {
    const eps = 0.000001;
    return (slot.translateX - patch.translateX).abs() > eps ||
        (slot.translateY - patch.translateY).abs() > eps ||
        (slot.scale - patch.scale).abs() > eps ||
        (slot.rotation - patch.rotation).abs() > eps;
  }


  bool get _canUndoText => _textHistory.canUndo;
  bool get _canRedoText => _textHistory.canRedo;

  _TextEditorSnapshot _captureTextSnapshot() {
    return _TextEditorSnapshot(
      drafts: _cloneDrafts(_overlayDrafts),
      selectedOverlayId: _selectedOverlayId,
    );
  }

  bool _sameTextSnapshot(_TextEditorSnapshot a, _TextEditorSnapshot b) {
    if (a.selectedOverlayId != b.selectedOverlayId) return false;
    if (a.drafts.length != b.drafts.length) return false;
    const eps = 0.000001;
    for (var i = 0; i < a.drafts.length; i++) {
      final x = a.drafts[i];
      final y = b.drafts[i];
      if (x.localId != y.localId ||
          x.text != y.text ||
          (x.x - y.x).abs() > eps ||
          (x.y - y.y).abs() > eps ||
          (x.scale - y.scale).abs() > eps ||
          x.textColor != y.textColor ||
          x.bgColor != y.bgColor ||
          x.zIndex != y.zIndex) {
        return false;
      }
    }
    return true;
  }

  void _restoreTextSnapshot(_TextEditorSnapshot snapshot) {
    setState(() {
      _overlayDrafts = _cloneDrafts(snapshot.drafts);
      _selectedOverlayId = snapshot.selectedOverlayId;
    });
    _syncTextInputController();
  }

  void _pushTextHistoryIfChanged(_TextEditorSnapshot before) {
    final after = _captureTextSnapshot();
    if (_sameTextSnapshot(before, after)) return;
    _textHistory.push(before);
    _setStateSafely(() {});
  }

  void _syncTextInputController() {
    final selected = _selectedOverlay;
    final nextId = selected?.localId;
    final nextText = selected?.text ?? '';
    if (_textInputOverlayId == nextId && _textInputController.text == nextText) {
      return;
    }
    _isSyncingTextInput = true;
    _textInputOverlayId = nextId;
    _textInputController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
    _isSyncingTextInput = false;
  }

  void _flushPendingTextInputHistory() {
    _textInputDebounce?.cancel();
    _textInputDebounce = null;
    final before = _textTypingStart;
    _textTypingStart = null;
    if (before != null) {
      _pushTextHistoryIfChanged(before);
    }
  }

  void _scheduleTextInputHistoryPush() {
    _textInputDebounce?.cancel();
    _textInputDebounce = Timer(const Duration(milliseconds: 500), () {
      _textInputDebounce = null;
      final before = _textTypingStart;
      _textTypingStart = null;
      if (before != null) {
        _pushTextHistoryIfChanged(before);
      }
    });
  }

  void _undoText() {
    if (_savingEdits) return;
    _flushPendingTextInputHistory();
    final prior = _textHistory.undo(_captureTextSnapshot());
    if (prior == null) return;
    _restoreTextSnapshot(prior);
  }

  void _redoText() {
    if (_savingEdits) return;
    _flushPendingTextInputHistory();
    final next = _textHistory.redo(_captureTextSnapshot());
    if (next == null) return;
    _restoreTextSnapshot(next);
  }

  bool get _hasTextDraftChanges {
    if (_overlayDrafts.length != _overlayTextBaseline.length) return true;
    for (var i = 0; i < _overlayDrafts.length; i++) {
      final a = _overlayDrafts[i];
      final b = _overlayTextBaseline[i];
      if (a.localId != b.localId ||
          a.text != b.text ||
          (a.x - b.x).abs() > 0.000001 ||
          (a.y - b.y).abs() > 0.000001 ||
          (a.scale - b.scale).abs() > 0.000001 ||
          a.textColor != b.textColor ||
          a.bgColor != b.bgColor ||
          a.zIndex != b.zIndex) {
        return true;
      }
    }
    return false;
  }

  bool get _canSaveCurrentEditStage {
    if (_isRepositionMode) return _pendingRepositionChanges.isNotEmpty;
    if (_isRearrangeMode) return _pendingSlotChanges.isNotEmpty;
    if (_isTextMode) return _hasTextDraftChanges;
    return false;
  }

  void _handleEnterRearrangeMode() {
    if (_savingEdits) return;
    setState(() {
      _pendingSlotChanges = {};
      _canUndoRearrange = false;
      _canRedoRearrange = false;
      _editStage = _EditStage.rearrange;
    });
  }

  void _handleCancelRearrangeMode() {
    if (_savingEdits) return;
    setState(() {
      // Grid pending map resets when isEditMode flips true -> false.
      _pendingSlotChanges = {};
      _canUndoRearrange = false;
      _canRedoRearrange = false;
      _editStage = _EditStage.menu;
    });
  }

  Future<void> _handleSaveRearrangeMode() async {
    if (_savingEdits) return;
    _commitEdits?.call();
    setState(() => _savingEdits = true);
    try {
      if (_pendingSlotChanges.isNotEmpty) {
        await _slotsRepo.reorderSlots(_pendingSlotChanges);
      }
      if (!mounted) return;
      setState(() {
        _pendingSlotChanges = {};
        _canUndoRearrange = false;
        _canRedoRearrange = false;
        _editStage = _EditStage.menu;
      });
    } finally {
      if (mounted) setState(() => _savingEdits = false);
    }
  }

  void _handleEnterTextMode() {
    if (_savingEdits) return;
    setState(() {
      _overlayTextBaseline = _cloneDrafts(_overlayDrafts);
      _textHistory.clear();
      _textGestureStart = null;
      _textInputDebounce?.cancel();
      _textInputDebounce = null;
      _textTypingStart = null;
      _editStage = _EditStage.text;
    });
    _syncTextInputController();
  }

  void _handleCancelTextMode() {
    if (_savingEdits) return;
    setState(() {
      _overlayDrafts = _cloneDrafts(_overlayTextBaseline);
      _selectedOverlayId = _overlayDrafts.isEmpty
          ? null
          : _overlayDrafts.last.localId;
      _textHistory.clear();
      _textGestureStart = null;
      _textInputDebounce?.cancel();
      _textInputDebounce = null;
      _textTypingStart = null;
      _editStage = _EditStage.menu;
    });
    _syncTextInputController();
  }

  void _captureSlotEditChanges(Map<int, String> changes) {
    _pendingSlotChanges = changes;
  }

  void _capturePendingReorderChanges(Map<int, String> changes) {
    _setStateSafely(() => _pendingSlotChanges = changes);
  }

  Future<void> _handleSaveTextMode() async {
    if (_savingEdits) return;
    _flushPendingTextInputHistory();
    setState(() => _savingEdits = true);
    try {
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
      if (!mounted) return;
      setState(() {
        _overlayTextBaseline = _cloneDrafts(_overlayDrafts);
        _textHistory.clear();
        _textGestureStart = null;
        _textInputDebounce?.cancel();
        _textInputDebounce = null;
        _textTypingStart = null;
        _editStage = _EditStage.menu;
      });
    } finally {
      if (mounted) {
        setState(() {
          _savingEdits = false;
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
    if (!_isTextMode) return;
    final before = _captureTextSnapshot();
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
    _pushTextHistoryIfChanged(before);
  }

  void _handleDeleteOverlay() {
    final id = _selectedOverlayId;
    if (id == null) return;
    final before = _captureTextSnapshot();
    setState(() {
      _overlayDrafts = _overlayDrafts.where((o) => o.localId != id).toList();
      _selectedOverlayId = _overlayDrafts.isEmpty
          ? null
          : _overlayDrafts.last.localId;
    });
    _pushTextHistoryIfChanged(before);
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
    // Overlay should only capture gestures in text edit mode.
    // In all other modes, pass pointers through so slot taps/drags
    // work even when user touches on top of text overlays.
    final passThroughOverlay = !_isTextMode;
    final overlays = _isTextMode ? _overlayDrafts : null;
    if (_isTextMode) {
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
              onTap: () {
                if (_selectedOverlayId == ov.localId) return;
                final before = _captureTextSnapshot();
                setState(() => _selectedOverlayId = ov.localId);
                _pushTextHistoryIfChanged(before);
              },
              onPanStart: (_) {
                _textGestureStart = _captureTextSnapshot();
              },
              onPanUpdate: (d) {
                setState(() {
                  ov.x = (ov.x + d.delta.dx / gridWidth).clamp(0.0, 1.0);
                  ov.y = (ov.y + d.delta.dy / gridHeight).clamp(0.0, 1.0);
                });
              },
              onPanEnd: (_) {
                final before = _textGestureStart;
                _textGestureStart = null;
                if (before != null) _pushTextHistoryIfChanged(before);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
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
                  if (isSelected) ...[
                    Positioned(
                      left: -7,
                      top: -7,
                      child: _ResizeHandle(
                        onPanStart: () {
                          _textGestureStart = _captureTextSnapshot();
                        },
                        onPanUpdate: (delta) {
                          setState(() {
                            final next = ov.scale + (-(delta.dx + delta.dy) / 220);
                            ov.scale = next.clamp(0.5, 4.0);
                          });
                        },
                        onPanEnd: () {
                          final before = _textGestureStart;
                          _textGestureStart = null;
                          if (before != null) _pushTextHistoryIfChanged(before);
                        },
                      ),
                    ),
                    Positioned(
                      right: -7,
                      bottom: -7,
                      child: _ResizeHandle(
                        onPanStart: () {
                          _textGestureStart = _captureTextSnapshot();
                        },
                        onPanUpdate: (delta) {
                          setState(() {
                            final next = ov.scale + ((delta.dx + delta.dy) / 220);
                            ov.scale = next.clamp(0.5, 4.0);
                          });
                        },
                        onPanEnd: () {
                          final before = _textGestureStart;
                          _textGestureStart = null;
                          if (before != null) _pushTextHistoryIfChanged(before);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      );
    }
    return IgnorePointer(
      ignoring: passThroughOverlay,
      child: StreamBuilder<List<GazeTextOverlay>>(
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
      ),
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
    _syncTextInputController();
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
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_savingEdits || !_canUndoText)
                            ? null
                            : _undoText,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kWhite.withValues(alpha: 0.8),
                          side: BorderSide(
                            color: kWhite.withValues(alpha: 0.15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.undo, size: 16),
                        label: const Text('Undo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_savingEdits || !_canRedoText)
                            ? null
                            : _redoText,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kWhite.withValues(alpha: 0.8),
                          side: BorderSide(
                            color: kWhite.withValues(alpha: 0.15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.redo, size: 16),
                        label: const Text('Redo'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                    controller: _textInputController,
                    onChanged: (v) {
                      if (_isSyncingTextInput) return;
                      final current = _selectedOverlay;
                      if (current == null) return;
                      _textTypingStart ??= _captureTextSnapshot();
                      current.text = v;
                      setState(() {});
                      _scheduleTextInputHistoryPush();
                    },
                    style: GoogleFonts.bricolageGrotesque(color: kWhite),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 3,
                    maxLines: null,
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
                              final before = _captureTextSnapshot();
                              selected.textColor = c;
                              setState(() {});
                              _pushTextHistoryIfChanged(before);
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
                              final before = _captureTextSnapshot();
                              selected.bgColor = c;
                              setState(() {});
                              _pushTextHistoryIfChanged(before);
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

  Widget _buildEditMenuBottomBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _savingEdits ? null : _handleEnterRepositionMode,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kWhite.withValues(alpha: 0.8),
                  side: BorderSide(
                    color: kWhite.withValues(alpha: 0.15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Reposition'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _savingEdits ? null : _handleEnterRearrangeMode,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kWhite.withValues(alpha: 0.8),
                  side: BorderSide(
                    color: kWhite.withValues(alpha: 0.15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Rearrange'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _savingEdits ? null : _handleEnterTextMode,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kWhite.withValues(alpha: 0.8),
                  side: BorderSide(
                    color: kWhite.withValues(alpha: 0.15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Texts'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_OverlayDraft> _cloneDrafts(List<_OverlayDraft> source) {
    return source
        .map(
          (o) => _OverlayDraft(
            localId: o.localId,
            text: o.text,
            x: o.x,
            y: o.y,
            scale: o.scale,
            textColor: o.textColor,
            bgColor: o.bgColor,
            zIndex: o.zIndex,
          ),
        )
        .toList();
  }

  /// Builds the undo/redo bottom bar shown during reposition/rearrange.
  Widget _buildEditUndoRedoBar({
    required bool canUndo,
    required bool canRedo,
    required VoidCallback? onUndo,
    required VoidCallback? onRedo,
  }) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: canUndo ? onUndo : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: canUndo ? kWhite : kWhite.withValues(alpha: 0.3),
                side: BorderSide(
                  color: canUndo
                      ? kWhite.withValues(alpha: 0.5)
                      : kWhite.withValues(alpha: 0.15),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Undo'),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: canRedo ? onRedo : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: canRedo ? kWhite : kWhite.withValues(alpha: 0.3),
                side: BorderSide(
                  color: canRedo
                      ? kWhite.withValues(alpha: 0.5)
                      : kWhite.withValues(alpha: 0.15),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              icon: const Icon(Icons.redo, size: 18),
              label: const Text('Redo'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _isTextMode
          ? _buildEditBottomPanel()
          : _isEditMenuMode
          ? _buildEditMenuBottomBar()
          : _isRepositionMode
          ? _buildEditUndoRedoBar(
              canUndo: _canUndoReposition,
              canRedo: _canRedoReposition,
              onUndo: _undoReposition,
              onRedo: _redoReposition,
            )
          : _isRearrangeMode
          ? _buildEditUndoRedoBar(
              canUndo: _canUndoRearrange,
              canRedo: _canRedoRearrange,
              onUndo: _undoRearrange,
              onRedo: _redoRearrange,
            )
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
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                  if (!_isAnyEditMode)
                    IconButton(
                      onPressed: () {
                        if (_isEditMenuMode) {
                          _handleToggleEditMode();
                          return;
                        }
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: kWhite,
                        size: 24,
                      ),
                      tooltip: 'Back',
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _isAnyEditMode ? 'Edit gaze' : 'Gaze Details',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: kWhite,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const Spacer(),
                  // Right-side actions by edit stage.
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
                      : _isEditMenuMode
                      ? TextButton(
                          onPressed: _handleToggleEditMode,
                          style: TextButton.styleFrom(
                            backgroundColor: kWhite.withValues(alpha: 0.08),
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
                            'Done',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kWhite,
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: _isAnyEditMode
                              ? (_canSaveCurrentEditStage
                                    ? (_isRepositionMode
                                          ? _handleSaveRepositionMode
                                          : _isRearrangeMode
                                          ? _handleSaveRearrangeMode
                                          : _handleSaveTextMode)
                                    : null)
                              : _handleToggleEditMode,
                          style: TextButton.styleFrom(
                            backgroundColor: _isAnyEditMode
                                ? (_canSaveCurrentEditStage
                                      ? kAccentBlue
                                      : kWhite.withValues(alpha: 0.08))
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
                            _isAnyEditMode ? 'Save' : 'Edit',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kWhite,
                            ),
                          ),
                        ),
                  if (_isRearrangeMode || _isTextMode || _isRepositionMode) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _isRepositionMode
                          ? _handleCancelRepositionMode
                          : _isRearrangeMode
                          ? _handleCancelRearrangeMode
                          : _handleCancelTextMode,
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
                  ] else if (!_isEditMenuMode)
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            // ── 3×3 gaze direction grid ───────────────────────
            GazeDirectionGrid(
              gazeId: _current.id,
              isDoublePrimary: _dualPrimary,
              isCompact: _compactMode,
              isEditMode: _isRearrangeMode,
              isRepositionMode: _isRepositionMode,
              isCellTapEnabled: !_isAnyEditMode,
              onDoublePrimaryEnabled: () =>
                  _handleFlagChanged(doublePrimary: true),
              onSaveEdits: _captureSlotEditChanges,
              onPendingReorderChanged: _capturePendingReorderChanges,
              onSaveReposition: _captureRepositionChanges,
              onPendingRepositionChanged: _capturePendingRepositionChanges,
              onCommitEditsBound: (fn) => _commitEdits = fn,
              onCommitRepositionBound: (fn) => _commitReposition = fn,
              onUndoRepositionBound: (fn) => _undoReposition = fn,
              onRedoRepositionBound: (fn) => _redoReposition = fn,
              onUndoRearrangeBound: (fn) => _undoRearrange = fn,
              onRedoRearrangeBound: (fn) => _redoRearrange = fn,
              onRearrangeUndoRedoChanged: (canUndo, canRedo) {
                _setStateSafely(() {
                  _canUndoRearrange = canUndo;
                  _canRedoRearrange = canRedo;
                });
              },
              onRepositionUndoRedoChanged: (canUndo, canRedo) {
                _setStateSafely(() {
                  _canUndoReposition = canUndo;
                  _canRedoReposition = canRedo;
                });
              },
              overlayBuilder: _buildOverlayLayer,
            ),

            // ── Sections below greyed out in edit mode ────────
            Expanded(
              child: AnimatedOpacity(
                opacity: _isAnyEditMode ? 0.25 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: _isAnyEditMode,
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

class _TextEditorSnapshot {
  const _TextEditorSnapshot({
    required this.drafts,
    required this.selectedOverlayId,
  });

  final List<_OverlayDraft> drafts;
  final int? selectedOverlayId;
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

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.onPanUpdate,
    this.onPanStart,
    this.onPanEnd,
  });

  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback? onPanStart;
  final VoidCallback? onPanEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => onPanStart?.call(),
      onPanUpdate: (d) => onPanUpdate(d.delta),
      onPanEnd: (_) => onPanEnd?.call(),
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: kAccentBlue,
          shape: BoxShape.circle,
          border: Border.all(color: kWhite, width: 1.2),
        ),
      ),
    );
  }
}

enum _EditStage { none, menu, reposition, rearrange, text }
