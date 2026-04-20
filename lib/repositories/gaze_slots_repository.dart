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

  /// Atomically rewrites [slotKey] for multiple rows in one
  /// transaction, using temp keys to sidestep the unique
  /// (gazeId, slotKey) constraint during intermediate states.
  ///
  /// [targetKeyById] maps each slot DB id to its desired final
  /// [slotKey] string. Only changed rows need to be included.
  Future<void> reorderSlots(Map<int, String> targetKeyById) {
    if (targetKeyById.isEmpty) return Future.value();
    return _db.transaction(() async {
      final now = DateTime.now();
      // Phase 1: write unique temp keys to break existing conflicts.
      var tempIdx = 0;
      for (final id in targetKeyById.keys) {
        await (_db.update(_db.gazeSlots)..where((s) => s.id.equals(id)))
            .write(GazeSlotsCompanion(
          slotKey: Value('__tmp_${tempIdx++}__'),
          updatedAt: Value(now),
        ));
      }
      // Phase 2: write final target keys.
      for (final entry in targetKeyById.entries) {
        await (_db.update(_db.gazeSlots)
              ..where((s) => s.id.equals(entry.key)))
            .write(GazeSlotsCompanion(
          slotKey: Value(entry.value),
          updatedAt: Value(now),
        ));
      }
    });
  }

  /// Atomically swaps the [slotKey] values of two slot rows
  /// identified by their DB [id]s.
  ///
  /// All image data, transform values, and eye landmarks stay on
  /// the same row — only the [slotKey] column moves. This is the
  /// correct semantic for a drag-and-swap reorder: the photo
  /// assigned to position A moves to position B and vice-versa.
  ///
  /// Wrapped in a transaction so both updates succeed or neither
  /// does — leaving the DB in a consistent state on error.
  Future<void> swapSlotKeys({
    required int idA,
    required String keyA,
    required int idB,
    required String keyB,
  }) {
    return _db.transaction(() async {
      final now = DateTime.now();
      // Write a temporary key to idA first to avoid the unique
      // (gazeId, slotKey) constraint firing during the swap.
      // SQLite defers constraint checks to the end of the statement
      // but NOT across separate UPDATE calls, so we use a temp value.
      final tempKey = '__swap_temp__';
      await (_db.update(_db.gazeSlots)..where((s) => s.id.equals(idA)))
          .write(GazeSlotsCompanion(
        slotKey: Value(tempKey),
        updatedAt: Value(now),
      ));
      await (_db.update(_db.gazeSlots)..where((s) => s.id.equals(idB)))
          .write(GazeSlotsCompanion(
        slotKey: Value(keyA),
        updatedAt: Value(now),
      ));
      await (_db.update(_db.gazeSlots)..where((s) => s.id.equals(idA)))
          .write(GazeSlotsCompanion(
        slotKey: Value(keyB),
        updatedAt: Value(now),
      ));
    });
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
