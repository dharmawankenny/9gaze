// Slot editor screen for fine-tuning gaze-direction slot images.
//
// Opened after the ML Kit auto-fit has been applied (or when the
// user taps an already-filled grid cell). Lets the user pan, pinch-
// zoom, and rotate the photo within the slot frame using multi-touch
// gestures, then save or discard the changes.
//
// The editor maintains a local copy of the transform state and
// persists it to the DB only on explicit "Save". "Reset" snaps back
// to the auto-fit recommended transform stored on the slot row.
//
// Guide overlay:
//   - Horizontal eye-line at 50% frame height.
//   - Vertical centre line at 50% frame width.
//   - Subtle white border around the frame.

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/db/database_provider.dart';
import 'package:kensa_9gaze/models/slot_key.dart';
import 'package:kensa_9gaze/repositories/gaze_slots_repository.dart';
import 'package:kensa_9gaze/services/face_aligner.dart';
import 'package:kensa_9gaze/services/image_storage.dart';
import 'package:kensa_9gaze/services/thumbnail_renderer.dart';
import 'package:kensa_9gaze/widgets/gaze_slot_image.dart';

/// Full-screen modal for adjusting pan/zoom/rotation of a slot photo.
///
/// [slot] is the current DB row. [gazeId] and [slotKey] are needed
/// when the user replaces the photo from within the editor.
/// [isCompact] determines the slot's aspect ratio (1:1 vs 2:1).
class SlotEditorScreen extends StatefulWidget {
  const SlotEditorScreen({
    super.key,
    required this.slot,
    required this.gazeId,
    required this.slotKey,
    this.isCompact = false,
  });

  final GazeSlot slot;
  final int gazeId;
  final SlotKey slotKey;
  final bool isCompact;

  @override
  State<SlotEditorScreen> createState() => _SlotEditorScreenState();
}

class _SlotEditorScreenState extends State<SlotEditorScreen> {
  late final GazeSlotsRepository _repo;

  // ── Mutable transform state ──────────────────────────────────

  /// Normalised horizontal centre (0–1 of source image width).
  late double _translateX;

  /// Normalised vertical centre (0–1 of source image height).
  late double _translateY;

  late double _scale;
  late double _rotation;

  /// Last persisted transform baseline — used by Reset.
  late double _savedTranslateX;
  late double _savedTranslateY;
  late double _savedScale;
  late double _savedRotation;

  // ── Gesture bookkeeping ──────────────────────────────────────

  double _gestureStartScale = 1.0;
  double _gestureStartRotation = 0.0;
  double _gestureStartTx = 0.5;
  double _gestureStartTy = 0.5;
  Offset _gestureFocalStart = Offset.zero;

  /// Captured inside LayoutBuilder; needed for pan delta conversion.
  Size _frameSize = Size.zero;

  bool _saving = false;
  late GazeSlot _currentSlot;

  @override
  void initState() {
    super.initState();
    _repo = GazeSlotsRepository(appDatabase);
    _currentSlot = widget.slot;
    _translateX = widget.slot.translateX;
    _translateY = widget.slot.translateY;
    _scale = widget.slot.scale;
    _rotation = widget.slot.rotation;
    _savedTranslateX = widget.slot.translateX;
    _savedTranslateY = widget.slot.translateY;
    _savedScale = widget.slot.scale;
    _savedRotation = widget.slot.rotation;
  }

  // ── Actions ──────────────────────────────────────────────────

  /// Resets transform to last saved DB values.
  void _handleReset() {
    setState(() {
      _translateX = _savedTranslateX;
      _translateY = _savedTranslateY;
      _scale = _savedScale;
      _rotation = _savedRotation;
    });
  }

  /// Re-centers transform to MLKit auto-detected framing.
  ///
  /// Uses current slot landmarks to recompute auto-fit without
  /// re-running detector.
  void _handleRecenter() {
    final autoFit = _computeAutoFitFromCurrentSlot();
    setState(() {
      _translateX = autoFit.translateX;
      _translateY = autoFit.translateY;
      _scale = autoFit.scale;
      _rotation = autoFit.rotation;
    });
  }

  /// Computes MLKit-like auto-fit from current slot metadata.
  AutoFit _computeAutoFitFromCurrentSlot() {
    final hasEyes =
        _currentSlot.eyeLeftX != null &&
        _currentSlot.eyeLeftY != null &&
        _currentSlot.eyeRightX != null &&
        _currentSlot.eyeRightY != null;
    if (!hasEyes) return AutoFit.identity;
    return FaceAligner.computeAutoFit(
      eyes: EyeLandmarks(
        leftX: _currentSlot.eyeLeftX!,
        leftY: _currentSlot.eyeLeftY!,
        rightX: _currentSlot.eyeRightX!,
        rightY: _currentSlot.eyeRightY!,
      ),
      sourceWidth: _currentSlot.sourceWidth,
      sourceHeight: _currentSlot.sourceHeight,
    );
  }

  /// Persists the current transform to the DB, regenerates all
  /// thumbnails to reflect the new framing, then pops the screen.
  Future<void> _handleSave() async {
    if (_saving) return;
    setState(() => _saving = true);

    await _repo.updateTransform(
      _currentSlot.id,
      translateX: _translateX,
      translateY: _translateY,
      scale: _scale,
      rotation: _rotation,
    );

    // Regenerate thumbnails so list and detail views reflect the
    // updated transform without needing to re-render from full res.
    try {
      await ImageStorage.generateThumbnails(
        relPath: _currentSlot.imagePath,
        params: SlotTransformParams(
          sourceWidth: _currentSlot.sourceWidth,
          sourceHeight: _currentSlot.sourceHeight,
          translateX: _translateX,
          translateY: _translateY,
          scale: _scale,
          rotation: _rotation,
          eyeLeftX: _currentSlot.eyeLeftX,
          eyeLeftY: _currentSlot.eyeLeftY,
          eyeRightX: _currentSlot.eyeRightX,
          eyeRightY: _currentSlot.eyeRightY,
        ),
      );
    } catch (_) {
      // Thumbnail regeneration is best-effort; transform is already
      // persisted and the full-resolution image remains usable.
    }

    if (mounted) Navigator.of(context).pop();
  }

  /// Allows the user to pick a new photo from gallery, re-running
  /// ML detection and replacing the current slot image.
  Future<void> _handleReplaceImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (picked == null || !mounted) return;

    // Delete old file and its thumbnails from disk.
    await ImageStorage.deleteThumbnails(_currentSlot.imagePath);
    await ImageStorage.deleteSlotFile(_currentSlot.imagePath);

    // Copy new file into the app sandbox.
    final newRelPath = await ImageStorage.copySlotImage(
      sourcePath: picked.path,
      gazeId: widget.gazeId,
      slotKey: widget.slotKey.name,
    );

    // Resolve absolute path and read source dimensions.
    final absPath = await ImageStorage.resolveAbsPath(newRelPath);
    final bytes = await File(absPath).readAsBytes();
    final dims = _parseImageDimensions(bytes);
    final srcW = dims?.$1 ?? _currentSlot.sourceWidth;
    final srcH = dims?.$2 ?? _currentSlot.sourceHeight;

    // Run ML Kit detection on the new image.
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

    // Upsert slot row with new image + auto-fit.
    await _repo.upsert(
      gazeId: widget.gazeId,
      key: widget.slotKey,
      imagePath: newRelPath,
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

    // Evict Flutter's image cache for the old and new paths so the
    // widget tree always loads the freshly copied file.
    await FileImage(File(absPath)).evict();

    // Generate thumbnails for the new image + auto-fit transform.
    try {
      await ImageStorage.generateThumbnails(
        relPath: newRelPath,
        params: SlotTransformParams(
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
        ),
      );
    } catch (_) {
      // Best-effort; full-resolution image remains usable.
    }

    final updated = await _repo.getOne(widget.gazeId, widget.slotKey);
    if (updated != null && mounted) {
      setState(() {
        _currentSlot = updated;
        _translateX = autoFit.translateX;
        _translateY = autoFit.translateY;
        _scale = autoFit.scale;
        _rotation = autoFit.rotation;
        _savedTranslateX = autoFit.translateX;
        _savedTranslateY = autoFit.translateY;
        _savedScale = autoFit.scale;
        _savedRotation = autoFit.rotation;
      });
    }
  }

  // ── Gesture handlers ─────────────────────────────────────────

  void _onScaleStart(ScaleStartDetails d) {
    _gestureStartScale = _scale;
    _gestureStartRotation = _rotation;
    _gestureStartTx = _translateX;
    _gestureStartTy = _translateY;
    _gestureFocalStart = d.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (_frameSize == Size.zero) return;

    final sw = _currentSlot.sourceWidth.toDouble();
    final sh = _currentSlot.sourceHeight.toDouble();
    final fw = _frameSize.width;
    final fh = _frameSize.height;

    // Compute base scale to convert pixel deltas to source coords.
    final hasEyes = _currentSlot.eyeLeftX != null;
    double baseScale;
    if (hasEyes) {
      final elx = _currentSlot.eyeLeftX! * sw;
      final ely = _currentSlot.eyeLeftY! * sh;
      final erx = _currentSlot.eyeRightX! * sw;
      final ery = _currentSlot.eyeRightY! * sh;
      final span = math.sqrt(math.pow(erx - elx, 2) + math.pow(ery - ely, 2));
      baseScale = span > 0 ? fw / span : fw / sw;
    } else {
      baseScale = math.max(fw / sw, fh / sh);
    }

    final totalScale = baseScale * _gestureStartScale;

    // Convert focal point delta (logical px) to normalised source
    // coordinate delta by dividing by (totalScale × sourcePx).
    final dx = d.focalPoint.dx - _gestureFocalStart.dx;
    final dy = d.focalPoint.dy - _gestureFocalStart.dy;
    final newTx = _gestureStartTx - dx / (totalScale * sw);
    final newTy = _gestureStartTy - dy / (totalScale * sh);

    setState(() {
      _scale = (_gestureStartScale * d.scale).clamp(0.2, 10.0);
      _rotation = _gestureStartRotation + d.rotation;
      _translateX = newTx.clamp(0.0, 1.0);
      _translateY = newTy.clamp(0.0, 1.0);
    });
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final aspectRatio = widget.isCompact ? 2.0 : 1.0;

    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        backgroundColor: kDarkBlue,
        leading: IconButton(
          icon: const Icon(Icons.close, color: kWhite),
          tooltip: 'Discard',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          kSlotKeyLabel[widget.slotKey] ?? '',
          style: GoogleFonts.bricolageGrotesque(
            color: kWhite,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _handleSave,
              child: Text(
                _saving ? 'Saving…' : 'Save',
                style: GoogleFonts.bricolageGrotesque(
                  color: kAccentBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pinch to zoom · Drag to pan · Twist to rotate',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  color: kWhite.withValues(alpha: 0.35),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _handleReset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kWhite.withValues(alpha: 0.8),
                        side: BorderSide(
                          color: kWhite.withValues(alpha: 0.15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _handleRecenter,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kWhite.withValues(alpha: 0.8),
                        side: BorderSide(
                          color: kWhite.withValues(alpha: 0.15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Recenter'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _handleReplaceImage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kWhite.withValues(alpha: 0.8),
                        side: BorderSide(
                          color: kWhite.withValues(alpha: 0.15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Replace'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Slot frame ───────────────────────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fw = constraints.maxWidth;
                final fh = fw / aspectRatio;
                _frameSize = Size(fw, fh);
                final frameSize = Size(fw, fh);

                return Center(
                  child: SizedBox(
                    width: fw,
                    height: fh,
                    child: Stack(
                      children: [
                        // Image with live transform.
                        GestureDetector(
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: _onScaleUpdate,
                          child: GazeSlotImage(
                            slot: _currentSlot,
                            renderSize: frameSize,

                            overrideTranslateX: _translateX,
                            overrideTranslateY: _translateY,
                            overrideScale: _scale,
                            overrideRotation: _rotation,
                          ),
                        ),

                        // Guide overlay (non-interactive).
                        IgnorePointer(
                          child: CustomPaint(
                            size: frameSize,
                            painter: _GuideOverlayPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}

// ── Guide overlay painter ────────────────────────────────────────

/// Paints horizontal + vertical centre guide lines and a subtle
/// frame border to help the user align the eye midpoint.
class _GuideOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x40FFFFFF)
      ..strokeWidth = 1.0;

    // Horizontal eye-line.
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      linePaint,
    );

    // Vertical centre line.
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      linePaint,
    );

    // Crosshair at centre.
    const crossR = 12.0;
    final crossPaint = Paint()
      ..color = const Color(0x80FFFFFF)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width / 2 - crossR, size.height / 2),
      Offset(size.width / 2 + crossR, size.height / 2),
      crossPaint,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height / 2 - crossR),
      Offset(size.width / 2, size.height / 2 + crossR),
      crossPaint,
    );

    // Frame border.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = const Color(0x40FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_GuideOverlayPainter old) => false;
}

// ── Image header parsers ──────────────────────────────────────────
// These are module-level helpers so they are accessible from both
// [_SlotEditorScreenState] and can be reused without a dependency
// on internal FaceAligner methods.

/// Extracts (width, height) from raw JPEG or PNG bytes by reading
/// only the image header. Returns null if the format is unrecognised.
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

/// Scans a JPEG byte array for SOF0/SOF1/SOF2 markers to extract
/// the encoded image height and width.
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
