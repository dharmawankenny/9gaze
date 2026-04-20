// Animated (or static) face icon representing all 9 clinical gaze
// directions. In animated mode it cycles through every direction,
// tracing the shape of the digit '9':
//   Primary → Dextroversion → Dextroelevation → Elevation
//   → Levoelevation → Levoversion → Levodepression
//   → Depression → Dextrodepression → (loop)
//
// In static mode it renders a single, fixed [GazeDirection] with no
// animation overhead.
//
// All dimensions are specified in a 64×64 design-space coordinate
// system and scaled uniformly to the requested widget size at
// paint time.
//
// Design spec (64×64 canvas):
//   Face   : circle, diameter 64, centred at (32, 32).
//   Eye    : 16×8 pill (border-radius 4).
//   Left eye origin  (x, y) at primary gaze: (12, 24).
//   Right eye origin (x, y) at primary gaze: (36, 24).
//   Gaze shifts: ±4 px in x for left/right, ±4 px in y for up/down.

import 'package:flutter/material.dart';

// ─── Design constants (all in 64-unit design space) ──────────

/// Diameter of the face circle in design units.
const double _kFaceSize = 64;

/// Eye pill width in design units.
const double _kEyeW = 16;

/// Eye pill height in design units.
const double _kEyeH = 8;

/// Eye pill corner radius in design units.
const double _kEyeR = 4;

/// Left-eye top-left x at primary gaze.
const double _kLeftEyeX = 12;

/// Right-eye top-left x at primary gaze.
const double _kRightEyeX = 36;

/// Both eyes top-left y at primary gaze.
const double _kEyeBaseY = 24;

/// Pixel shift per gaze direction step.
const double _kShift = 4;

// ─── Public gaze direction enum ──────────────────────────────

/// Clinical names for all nine cardinal gaze directions.
///
/// Each value maps directly to a design-space eye offset from the
/// primary (centre-centre) rest position.
enum GazeDirection {
  /// Centre-centre: eyes at rest.
  primary,

  /// Centre-left: both eyes shifted left.
  dextroversion,

  /// Upper-left: both eyes shifted left and up.
  dextroelevation,

  /// Centre-up: both eyes shifted up.
  elevation,

  /// Upper-right: both eyes shifted right and up.
  levoelevation,

  /// Centre-right: both eyes shifted right.
  levoversion,

  /// Lower-right: both eyes shifted right and down.
  levodepression,

  /// Centre-down: both eyes shifted down.
  depression,

  /// Lower-left: both eyes shifted left and down.
  dextrodepression,
}

// ─── Gaze keyframe data ───────────────────────────────────────

/// Encodes the eye offset from the primary-gaze rest position.
class _GazeFrame {
  const _GazeFrame(this.dx, this.dy);

  /// Horizontal offset from primary position in design units.
  final double dx;

  /// Vertical offset from primary position in design units.
  final double dy;

  /// Linear interpolation between two frames.
  _GazeFrame lerp(_GazeFrame other, double t) =>
      _GazeFrame(dx + (other.dx - dx) * t, dy + (other.dy - dy) * t);
}

/// Maps each [GazeDirection] to its design-space eye offset.
const Map<GazeDirection, _GazeFrame> _kDirectionFrames = {
  GazeDirection.primary: _GazeFrame(0, 0),
  GazeDirection.dextroversion: _GazeFrame(-_kShift, 0),
  GazeDirection.dextroelevation: _GazeFrame(-_kShift, -_kShift),
  GazeDirection.elevation: _GazeFrame(0, -_kShift),
  GazeDirection.levoelevation: _GazeFrame(_kShift, -_kShift),
  GazeDirection.levoversion: _GazeFrame(_kShift, 0),
  GazeDirection.levodepression: _GazeFrame(_kShift, _kShift),
  GazeDirection.depression: _GazeFrame(0, _kShift),
  GazeDirection.dextrodepression: _GazeFrame(-_kShift, _kShift),
};

/// 9 keyframes in animation display order (see file header).
const List<_GazeFrame> _kFrames = [
  _GazeFrame(0, 0), // 1 Primary
  _GazeFrame(-_kShift, 0), // 2 Dextroversion   (left)
  _GazeFrame(-_kShift, -_kShift), // 3 Dextroelevation (left-up)
  _GazeFrame(0, -_kShift), // 4 Elevation        (up)
  _GazeFrame(_kShift, -_kShift), // 5 Levoelevation   (right-up)
  _GazeFrame(_kShift, 0), // 6 Levoversion      (right)
  _GazeFrame(_kShift, _kShift), // 7 Levodepression   (right-down)
  _GazeFrame(0, _kShift), // 8 Depression       (down)
  _GazeFrame(-_kShift, _kShift), // 9 Dextrodepression (left-down)
];

// ─── Painter ─────────────────────────────────────────────────

/// Paints a single frame of the gaze face using the design-space
/// spec scaled uniformly to [size].
class _GazeFacePainter extends CustomPainter {
  const _GazeFacePainter({
    required this.frame,
    required this.faceColor,
    required this.eyeColor,
  });

  final _GazeFrame frame;
  final Color faceColor;
  final Color eyeColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Uniform scale: design canvas is _kFaceSize × _kFaceSize.
    final s = size.width / _kFaceSize;

    // ── Face circle ───────────────────────────────────────────
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      Paint()..color = faceColor,
    );

    // ── Eye pills ─────────────────────────────────────────────
    final eyePaint = Paint()..color = eyeColor;
    final radius = Radius.circular(_kEyeR * s);

    for (final originX in [_kLeftEyeX, _kRightEyeX]) {
      final left = (originX + frame.dx) * s;
      final top = (_kEyeBaseY + frame.dy) * s;
      canvas.drawRRect(
        RRect.fromLTRBR(left, top, left + _kEyeW * s, top + _kEyeH * s, radius),
        eyePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GazeFacePainter old) =>
      old.frame.dx != frame.dx ||
      old.frame.dy != frame.dy ||
      old.faceColor != faceColor ||
      old.eyeColor != eyeColor;
}

// ─── Public widget ────────────────────────────────────────────

/// Animated or static gaze face icon.
///
/// **Animated mode** (default constructor): cycles through all 9
/// gaze directions in order, smoothly interpolating between each
/// keyframe every [stepDuration] (default 1 second).
///
/// **Static mode** ([AnimatedGazeFace.static] constructor): renders
/// a fixed [GazeDirection] with no animation overhead whatsoever —
/// no [AnimationController], no [Ticker].
///
/// [faceColor] defaults to #FAFAFA (matching the SVG fill).
/// [eyeColor] defaults to the theme's scaffold background so the
/// pills appear as transparent cut-outs. Pass an explicit colour
/// when the widget sits on a non-scaffold background (e.g.
/// [kAccentBlue] inside the New Gaze button).
class AnimatedGazeFace extends StatefulWidget {
  /// Creates an animated gaze face that cycles through all 9
  /// gaze directions on a loop.
  const AnimatedGazeFace({
    super.key,
    this.size = 32,
    this.faceColor = const Color(0xFFFAFAFA),
    this.eyeColor,
    this.stepDuration = const Duration(seconds: 1),
  }) : _staticGaze = null;

  /// Creates a static, non-animated gaze face locked to a single
  /// clinical [direction].
  const AnimatedGazeFace.static({
    super.key,
    required GazeDirection direction,
    this.size = 32,
    this.faceColor = const Color(0xFFFAFAFA),
    this.eyeColor,
  }) : _staticGaze = direction,
       stepDuration = const Duration(seconds: 1);

  /// Width and height of the widget in logical pixels.
  final double size;

  /// Fill colour of the face circle.
  final Color faceColor;

  /// Colour of the eye cut-outs. When null, resolves to the
  /// theme's [ThemeData.scaffoldBackgroundColor] at build time.
  final Color? eyeColor;

  /// How long each step transition takes (animated mode only).
  final Duration stepDuration;

  /// Non-null when using the static constructor; selects which
  /// direction to lock the gaze to.
  final GazeDirection? _staticGaze;

  @override
  State<AnimatedGazeFace> createState() => _AnimatedGazeFaceState();
}

class _AnimatedGazeFaceState extends State<AnimatedGazeFace>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  /// Index of the frame we are transitioning *from*.
  int _fromIndex = 0;

  @override
  void initState() {
    super.initState();

    // Skip the controller entirely in static mode to avoid any
    // unnecessary Ticker allocation.
    if (widget._staticGaze != null) return;

    _controller = AnimationController(
      vsync: this,
      duration: widget.stepDuration,
    )..addStatusListener(_onStatus);
    _controller!.forward();
  }

  /// Advances the frame index and replays the controller.
  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _fromIndex = (_fromIndex + 1) % _kFrames.length;
      });
      _controller!.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedEyeColor =
        widget.eyeColor ?? Theme.of(context).scaffoldBackgroundColor;

    // ── Static mode ───────────────────────────────────────────
    if (widget._staticGaze != null) {
      final frame = _kDirectionFrames[widget._staticGaze]!;
      return SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _GazeFacePainter(
            frame: frame,
            faceColor: widget.faceColor,
            eyeColor: resolvedEyeColor,
          ),
        ),
      );
    }

    // ── Animated mode ─────────────────────────────────────────
    final toIndex = (_fromIndex + 1) % _kFrames.length;

    return AnimatedBuilder(
      animation: _controller!,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_controller!.value);
        final frame = _kFrames[_fromIndex].lerp(_kFrames[toIndex], t);

        return SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(
            painter: _GazeFacePainter(
              frame: frame,
              faceColor: widget.faceColor,
              eyeColor: resolvedEyeColor,
            ),
          ),
        );
      },
    );
  }
}
