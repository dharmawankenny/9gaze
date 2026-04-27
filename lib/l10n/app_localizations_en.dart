// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => '9Gaze';

  @override
  String get searchByNameHint => 'Search by name...';

  @override
  String get newGaze => 'New Gaze';

  @override
  String get gazeDetails => 'Gaze Details';

  @override
  String get gazeDetail => 'Gaze Detail';

  @override
  String get gazeDetailName => 'Gaze name';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get created => 'Created';

  @override
  String get createGaze => 'Create Gaze';

  @override
  String get updated => 'Updated';

  @override
  String get updateGaze => 'Update Gaze';

  @override
  String get failedLoadGazes => 'Failed to load gazes.';

  @override
  String get noGazeFound => 'No gaze found, try searching for another name';

  @override
  String get noGazeYet =>
      'No gaze yet, make one by clicking the blue button below';

  @override
  String get deleteGazeTitle => 'Delete gaze?';

  @override
  String deleteGazeMessage(Object name) {
    return 'This will permanently remove \"$name\" and cannot be undone.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String lastEdited(Object date) {
    return 'Last edited: $date';
  }

  @override
  String get back => 'Back';

  @override
  String get editGaze => 'Edit gaze';

  @override
  String get editReposition => 'Edit Position';

  @override
  String get editRearrange => 'Edit Arrangement';

  @override
  String get editTexts => 'Edit Texts';

  @override
  String get done => 'Done';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get exporting => 'Exporting…';

  @override
  String get exportedSuccessfully => 'Exported successfully';

  @override
  String get saveToGallery => 'Save to Gallery';

  @override
  String get compactMode => 'Compact Mode?';

  @override
  String get dualPrimary => 'Dual Primary?';

  @override
  String get update => 'Update';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get reposition => 'Reposition';

  @override
  String get rearrange => 'Rearrange';

  @override
  String get texts => 'Texts';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get addText => 'Add Text';

  @override
  String get overlayTextHint => 'Overlay text';

  @override
  String get dragMovePinchScale =>
      'Drag to move. Pinch selected text to scale.';

  @override
  String exportFailed(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get tapToAdd => 'Tap to add';

  @override
  String get slotTopLeft => 'Top-left';

  @override
  String get slotTopCenter => 'Top-center';

  @override
  String get slotTopRight => 'Top-right';

  @override
  String get slotCenterLeft => 'Center-left';

  @override
  String get slotCenter => 'Center';

  @override
  String get slotCenterRight => 'Center-right';

  @override
  String get slotBottomLeft => 'Bottom-left';

  @override
  String get slotBottomCenter => 'Bottom-center';

  @override
  String get slotBottomRight => 'Bottom-right';

  @override
  String get slotCenter2 => 'Center 2';

  @override
  String get discard => 'Discard';

  @override
  String get saving => 'Saving…';

  @override
  String get pinchZoomDragTwist =>
      'Pinch to zoom · Drag to pan · Twist to rotate';

  @override
  String get reset => 'Reset';

  @override
  String get recenter => 'Recenter';

  @override
  String get replace => 'Replace';

  @override
  String get textDefault => 'Text';
}
