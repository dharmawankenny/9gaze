// Image storage service for 9Gaze slot photos.
//
// Copies gallery-picked images into the app's documents directory
// under gazes/<gazeId>/<slotKey>_<uuid>.jpg so that photos survive
// the user deleting or replacing their gallery originals.
//
// All public methods are safe to call from any isolate that has
// access to the file system; they do not touch Flutter bindings.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Manages on-disk storage of gaze-slot photos in the app sandbox.
///
/// Paths returned by [copySlotImage] are **relative** to the app
/// documents directory and must be resolved with [resolveAbsPath]
/// before opening a [File].
class ImageStorage {
  const ImageStorage._();

  static const _uuid = Uuid();

  // ── Path helpers ────────────────────────────────────────────

  /// Returns the absolute app documents directory path.
  static Future<String> _docsRoot() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// Converts a relative DB path to an absolute filesystem path.
  static Future<String> resolveAbsPath(String relativePath) async {
    final root = await _docsRoot();
    return p.join(root, relativePath);
  }

  /// Converts an absolute filesystem path to a relative DB path
  /// (relative to the app documents directory).
  static Future<String> _toRelPath(String absPath) async {
    final root = await _docsRoot();
    return p.relative(absPath, from: root);
  }

  // ── Core operations ─────────────────────────────────────────

  /// Copies [sourcePath] (gallery-picked file) into the app docs
  /// sandbox at `gazes/<gazeId>/<slotKey>_<uuid>.jpg`.
  ///
  /// Returns the **relative** path stored in the database.
  ///
  /// Uses a UUID suffix so that replacing a slot image with a new
  /// photo flushes iOS's image-decode cache (which is keyed by
  /// path). The old file is **not** deleted here; pass the old
  /// relative path to [deleteSlotFile] before or after.
  static Future<String> copySlotImage({
    required String sourcePath,
    required int gazeId,
    required String slotKey,
  }) async {
    final root = await _docsRoot();
    final dir = Directory(p.join(root, 'gazes', '$gazeId'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    final filename = '${slotKey}_${_uuid.v4()}.jpg';
    final destAbs = p.join(dir.path, filename);

    await File(sourcePath).copy(destAbs);

    return _toRelPath(destAbs);
  }

  /// Deletes the file at [relativePath] from the app docs dir.
  ///
  /// Silently no-ops if the file no longer exists so that callers
  /// do not need to guard against double-delete.
  static Future<void> deleteSlotFile(String relativePath) async {
    final absPath = await resolveAbsPath(relativePath);
    final file = File(absPath);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Deletes the entire `gazes/<gazeId>/` directory and all slot
  /// images inside it.
  ///
  /// Call this when a gaze session is deleted so orphaned files do
  /// not accumulate in the app sandbox.
  static Future<void> deleteGazeDirectory(int gazeId) async {
    final root = await _docsRoot();
    final dir = Directory(p.join(root, 'gazes', '$gazeId'));
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }
}
