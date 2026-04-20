// SlotKey enum and helpers for mapping gaze-direction slots to
// the existing GazeDirection rendering enum.
//
// Each value corresponds to one cell in the 3x3 gaze grid, plus
// the optional tenth slot used when isDoublePrimary is enabled.
// The string representation is what gets persisted in the DB.

import 'package:kensa_9gaze/widgets/animated_gaze_face.dart';

/// Identifies one of the ten possible gaze-direction image slots.
///
/// Nine slots map 1:1 to [GazeDirection] values. The tenth slot,
/// [primarySecondary], shares the centre cell with [primary] when
/// [Gaze.isDoublePrimary] is true and maps to [GazeDirection.primary]
/// for rendering purposes.
enum SlotKey {
  dextroelevation,
  elevation,
  levoelevation,
  dextroversion,
  primary,
  levoversion,
  dextrodepression,
  depression,
  levodepression,

  /// Optional second image for the centre cell, active only when
  /// the parent gaze has [Gaze.isDoublePrimary] set to true.
  primarySecondary,
}

/// Maps each [SlotKey] to its corresponding [GazeDirection] for
/// rendering the gaze-face overlay icon and export grid.
///
/// [SlotKey.primarySecondary] maps to [GazeDirection.primary] since
/// both halves of the dual-primary cell show a centre gaze.
const Map<SlotKey, GazeDirection> kSlotKeyToDirection = {
  SlotKey.dextroelevation: GazeDirection.dextroelevation,
  SlotKey.elevation: GazeDirection.elevation,
  SlotKey.levoelevation: GazeDirection.levoelevation,
  SlotKey.dextroversion: GazeDirection.dextroversion,
  SlotKey.primary: GazeDirection.primary,
  SlotKey.levoversion: GazeDirection.levoversion,
  SlotKey.dextrodepression: GazeDirection.dextrodepression,
  SlotKey.depression: GazeDirection.depression,
  SlotKey.levodepression: GazeDirection.levodepression,
  SlotKey.primarySecondary: GazeDirection.primary,
};

/// The canonical reading-order sequence of the nine grid cells.
///
/// Row-major order: top-left → top-center → top-right, then
/// middle row, then bottom row. [primarySecondary] is excluded
/// because it shares its grid position with [primary].
const List<SlotKey> kGridSlotOrder = [
  SlotKey.dextroelevation,
  SlotKey.elevation,
  SlotKey.levoelevation,
  SlotKey.dextroversion,
  SlotKey.primary,
  SlotKey.levoversion,
  SlotKey.dextrodepression,
  SlotKey.depression,
  SlotKey.levodepression,
];

/// Human-readable label for each slot, shown beneath the icon in
/// the gaze direction grid.
const Map<SlotKey, String> kSlotKeyLabel = {
  SlotKey.dextroelevation: 'Dextroelevation',
  SlotKey.elevation: 'Elevation',
  SlotKey.levoelevation: 'Levoelevation',
  SlotKey.dextroversion: 'Dextroversion',
  SlotKey.primary: 'Primary',
  SlotKey.levoversion: 'Levoversion',
  SlotKey.dextrodepression: 'Dextrodepression',
  SlotKey.depression: 'Depression',
  SlotKey.levodepression: 'Levodepression',
  SlotKey.primarySecondary: 'Primary 2',
};
