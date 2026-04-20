// Drift table definition for the `gaze_slots` table.
//
// Each row stores one photographed gaze direction slot belonging to
// a parent [Gazes] row. The table enforces a unique (gazeId, slotKey)
// constraint so each direction can only have one active image per
// gaze session.
//
// Transform values are stored in a normalised, resolution-independent
// form so that rendering at any output size (96 px thumbnail, full-screen
// detail view, 1080 px export) requires no schema changes.

import 'package:drift/drift.dart';

import 'package:kensa_9gaze/db/tables/gazes.dart';

/// Stores one gaze-direction image slot for a parent [Gazes] row.
///
/// Columns:
/// - [id] auto-incremented primary key.
/// - [gazeId] foreign key → gazes.id (cascade delete).
/// - [slotKey] string representation of the [SlotKey] enum value.
/// - [imagePath] relative path under the app documents directory,
///   e.g. "gazes/12/primary_abc123.jpg".
/// - [translateX], [translateY] normalised image-centre position
///   within the slot frame (0–1 each axis). Default 0.5 = centred.
/// - [scale] user-applied multiplier on top of the auto-fit base
///   scale. 1.0 = exactly the ML-recommended fit.
/// - [rotation] clockwise rotation in radians applied after scale.
/// - [eyeLeftX], [eyeLeftY], [eyeRightX], [eyeRightY] ML-detected
///   eye landmark positions, normalised to source image size (0–1).
///   Nullable when ML detection produced no result.
/// - [sourceWidth], [sourceHeight] pixel dimensions of the copied
///   source image; used to recompute the base scale at render time.
/// - [createdAt], [updatedAt] timestamps.
class GazeSlots extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// References the parent gaze session; deleting a gaze cascades
  /// to all of its slots.
  IntColumn get gazeId =>
      integer().references(Gazes, #id, onDelete: KeyAction.cascade)();

  /// String value of the SlotKey enum (e.g. "primary", "elevation").
  TextColumn get slotKey => text()();

  /// Relative file path under the app documents directory.
  TextColumn get imagePath => text()();

  // ── Normalised transform (resolution-independent) ──────────

  /// Normalised horizontal centre of the image within the slot
  /// frame. 0 = left edge, 1 = right edge, 0.5 = centred.
  RealColumn get translateX => real().withDefault(const Constant(0.5))();

  /// Normalised vertical centre of the image within the slot
  /// frame. 0 = top edge, 1 = bottom edge, 0.5 = centred.
  RealColumn get translateY => real().withDefault(const Constant(0.5))();

  /// User-applied scale multiplier on top of the ML auto-fit base
  /// scale. 1.0 = exactly the recommended fit.
  RealColumn get scale => real().withDefault(const Constant(1.0))();

  /// Clockwise rotation in radians applied after scale.
  RealColumn get rotation => real().withDefault(const Constant(0.0))();

  // ── ML-derived landmark metadata ──────────────────────────

  /// Left-eye X position normalised to source image width (0–1).
  RealColumn get eyeLeftX => real().nullable()();

  /// Left-eye Y position normalised to source image height (0–1).
  RealColumn get eyeLeftY => real().nullable()();

  /// Right-eye X position normalised to source image width (0–1).
  RealColumn get eyeRightX => real().nullable()();

  /// Right-eye Y position normalised to source image height (0–1).
  RealColumn get eyeRightY => real().nullable()();

  // ── Source image dimensions ────────────────────────────────

  /// Width of the source image in pixels.
  IntColumn get sourceWidth => integer()();

  /// Height of the source image in pixels.
  IntColumn get sourceHeight => integer()();

  // ── Timestamps ─────────────────────────────────────────────

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Enforces one slot per direction per gaze session.
  @override
  List<Set<Column>> get uniqueKeys => [
    {gazeId, slotKey},
  ];
}
