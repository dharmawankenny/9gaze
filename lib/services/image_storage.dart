// Image storage service for 9Gaze slot photos.
//
// Copies gallery-picked images into the app's documents directory
// under gazes/<gazeId>/<slotKey>_<uuid>.jpg so that photos survive
// the user deleting or replacing their gallery originals.
//
// Alongside the full-resolution original, three JPEG thumbnails are
// generated from the same directory:
//   <base>_thumb300.jpg — 300×300 px export crop.
//   <base>_thumb192.jpg — 192×192 px detail-grid preview.
//   <base>_thumb32.jpg  —  32×32 px home-list mosaic cell.
//
// "base" is the stem of the relative path without its .jpg extension.
// Example: gazes/3/primary_abc123.jpg produces
//   gazes/3/primary_abc123_thumb300.jpg, etc.
//
// All public methods are safe to call from any isolate that has
// access to the file system; they do not touch Flutter bindings
// except via [renderThumbJpeg], which uses dart:ui internally.

import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:kensa_9gaze/services/thumbnail_renderer.dart';

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

  /// Returns the relative path of the thumbnail derived from
  /// [relPath] for the given [size].
  ///
  /// The thumbnail sits beside the original file with a size
  /// suffix inserted before the extension. For example:
  ///   gazes/3/primary_abc.jpg + px300 →
  ///   gazes/3/primary_abc_thumb300.jpg
  static String resolveThumbRelPath(String relPath, ThumbSize size) {
    final ext = p.extension(relPath);
    final stem = relPath.substring(0, relPath.length - ext.length);
    return '${stem}_thumb${size.pixels}$ext';
  }

  /// Resolves [resolveThumbRelPath] to an absolute filesystem path.
  static Future<String> resolveThumbAbsPath(
    String relPath,
    ThumbSize size,
  ) async {
    final root = await _docsRoot();
    return p.join(root, resolveThumbRelPath(relPath, size));
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

  /// Generates (or regenerates) the three thumbnail JPEG files for
  /// the slot image at [relPath] using [params] to apply the same
  /// normalised transform as the on-screen renderer.
  ///
  /// Existing thumbnails at the derived paths are overwritten so
  /// this is safe to call after every transform update (Save in the
  /// slot editor).
  static Future<void> generateThumbnails({
    required String relPath,
    required SlotTransformParams params,
  }) async {
    final absPath = await resolveAbsPath(relPath);
    if (!File(absPath).existsSync()) return;

    for (final size in ThumbSize.values) {
      final thumbAbs = await resolveThumbAbsPath(relPath, size);
      final thumbBytes = await renderThumbJpeg(
        absSourcePath: absPath,
        params: params,
        size: size,
      );
      await File(thumbAbs).writeAsBytes(thumbBytes, flush: true);
      // Same path reused across updates; evict decode cache so UI
      // reloads latest bytes immediately after save.
      await FileImage(File(thumbAbs)).evict();
    }
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

  /// Deletes all three thumbnail files derived from [relPath].
  ///
  /// Silently skips thumbnails that do not yet exist so callers do
  /// not need to guard against partial generation states.
  static Future<void> deleteThumbnails(String relPath) async {
    for (final size in ThumbSize.values) {
      final thumbAbs = await resolveThumbAbsPath(relPath, size);
      final file = File(thumbAbs);
      if (file.existsSync()) {
        await FileImage(file).evict();
        await file.delete();
      }
    }
  }

  /// Deletes the entire `gazes/<gazeId>/` directory and all slot
  /// images and thumbnails inside it.
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
