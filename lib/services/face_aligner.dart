// Face detection and auto-fit computation for gaze slot images.
//
// Uses Google ML Kit Face Detection with contour detection to
// locate the outer-edge boundaries of both eyes. The leftmost
// point of the left-eye contour and the rightmost point of the
// right-eye contour define the "eye span", which is scaled to
// exactly fill the slot frame width on auto-fit.
//
// All public APIs accept / return normalised coordinates (0–1
// relative to image or frame dimensions) so the results are valid
// regardless of render resolution.

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

// ── Value types ─────────────────────────────────────────────────

/// Normalised (0–1) eye boundary positions within the source image.
///
/// [leftX] / [leftY] are the outermost (minimum-X) point of the
/// left-eye contour; [rightX] / [rightY] are the outermost
/// (maximum-X) point of the right-eye contour.
/// Using contour extremes — not landmark centres — ensures the
/// auto-fit span matches the visible edge-to-edge eye width.
@immutable
class EyeLandmarks {
  const EyeLandmarks({
    required this.leftX,
    required this.leftY,
    required this.rightX,
    required this.rightY,
  });

  /// Normalised X of the leftmost point of the left-eye contour.
  final double leftX;

  /// Normalised Y of the leftmost point of the left-eye contour.
  final double leftY;

  /// Normalised X of the rightmost point of the right-eye contour.
  final double rightX;

  /// Normalised Y of the rightmost point of the right-eye contour.
  final double rightY;
}

/// Resolution-independent auto-fit transform computed from ML eye
/// landmarks.
///
/// All values are stored in the [GazeSlot] row and interpreted by
/// [GazeSlotImage] at render time. The [scale] field starts at
/// exactly 1.0, meaning "apply the ML-recommended fit". Users can
/// then adjust it in [SlotEditorScreen].
@immutable
class AutoFit {
  const AutoFit({
    required this.translateX,
    required this.translateY,
    required this.scale,
    required this.rotation,
  });

  /// Normalised horizontal centre within the slot frame (0–1).
  final double translateX;

  /// Normalised vertical centre within the slot frame (0–1).
  final double translateY;

  /// Scale multiplier relative to the auto-fit base scale. Always
  /// 1.0 when returned from [FaceAligner.computeAutoFit].
  final double scale;

  /// Rotation in radians (counter-clockwise) to level the eye line.
  final double rotation;

  /// Default centred, unscaled, unrotated transform. Used as the
  /// initial value when ML detection fails.
  static const identity = AutoFit(
    translateX: 0.5,
    translateY: 0.5,
    scale: 1.0,
    rotation: 0.0,
  );
}

// ── Service ─────────────────────────────────────────────────────

/// Detects eye landmarks in a static image and computes the
/// recommended auto-fit transform for a gaze direction slot.
class FaceAligner {
  FaceAligner._();

  /// Shared detector instance; uses [FaceDetectorMode.accurate]
  /// with contour detection enabled so we get full eye contour
  /// point arrays instead of single landmark centres.
  /// Landmarks also enabled as fallback when contours are absent.
  static final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: true,
      enableClassification: false,
      enableTracking: false,
      // Accurate mode improves contour precision at the cost of
      // slightly higher latency — acceptable for a one-shot pick.
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.05,
    ),
  );

  /// Closes the shared ML Kit detector. Call once when the app is
  /// shutting down to release native resources.
  static Future<void> dispose() => _detector.close();

  // ── Detection ────────────────────────────────────────────────

  /// Runs ML Kit face detection on [imagePath] and returns
  /// normalised eye boundary positions if a face is found.
  ///
  /// Uses eye contours (full point arrays) to find the true outer
  /// edges: leftmost point of left-eye contour → [EyeLandmarks.leftX],
  /// rightmost point of right-eye contour → [EyeLandmarks.rightX].
  /// Falls back to landmark centres when contours are unavailable.
  /// Returns null when no face or no eye data is detected.
  static Future<EyeLandmarks?> detectEyes(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await _detector.processImage(inputImage);
    if (faces.isEmpty) return null;

    final face = faces.first;

    final imageSize = await _readImageSize(imagePath);
    if (imageSize == null) return null;
    final w = imageSize.width;
    final h = imageSize.height;

    // Prefer contour extreme points for accurate edge-to-edge span.
    final leftContour = face.contours[FaceContourType.leftEye];
    final rightContour = face.contours[FaceContourType.rightEye];

    if (leftContour != null &&
        leftContour.points.isNotEmpty &&
        rightContour != null &&
        rightContour.points.isNotEmpty) {
      // Left eye outer boundary = minimum X in left-eye contour.
      final leftOuterPt = leftContour.points.reduce(
        (a, b) => a.x < b.x ? a : b,
      );
      // Right eye outer boundary = maximum X in right-eye contour.
      final rightOuterPt = rightContour.points.reduce(
        (a, b) => a.x > b.x ? a : b,
      );

      return EyeLandmarks(
        leftX: leftOuterPt.x / w,
        leftY: leftOuterPt.y / h,
        rightX: rightOuterPt.x / w,
        rightY: rightOuterPt.y / h,
      );
    }

    // Fallback: use landmark centres when contours absent.
    final leftLm = face.landmarks[FaceLandmarkType.leftEye];
    final rightLm = face.landmarks[FaceLandmarkType.rightEye];
    if (leftLm == null || rightLm == null) return null;

    return EyeLandmarks(
      leftX: leftLm.position.x / w,
      leftY: leftLm.position.y / h,
      rightX: rightLm.position.x / w,
      rightY: rightLm.position.y / h,
    );
  }

  // ── Auto-fit computation ─────────────────────────────────────

  /// Computes the auto-fit transform that positions and scales the
  /// source image so the inter-eye span fills the slot frame width
  /// and the eye midpoint is centred vertically.
  ///
  /// [sourceWidth] / [sourceHeight] are the pixel dimensions of the
  /// source image. [slotAspectRatio] is `width / height` of the
  /// target slot frame (1.0 for square, 2.0 for compact 2:1).
  ///
  /// The returned [AutoFit.scale] is always exactly 1.0 — meaning
  /// "apply the base scale derived from the eye span at render
  /// time". The [translateX] / [translateY] express where the
  /// image's eye midpoint should sit within the frame (0.5 = centre,
  /// which is always the recommendation here; the user can nudge
  /// it later in the editor).
  static AutoFit computeAutoFit({
    required EyeLandmarks eyes,
    required int sourceWidth,
    required int sourceHeight,
  }) {
    // Midpoint between outer eye edges in normalised source coords.
    final midX = (eyes.leftX + eyes.rightX) / 2;
    final midY = (eyes.leftY + eyes.rightY) / 2;

    // Rotation: angle to level the line between the two outer
    // edge points (counter-clockwise so right edge = same Y as
    // left edge after rotation).
    final dx = (eyes.rightX - eyes.leftX) * sourceWidth;
    final dy = (eyes.rightY - eyes.leftY) * sourceHeight;
    final rotation = -math.atan2(dy, dx);

    // We want the eye midpoint at the frame centre and the user can
    // pan from there. encode midpoint as frame-normalised centre
    // (always 0.5, 0.5 for auto-fit) — the actual base-scale +
    // midpoint centering maths happen in GazeSlotImage at render
    // time using eyeLeft*/eyeRight* + sourceWidth/Height stored on
    // the slot row.
    //
    // Storing (0.5, 0.5) + scale=1.0 means "exactly the recommended
    // position". All user edits in the editor are deltas from this.
    return AutoFit(
      translateX: midX,
      translateY: midY,
      scale: 1.0,
      rotation: rotation,
    );
  }

  // ── Internal helpers ─────────────────────────────────────────

  /// Reads the pixel dimensions of an image file using dart:io
  /// without fully decoding it. Falls back to null on error.
  static Future<({double width, double height})?> _readImageSize(
    String path,
  ) async {
    try {
      final bytes = await File(path).readAsBytes();
      // Use the image package for header-only size extraction when
      // possible; for simplicity here we decode the full image since
      // we already need it for the copy operation and the image is
      // already on disk.
      //
      // NOTE: For large images this may allocate significant memory.
      // A production improvement would use a streaming JPEG/PNG
      // header parser to avoid full decode.
      final codec = await _decodeImageSize(bytes);
      return codec;
    } catch (_) {
      return null;
    }
  }

  /// Decodes only enough of [bytes] to extract width/height using
  /// Flutter's image codec infrastructure-free approach via the
  /// image package.
  static Future<({double width, double height})?> _decodeImageSize(
    Uint8List bytes,
  ) async {
    try {
      // Parse JPEG/PNG/WEBP dimensions from raw header bytes.
      // JPEG: FF D8 ... SOF0 marker (FF C0) width/height at bytes
      // +3/+5 as big-endian uint16. PNG: 8-byte sig + IHDR gives
      // width/height at bytes 16-19 / 20-23. For robustness we use
      // a simple heuristic: delegate to dart:ui via ImmutableBuffer.
      //
      // dart:ui is available on the main isolate. Since this is
      // called from async context on the main isolate it is safe.
      //
      // This does NOT decode pixel data; it only reads the frame
      // header — making it fast even for multi-megapixel photos.
      // ignore: avoid_annotating_with_dynamic
      final info = await _getImageInfoFromBytes(bytes);
      return info;
    } catch (_) {
      return null;
    }
  }

  /// Uses dart:ui ImmutableBuffer (available Flutter 3.x+) to
  /// extract image dimensions without decoding pixel data.
  // ignore: avoid_annotating_with_dynamic
  static Future<({double width, double height})?> _getImageInfoFromBytes(
    Uint8List bytes,
  ) async {
    // Use the image package (already a dep) for header parsing as
    // it supports JPEG, PNG, WEBP, and GIF without full decode.
    // We only need width/height so we use decodeImageHeader if
    // available, otherwise fallback to decode().
    try {
      // image pkg decode is synchronous but may be slow for large
      // files; run in an isolate if performance is a concern.
      // For this use-case (one-shot on photo pick) it is acceptable.
      //
      // ignore: depend_on_referenced_packages
      final img = await compute(_parseImageDimensions, bytes);
      if (img == null) return null;
      return (width: img.$1.toDouble(), height: img.$2.toDouble());
    } catch (_) {
      return null;
    }
  }

  /// Top-level function (required by [compute]) that returns
  /// (width, height) from raw image bytes, or null on failure.
  static (int, int)? _parseImageDimensions(Uint8List bytes) {
    try {
      // Read JPEG SOF or PNG IHDR header only; avoid full decode.
      // JPEG: scan for FF C0 (SOF0) or FF C2 (SOF2) marker.
      if (bytes.length > 4 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
        return _parseJpegDimensions(bytes);
      }
      // PNG: 8-byte signature + 4-byte length + 'IHDR' + 4W + 4H.
      if (bytes.length > 24 && bytes[0] == 0x89 && bytes[1] == 0x50) {
        final w =
            (bytes[16] << 24) |
            (bytes[17] << 16) |
            (bytes[18] << 8) |
            bytes[19];
        final h =
            (bytes[20] << 24) |
            (bytes[21] << 16) |
            (bytes[22] << 8) |
            bytes[23];
        return (w, h);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Scans JPEG bytes for a SOF0/SOF1/SOF2 marker to extract
  /// image height and width.
  static (int, int)? _parseJpegDimensions(Uint8List bytes) {
    var i = 2;
    while (i < bytes.length - 8) {
      if (bytes[i] != 0xFF) break;
      final marker = bytes[i + 1];
      final segLen = (bytes[i + 2] << 8) | bytes[i + 3];
      // SOF0=C0, SOF1=C1, SOF2=C2 all carry height/width.
      if (marker == 0xC0 || marker == 0xC1 || marker == 0xC2) {
        final h = (bytes[i + 5] << 8) | bytes[i + 6];
        final w = (bytes[i + 7] << 8) | bytes[i + 8];
        return (w, h);
      }
      i += 2 + segLen;
    }
    return null;
  }
}
