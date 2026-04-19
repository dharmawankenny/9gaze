// 3×3 grid showing all nine clinical gaze directions as static
// face icons. Each cell is a square one-third of the container
// width, with a dark-blue background and flush edges.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/widgets/animated_gaze_face.dart';

/// The fixed sequence of gaze directions displayed in reading
/// order: top-left → top-center → top-right → … → bottom-right.
const List<GazeDirection> _kGridOrder = [
  GazeDirection.dextroelevation,
  GazeDirection.elevation,
  GazeDirection.levoelevation,
  GazeDirection.dextroversion,
  GazeDirection.primary,
  GazeDirection.levoversion,
  GazeDirection.dextrodepression,
  GazeDirection.depression,
  GazeDirection.levodepression,
];

/// Human-readable short label for each gaze direction, shown
/// beneath the icon inside each grid cell.
const Map<GazeDirection, String> _kDirectionLabel = {
  GazeDirection.dextroelevation: 'Dextroelevation',
  GazeDirection.elevation: 'Elevation',
  GazeDirection.levoelevation: 'Levoelevation',
  GazeDirection.dextroversion: 'Dextroversion',
  GazeDirection.primary: 'Primary',
  GazeDirection.levoversion: 'Levoversion',
  GazeDirection.dextrodepression: 'Dextrodepression',
  GazeDirection.depression: 'Depression',
  GazeDirection.levodepression: 'Levodepression',
};

/// Full-width 3×3 grid of static gaze direction cells.
///
/// Each cell is square (1:1), sized to exactly one-third of the
/// available width via [LayoutBuilder]. No corner radius, no gap
/// between cells, dark-blue background per cell.
class GazeDirectionGrid extends StatelessWidget {
  const GazeDirectionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = constraints.maxWidth / 3;

          return Wrap(
            children: _kGridOrder.map((direction) {
              return _GazeCell(direction: direction, size: cellSize);
            }).toList(),
          );
        },
      ),
    );
  }
}

/// A single square cell in the gaze direction grid.
class _GazeCell extends StatelessWidget {
  const _GazeCell({required this.direction, required this.size});

  final GazeDirection direction;

  /// Width and height of this cell in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final faceSize = size * 0.3;
    final label = _kDirectionLabel[direction]!;

    return SizedBox(
      width: size,
      height: size,
      child: ColoredBox(
        color: kDarkBlue.withValues(alpha: 0.5),
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
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 8,
                  color: kWhite.withValues(alpha: 0.25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
