// GazeSlotImage: single source of truth for rendering a slot photo.
//
// Renders the source image onto the slot frame using a Matrix4
// transform derived from the normalised [GazeSlot] values. The same
// widget works at any render size (96 px list thumb, full-width detail
// grid, 360 px export cell) — only [renderSize] differs.
//
// Transform derivation:
//   baseScale = frameWidth / eyeSpanPx  (or cover-fit when no eyes)
//   matrix = T(frameCenter) * R(rotation) * S(baseScale*userScale)
//            * T(-eyeMidpointInSourcePx)
//
// The image is decoded once via dart:ui and painted with Canvas.drawImageRect
// so we have full control over the source rect, destination rect, and
// the transform applied — no fighting with Image widget internals.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/services/image_storage.dart';

/// Renders one [GazeSlot] photo inside a clipped frame of [renderSize].
///
/// Pass override values (from the editor's live state) to preview
/// pending transform changes without writing to the DB.
class GazeSlotImage extends StatefulWidget {
  const GazeSlotImage({
    super.key,
    required this.slot,
    required this.renderSize,
    this.overrideTranslateX,
    this.overrideTranslateY,
    this.overrideScale,
    this.overrideRotation,
  });

  final GazeSlot slot;
  final Size renderSize;

  final double? overrideTranslateX;
  final double? overrideTranslateY;
  final double? overrideScale;
  final double? overrideRotation;

  @override
  State<GazeSlotImage> createState() => _GazeSlotImageState();
}

class _GazeSlotImageState extends State<GazeSlotImage> {
  ui.Image? _image;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(GazeSlotImage old) {
    super.didUpdateWidget(old);
    // Reload when the slot's image path changes (e.g. after Replace).
    if (old.slot.imagePath != widget.slot.imagePath) {
      _image = null;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (_loading) return;
    _loading = true;

    try {
      final absPath = await ImageStorage.resolveAbsPath(widget.slot.imagePath);
      final file = File(absPath);
      if (!file.existsSync()) {
        _loading = false;
        return;
      }

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      if (mounted) {
        setState(() {
          _image = frame.image;
        });
      }
    } catch (_) {
      // Silently fail — widget renders nothing when image is missing.
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    if (img == null) {
      return SizedBox(
        width: widget.renderSize.width,
        height: widget.renderSize.height,
      );
    }

    return SizedBox(
      width: widget.renderSize.width,
      height: widget.renderSize.height,
      child: ClipRect(
        child: CustomPaint(
          size: widget.renderSize,
          painter: _SlotPainter(
            image: img,
            slot: widget.slot,
            renderSize: widget.renderSize,
            overrideTranslateX: widget.overrideTranslateX,
            overrideTranslateY: widget.overrideTranslateY,
            overrideScale: widget.overrideScale,
            overrideRotation: widget.overrideRotation,
          ),
        ),
      ),
    );
  }
}

/// Paints the source image onto the slot frame using the normalised
/// transform stored in [slot], with optional editor overrides.
class _SlotPainter extends CustomPainter {
  const _SlotPainter({
    required this.image,
    required this.slot,
    required this.renderSize,
    this.overrideTranslateX,
    this.overrideTranslateY,
    this.overrideScale,
    this.overrideRotation,
  });

  final ui.Image image;
  final GazeSlot slot;
  final Size renderSize;
  final double? overrideTranslateX;
  final double? overrideTranslateY;
  final double? overrideScale;
  final double? overrideRotation;

  @override
  void paint(Canvas canvas, Size size) {
    final fw = size.width;
    final fh = size.height;
    final sw = slot.sourceWidth.toDouble();
    final sh = slot.sourceHeight.toDouble();

    final tx = overrideTranslateX ?? slot.translateX;
    final ty = overrideTranslateY ?? slot.translateY;
    final userScale = overrideScale ?? slot.scale;
    final rotation = overrideRotation ?? slot.rotation;

    // Base scale: size image so eye span fills frame width,
    // or cover-fit when no landmarks available.
    final hasEyes =
        slot.eyeLeftX != null &&
        slot.eyeLeftY != null &&
        slot.eyeRightX != null &&
        slot.eyeRightY != null;

    double baseScale;
    if (hasEyes) {
      final elx = slot.eyeLeftX! * sw;
      final ely = slot.eyeLeftY! * sh;
      final erx = slot.eyeRightX! * sw;
      final ery = slot.eyeRightY! * sh;
      final span = math.sqrt(math.pow(erx - elx, 2) + math.pow(ery - ely, 2));
      baseScale = span > 0 ? fw / span : math.max(fw / sw, fh / sh);
    } else {
      baseScale = math.max(fw / sw, fh / sh);
    }

    final totalScale = baseScale * userScale;

    // Anchor point in source pixels that maps to the frame centre.
    final anchorX = tx * sw;
    final anchorY = ty * sh;

    // Apply transform: translate to frame centre, rotate, scale,
    // then offset so anchorX/Y lands exactly at frame centre.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, fw, fh));
    canvas.translate(fw / 2, fh / 2);
    canvas.rotate(rotation);
    canvas.scale(totalScale, totalScale);
    canvas.translate(-anchorX, -anchorY);

    // Draw the full source image at its natural size.
    canvas.drawImage(image, Offset.zero, Paint());

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SlotPainter old) =>
      old.image != image ||
      old.slot != slot ||
      old.renderSize != renderSize ||
      old.overrideTranslateX != overrideTranslateX ||
      old.overrideTranslateY != overrideTranslateY ||
      old.overrideScale != overrideScale ||
      old.overrideRotation != overrideRotation;
}
