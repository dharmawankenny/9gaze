// One-time session backfill for legacy slot thumbnails.
//
// Generates missing 300/192/32 thumbnails for slots created before
// thumbnail support shipped, so existing installs get same rendering
// performance improvements as new entries.

import 'dart:io';

import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/services/image_storage.dart';
import 'package:kensa_9gaze/services/thumbnail_renderer.dart';

/// Backfills missing thumbnails for existing slot rows.
///
/// Runs at most once per app session. It is safe to call repeatedly.
class ThumbnailBackfill {
  ThumbnailBackfill._();

  static bool _ranThisSession = false;

  /// Scans all slots and generates thumbs only when any size is missing.
  static Future<void> runOnce(AppDatabase db) async {
    if (_ranThisSession) return;
    _ranThisSession = true;

    try {
      final slots = await db.select(db.gazeSlots).get();
      for (final slot in slots) {
        final missing = await _hasMissingThumb(slot.imagePath);
        if (!missing) continue;
        try {
          await ImageStorage.generateThumbnails(
            relPath: slot.imagePath,
            params: SlotTransformParams(
              sourceWidth: slot.sourceWidth,
              sourceHeight: slot.sourceHeight,
              translateX: slot.translateX,
              translateY: slot.translateY,
              scale: slot.scale,
              rotation: slot.rotation,
              eyeLeftX: slot.eyeLeftX,
              eyeLeftY: slot.eyeLeftY,
              eyeRightX: slot.eyeRightX,
              eyeRightY: slot.eyeRightY,
            ),
          );
        } catch (_) {
          // Keep migrating remaining slots even if one fails.
        }
      }
    } catch (_) {
      // Best-effort background task; never block app flow.
    }
  }

  static Future<bool> _hasMissingThumb(String relPath) async {
    for (final size in ThumbSize.values) {
      final abs = await ImageStorage.resolveThumbAbsPath(relPath, size);
      if (!File(abs).existsSync()) return true;
    }
    return false;
  }
}
