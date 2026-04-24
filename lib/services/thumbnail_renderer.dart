// Thumbnail renderer: applies the slot's normalised transform to
// produce a cropped ui.Image at a given target size.
//
// This mirrors the matrix math used by GazeSlotImage._SlotPainter
// so thumbnails look identical to the on-screen preview. Runs the
// JPEG encode step in a compute isolate to avoid blocking the UI.
//
// Sizing contract:
//   300 × 300 px — export-quality crop (replaces full image in
//                   GazeExporter so export reads less data).
//   192 × 192 px — gaze-detail grid preview cells.
//    32 ×  32 px — home-screen list mosaic cells.
//
// All three sizes use a square frame. Compact-mode slots are still
// rendered into a square crop (the slot's own aspect ratio is
// handled by setting renderHeight < renderWidth when desired, but
// for thumbnail generation we always crop square and let the
// display widget clip/letterbox as needed).

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Supported thumbnail sizes generated per slot image.
enum ThumbSize {
  /// 300 × 300 px — used in the export collage.
  px300(300),

  /// 192 × 192 px — used in the gaze-detail grid preview.
  px192(192),

  /// 32 × 32 px — used in the home-screen mosaic thumbnail.
  px32(32);

  const ThumbSize(this.pixels);

  /// Side length in pixels for this thumbnail size.
  final int pixels;
}

/// Parameters needed to re-apply a slot's transform when cropping.
///
/// All fields mirror the corresponding [GazeSlot] columns so the
/// renderer can be called without importing the full DB model.
class SlotTransformParams {
  const SlotTransformParams({
    required this.sourceWidth,
    required this.sourceHeight,
    required this.translateX,
    required this.translateY,
    required this.scale,
    required this.rotation,
    this.eyeLeftX,
    this.eyeLeftY,
    this.eyeRightX,
    this.eyeRightY,
  });

  final int sourceWidth;
  final int sourceHeight;
  final double translateX;
  final double translateY;
  final double scale;
  final double rotation;
  final double? eyeLeftX;
  final double? eyeLeftY;
  final double? eyeRightX;
  final double? eyeRightY;
}

/// Renders the slot image cropped and transformed into a square
/// JPEG [Uint8List] at [size] × [size] pixels.
///
/// Applies the same matrix as [GazeSlotImage._SlotPainter] so the
/// thumbnail matches the on-screen preview exactly.
Future<Uint8List> renderThumbJpeg({
  required String absSourcePath,
  required SlotTransformParams params,
  required ThumbSize size,
}) async {
  final bytes = await File(absSourcePath).readAsBytes();
  final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
  final frame = await codec.getNextFrame();
  final srcImage = frame.image;

  final px = size.pixels.toDouble();
  final sw = params.sourceWidth.toDouble();
  final sh = params.sourceHeight.toDouble();

  // Compute base scale: eye-span fills frame width, or cover-fit.
  final hasEyes =
      params.eyeLeftX != null &&
      params.eyeLeftY != null &&
      params.eyeRightX != null &&
      params.eyeRightY != null;

  double baseScale;
  if (hasEyes) {
    final elx = params.eyeLeftX! * sw;
    final ely = params.eyeLeftY! * sh;
    final erx = params.eyeRightX! * sw;
    final ery = params.eyeRightY! * sh;
    final span =
        math.sqrt(math.pow(erx - elx, 2) + math.pow(ery - ely, 2));
    baseScale = span > 0 ? px / span : math.max(px / sw, px / sh);
  } else {
    baseScale = math.max(px / sw, px / sh);
  }

  final totalScale = baseScale * params.scale;
  final anchorX = params.translateX * sw;
  final anchorY = params.translateY * sh;

  // Record the draw into a ui.Picture then rasterise.
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(
    recorder,
    ui.Rect.fromLTWH(0, 0, px, px),
  );

  canvas.clipRect(ui.Rect.fromLTWH(0, 0, px, px));
  canvas.translate(px / 2, px / 2);
  canvas.rotate(params.rotation);
  canvas.scale(totalScale, totalScale);
  canvas.translate(-anchorX, -anchorY);
  canvas.drawImage(srcImage, ui.Offset.zero, ui.Paint());

  final picture = recorder.endRecording();
  final thumbImg = await picture.toImage(size.pixels, size.pixels);
  final byteData =
      await thumbImg.toByteData(format: ui.ImageByteFormat.rawRgba);

  srcImage.dispose();
  thumbImg.dispose();

  if (byteData == null) {
    throw StateError('Failed to obtain RGBA bytes for thumbnail.');
  }

  final rawRgba = byteData.buffer.asUint8List();
  // Encode JPEG in a separate isolate to keep the UI thread free.
  return compute(
    _encodeJpegThumb,
    (rawRgba, size.pixels, size.pixels),
  );
}

/// Top-level function required by [compute]: encodes raw RGBA bytes
/// to a JPEG byte array at quality 90 (sufficient for thumbnails).
Uint8List _encodeJpegThumb(
  (Uint8List rawRgba, int width, int height) args,
) {
  final (rawRgba, width, height) = args;
  final image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rawRgba.buffer,
    format: img.Format.uint8,
    numChannels: 4,
  );
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}
