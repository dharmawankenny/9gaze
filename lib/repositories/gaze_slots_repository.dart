// Typed CRUD facade over the `gaze_slots` drift table.
//
// Keeps drift internals out of the UI and service layers.
// The repository does NOT delete image files; callers must invoke
// [ImageStorage.deleteSlotFile] when replacing or removing a slot,
// since the repository does not own the file system.

import 'package:drift/drift.dart';

import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/models/slot_key.dart';

/// High-level operations on the `gaze_slots` table.
///
/// All mutations automatically refresh the [GazeSlot.updatedAt]
/// timestamp unless documented otherwise.
class GazeSlotsRepository {
  const GazeSlotsRepository(this._db);

  final AppDatabase _db;

  // ── Queries ─────────────────────────────────────────────────

  /// Fetches the slot for [gazeId] and [key], or null if none
  /// has been created yet.
  Future<GazeSlot?> getOne(int gazeId, SlotKey key) {
    return (_db.select(_db.gazeSlots)
          ..where((s) => s.gazeId.equals(gazeId) & s.slotKey.equals(key.name)))
        .getSingleOrNull();
  }

  /// Returns all slots for [gazeId] ordered by creation time.
  Future<List<GazeSlot>> getAllForGaze(int gazeId) {
    return (_db.select(_db.gazeSlots)
          ..where((s) => s.gazeId.equals(gazeId))
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
        .get();
  }

  /// Reactive variant of [getAllForGaze]. Emits a new list
  /// whenever any slot row for [gazeId] changes.
  Stream<List<GazeSlot>> watchAllForGaze(int gazeId) {
    return (_db.select(_db.gazeSlots)
          ..where((s) => s.gazeId.equals(gazeId))
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
        .watch();
  }

  // ── Mutations ───────────────────────────────────────────────

  /// Inserts or replaces a slot row, enforcing the unique
  /// (gazeId, slotKey) constraint via SQLite's REPLACE conflict
  /// resolution.
  ///
  /// Call [ImageStorage.deleteSlotFile] with the old image path
  /// **before** calling [upsert] when replacing an existing slot.
  /// Inserts or replaces a slot row, resolving conflicts on the
  /// unique (gazeId, slotKey) constraint via SQLite's OR REPLACE
  /// strategy (which replaces any conflicting row regardless of
  /// which column caused the conflict — unlike insertOnConflictUpdate
  /// which only handles the PK).
  Future<void> upsert({
    required int gazeId,
    required SlotKey key,
    required String imagePath,
    required int sourceWidth,
    required int sourceHeight,
    double translateX = 0.5,
    double translateY = 0.5,
    double scale = 1.0,
    double rotation = 0.0,
    double? eyeLeftX,
    double? eyeLeftY,
    double? eyeRightX,
    double? eyeRightY,
  }) {
    final now = DateTime.now();
    return _db.into(_db.gazeSlots).insert(
          GazeSlotsCompanion.insert(
            gazeId: gazeId,
            slotKey: key.name,
            imagePath: imagePath,
            sourceWidth: sourceWidth,
            sourceHeight: sourceHeight,
            translateX: Value(translateX),
            translateY: Value(translateY),
            scale: Value(scale),
            rotation: Value(rotation),
            eyeLeftX: Value(eyeLeftX),
            eyeLeftY: Value(eyeLeftY),
            eyeRightX: Value(eyeRightX),
            eyeRightY: Value(eyeRightY),
            updatedAt: Value(now),
          ),
          // OR REPLACE fires on any constraint conflict, including
          // the unique (gaze_id, slot_key) index — not just the PK.
          mode: InsertMode.insertOrReplace,
        );
  }

  /// Updates only the transform columns for the slot identified
  /// by [id], refreshing [GazeSlot.updatedAt].
  Future<void> updateTransform(
    int id, {
    required double translateX,
    required double translateY,
    required double scale,
    required double rotation,
  }) {
    return (_db.update(_db.gazeSlots)..where((s) => s.id.equals(id))).write(
      GazeSlotsCompanion(
        translateX: Value(translateX),
        translateY: Value(translateY),
        scale: Value(scale),
        rotation: Value(rotation),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Deletes the slot row by [id].
  ///
  /// The caller is responsible for deleting the associated image
  /// file via [ImageStorage.deleteSlotFile].
  Future<int> deleteById(int id) {
    return (_db.delete(_db.gazeSlots)..where((s) => s.id.equals(id))).go();
  }

  /// Returns all slots for [gazeId] — used by the file-cleanup
  /// helper in [GazesRepository] before cascade-deleting a gaze.
  Future<List<GazeSlot>> getAllForGazeOnce(int gazeId) => getAllForGaze(gazeId);
}
