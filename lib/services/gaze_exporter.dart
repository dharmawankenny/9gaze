// Gaze collage exporter.
//
// Renders all 9 (or 10 for dual-primary) slot images onto a single
// Canvas at 1080×1080 px (standard mode) or 1080×540 px (compact
// mode), encodes the result as a maximum-quality JPEG, and saves it
// to the device gallery via the `gal` package.
//
// The same normalised transform stored in each [GazeSlot] row is
// applied here, mirroring the matrix used by [GazeSlotImage] so the
// exported collage looks identical to what the user sees on screen.
//
// Export layout:
//   Standard    : 3×3 grid, each cell 360×360 px.
//   Compact     : 3×3 grid, each cell 360×180 px (1080×540 total).
//   Dual-primary: centre cell splits top/bottom into two 360×(cellH/2)
//                 halves — primary on top, primarySecondary below.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/models/slot_key.dart';
import 'package:kensa_9gaze/services/image_storage.dart';
import 'package:kensa_9gaze/services/text_overlay_layout.dart';
import 'package:kensa_9gaze/services/thumbnail_renderer.dart';

/// Renders a gaze collage and saves it to the device gallery.
class GazeExporter {
  GazeExporter._();

  static const _uuid = Uuid();

  /// Grid width / height of the export canvas in pixels.
  static const int kExportGridPx = 1080;

  /// Cell size for standard (non-compact) mode.
  static const int kStandardCellPx = 360;

  /// Cell height for compact mode (half-height cells).
  static const int kCompactCellH = 180;

  /// Exports the collage for [gaze] using [slots] as the image data.
  ///
  /// Renders at full 1080 px resolution, saves as JPEG quality 100
  /// via [gal], and shows a SnackBar/dialog on success or failure.
  ///
  /// The [isCompact] and [isDoublePrimary] flags are read from
  /// [gaze] to determine the layout variant.
  static Future<ExportResult> export({
    required Gaze gaze,
    required List<GazeSlot> slots,
    List<GazeTextOverlay> overlays = const [],
    Locale? locale,
    double? referenceFrameWidth,
  }) async {
    try {
      final bytes = await _renderCollage(
        gaze: gaze,
        slots: slots,
        overlays: overlays,
        locale: locale,
        referenceFrameWidth: referenceFrameWidth,
      );
      final shortId = _uuid.v4().replaceAll('-', '').substring(0, 8);
      final safeName = gaze.name
          .trim()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'[^A-Za-z0-9_]'), '')
          .toLowerCase();
      final normalizedName = safeName.isEmpty ? 'gaze_detail' : safeName;
      final timeTag = DateTime.now().microsecondsSinceEpoch
          .toRadixString(36)
          .substring(4);
      final filename = '9gaze_${normalizedName}_${shortId}_$timeTag.jpg';

      await Gal.putImageBytes(bytes, name: filename, album: '9Gaze');

      return ExportResult(success: true, filename: filename);
    } catch (e) {
      return ExportResult(success: false, error: e.toString());
    }
  }

  // ── Render pipeline ─────────────────────────────────────────

  /// Renders the full collage to a JPEG byte array.
  static Future<Uint8List> _renderCollage({
    required Gaze gaze,
    required List<GazeSlot> slots,
    required List<GazeTextOverlay> overlays,
    Locale? locale,
    double? referenceFrameWidth,
  }) async {
    final isCompact = gaze.isCompact;
    final isDualPrimary = gaze.isDoublePrimary;

    final cellW = kStandardCellPx;
    final cellH = isCompact ? kCompactCellH : kStandardCellPx;
    final canvasW = kExportGridPx;
    final canvasH = cellH * 3;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, canvasW.toDouble(), canvasH.toDouble()),
    );

    // Black background.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasW.toDouble(), canvasH.toDouble()),
      Paint()..color = const ui.Color(0xFF000000),
    );

    final slotMap = {for (final s in slots) s.slotKey: s};

    // Draw all 9 cells in grid order.
    for (var i = 0; i < kGridSlotOrder.length; i++) {
      final key = kGridSlotOrder[i];
      final col = i % 3;
      final row = i ~/ 3;
      final x = col * cellW;
      final y = row * cellH;

      // Centre cell: dual-primary splits top/bottom into two halves.
      if (key == SlotKey.primary && isDualPrimary) {
        // Each half is the full cell width but half the cell height.
        // Standard mode: 360×180 px each. Compact: 360×90 px each.
        final halfH = cellH ~/ 2;

        await _drawSlotCell(
          canvas: canvas,
          slot: slotMap[SlotKey.primary.name],
          cellRect: Rect.fromLTWH(
            x.toDouble(),
            y.toDouble(),
            cellW.toDouble(),
            halfH.toDouble(),
          ),
        );
        await _drawSlotCell(
          canvas: canvas,
          slot: slotMap[SlotKey.primarySecondary.name],
          cellRect: Rect.fromLTWH(
            x.toDouble(),
            (y + halfH).toDouble(),
            cellW.toDouble(),
            halfH.toDouble(),
          ),
        );
      } else {
        await _drawSlotCell(
          canvas: canvas,
          slot: slotMap[key.name],
          cellRect: Rect.fromLTWH(
            x.toDouble(),
            y.toDouble(),
            cellW.toDouble(),
            cellH.toDouble(),
          ),
        );
      }
    }

    // Draw text overlays on top of grid images.
    for (final overlay in overlays) {
      _drawTextOverlay(
        canvas: canvas,
        overlay: overlay,
        canvasW: canvasW.toDouble(),
        canvasH: canvasH.toDouble(),
        locale: locale,
        referenceFrameWidth: referenceFrameWidth,
      );
    }

    // Finalise the picture.
    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(canvasW, canvasH);
    final byteData = await uiImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (byteData == null) {
      throw StateError('Failed to obtain raw RGBA bytes from canvas.');
    }

    // Encode to JPEG at maximum quality using the image package.
    // dart:ui does not support direct JPEG export, so we convert
    // the raw RGBA buffer via the image package.
    final rawBytes = byteData.buffer.asUint8List();
    final encoded = await compute(_encodeJpeg, (rawBytes, canvasW, canvasH));
    return encoded;
  }

  /// Draws a single slot's image (or a black placeholder) into
  /// [cellRect] on [canvas].
  ///
  /// Prefers the 300×300 px pre-cropped thumbnail (already
  /// transformed, so we can just scale-to-fill the cell). Falls back
  /// to decoding the full-resolution image and applying the stored
  /// normalised transform when the thumbnail is absent (legacy slots
  /// or partial generation).
  static Future<void> _drawSlotCell({
    required Canvas canvas,
    required GazeSlot? slot,
    required Rect cellRect,
  }) async {
    if (slot == null) {
      // Empty slot: leave black (already painted as bg).
      return;
    }

    final thumbAbsPath = await ImageStorage.resolveThumbAbsPath(
      slot.imagePath,
      ThumbSize.px300,
    );

    // Fast path: thumbnail already encodes the transform, so we just
    // scale it to fill the cell — no matrix arithmetic needed.
    if (File(thumbAbsPath).existsSync()) {
      final bytes = await File(thumbAbsPath).readAsBytes();
      final codec =
          await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final frame = await codec.getNextFrame();
      final thumbImg = frame.image;

      final src = _computeCoverSrcRect(
        srcW: thumbImg.width.toDouble(),
        srcH: thumbImg.height.toDouble(),
        dstW: cellRect.width,
        dstH: cellRect.height,
      );
      canvas.save();
      canvas.clipRect(cellRect);
      canvas.drawImageRect(thumbImg, src, cellRect, Paint());
      canvas.restore();
      thumbImg.dispose();
      return;
    }

    // Fallback: full-resolution decode + transform application.
    final absPath = await ImageStorage.resolveAbsPath(slot.imagePath);
    final bytes = await File(absPath).readAsBytes();
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
    final frame = await codec.getNextFrame();
    final srcImage = frame.image;

    final sw = slot.sourceWidth.toDouble();
    final sh = slot.sourceHeight.toDouble();
    final fw = cellRect.width;
    final fh = cellRect.height;

    // Compute base scale identical to GazeSlotImage._buildMatrix.
    final hasEyes = slot.eyeLeftX != null;
    double baseScale;
    if (hasEyes) {
      final elx = slot.eyeLeftX! * sw;
      final ely = slot.eyeLeftY! * sh;
      final erx = slot.eyeRightX! * sw;
      final ery = slot.eyeRightY! * sh;
      final span =
          math.sqrt(math.pow(erx - elx, 2) + math.pow(ery - ely, 2));
      baseScale = span > 0 ? fw / span : fw / sw;
    } else {
      baseScale = math.max(fw / sw, fh / sh);
    }

    final totalScale = baseScale * slot.scale;
    final imgCx = slot.translateX * sw;
    final imgCy = slot.translateY * sh;

    canvas.save();
    canvas.clipRect(cellRect);
    canvas.translate(cellRect.left + fw / 2, cellRect.top + fh / 2);
    canvas.rotate(slot.rotation);
    canvas.scale(totalScale, totalScale);
    canvas.translate(-imgCx, -imgCy);
    canvas.drawImage(srcImage, Offset.zero, Paint());
    canvas.restore();
    srcImage.dispose();
  }

  static void _drawTextOverlay({
    required Canvas canvas,
    required GazeTextOverlay overlay,
    required double canvasW,
    required double canvasH,
    Locale? locale,
    double? referenceFrameWidth,
  }) {
    final layout = TextOverlayLayout.compute(
      text: overlay.content,
      textColor: overlay.textColor,
      scale: overlay.scale,
      normalizedX: overlay.x,
      normalizedY: overlay.y,
      frameWidth: canvasW,
      frameHeight: canvasH,
      referenceFrameWidth: referenceFrameWidth,
      locale: locale,
    );

    canvas.save();
    canvas.translate(layout.left, layout.top);
    TextOverlayBoxPainter(
      layout: layout,
      bgColor: overlay.bgColor,
    ).paint(canvas, Size(layout.boxWidth, layout.boxHeight));
    canvas.restore();
  }

  /// Computes source crop rect for BoxFit.cover style drawImageRect.
  ///
  /// Keeps destination aspect ratio by cropping source (never stretching).
  static Rect _computeCoverSrcRect({
    required double srcW,
    required double srcH,
    required double dstW,
    required double dstH,
  }) {
    final srcAspect = srcW / srcH;
    final dstAspect = dstW / dstH;
    if ((srcAspect - dstAspect).abs() < 0.000001) {
      return Rect.fromLTWH(0, 0, srcW, srcH);
    }
    if (srcAspect > dstAspect) {
      final cropW = srcH * dstAspect;
      final left = (srcW - cropW) / 2;
      return Rect.fromLTWH(left, 0, cropW, srcH);
    }
    final cropH = srcW / dstAspect;
    final top = (srcH - cropH) / 2;
    return Rect.fromLTWH(0, top, srcW, cropH);
  }
}

// ── Top-level isolate helpers ────────────────────────────────────
// Must be top-level (not static) for [compute] to serialise them.

/// Encodes raw RGBA bytes to a maximum-quality JPEG byte array.
///
/// Runs in a separate isolate via [compute] to avoid blocking the
/// main thread during the JPEG compression step.
Uint8List _encodeJpeg((Uint8List rawRgba, int width, int height) args) {
  final (rawRgba, width, height) = args;
  final image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rawRgba.buffer,
    format: img.Format.uint8,
    numChannels: 4,
  );
  return Uint8List.fromList(img.encodeJpg(image, quality: 100));
}

// ── Result type ─────────────────────────────────────────────────

/// Holds the outcome of a [GazeExporter.export] call.
class ExportResult {
  const ExportResult({required this.success, this.filename, this.error});

  final bool success;
  final String? filename;
  final String? error;
}
