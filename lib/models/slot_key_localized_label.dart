// Localized labels for slot keys used in UI surfaces.

import 'package:kensa_9gaze/l10n/app_localizations.dart';

import 'package:kensa_9gaze/models/slot_key.dart';

/// Returns localized display label for [slotKey].
String slotKeyLocalizedLabel(AppLocalizations l10n, SlotKey slotKey) {
  switch (slotKey) {
    case SlotKey.dextroelevation:
      return l10n.slotTopLeft;
    case SlotKey.elevation:
      return l10n.slotTopCenter;
    case SlotKey.levoelevation:
      return l10n.slotTopRight;
    case SlotKey.dextroversion:
      return l10n.slotCenterLeft;
    case SlotKey.primary:
      return l10n.slotCenter;
    case SlotKey.levoversion:
      return l10n.slotCenterRight;
    case SlotKey.dextrodepression:
      return l10n.slotBottomLeft;
    case SlotKey.depression:
      return l10n.slotBottomCenter;
    case SlotKey.levodepression:
      return l10n.slotBottomRight;
    case SlotKey.primarySecondary:
      return l10n.slotCenter2;
  }
}
