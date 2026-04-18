// Animated face icon that cycles through all 9 gaze directions,
// tracing the shape of the digit '9':
//   Primary → Dextroversion → Dextroelevation → Elevation
//   → Levoelevation → Levoversion → Levodepression
//   → Depression → Dextrodepression → (loop)
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

/// 9 keyframes in display order (see file header for sequence).
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

/// Animated face that cycles through all 9 gaze directions,
/// smoothly interpolating between each keyframe every
/// [stepDuration] (default 1 second).
///
/// [faceColor] defaults to #FAFAFA (matching the SVG fill).
/// [eyeColor] defaults to the theme's scaffold background so
/// the pills appear as transparent cut-outs. Pass an explicit
/// colour when the widget sits on a non-scaffold background
/// (e.g. [kAccentBlue] inside the New Gaze button).
class AnimatedGazeFace extends StatefulWidget {
  const AnimatedGazeFace({
    super.key,
    this.size = 32,
    this.faceColor = const Color(0xFFFAFAFA),
    this.eyeColor,
    this.stepDuration = const Duration(seconds: 1),
  });

  /// Width and height of the widget in logical pixels.
  final double size;

  /// Fill colour of the face circle.
  final Color faceColor;

  /// Colour of the eye cut-outs. When null, resolves to the
  /// theme's [ThemeData.scaffoldBackgroundColor] at build time.
  final Color? eyeColor;

  /// How long each step transition takes.
  final Duration stepDuration;

  @override
  State<AnimatedGazeFace> createState() => _AnimatedGazeFaceState();
}

class _AnimatedGazeFaceState extends State<AnimatedGazeFace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Index of the frame we are transitioning *from*.
  int _fromIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.stepDuration,
    )..addStatusListener(_onStatus);
    _controller.forward();
  }

  /// Advances the frame index and replays the controller.
  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _fromIndex = (_fromIndex + 1) % _kFrames.length;
      });
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedEyeColor =
        widget.eyeColor ?? Theme.of(context).scaffoldBackgroundColor;
    final toIndex = (_fromIndex + 1) % _kFrames.length;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_controller.value);
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
