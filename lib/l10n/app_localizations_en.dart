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
  String get saveToGallery => 'Export to Gallery';

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
  String get exportVerb => 'Export';

  @override
  String get exportDone => 'Exported';

  @override
  String get textDefault => 'Text';

  @override
  String get onboardingWelcomeTitle => 'Welcome to 9Gaze';

  @override
  String get onboardingWelcomeBody =>
      'Import your eye movement photos from the gallery and arrange them into a clean, labeled 3×3 grid. Auto-alignment handles the framing; you can fine-tune any slot. Export one composed image when you are done.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGotIt => 'Got it';

  @override
  String get onboardingSkipTour => 'Skip tour';

  @override
  String get onboardingSkipConfirmTitle => 'Skip the tour?';

  @override
  String get onboardingSkipConfirmBody =>
      'You can restart the tutorial anytime from the settings menu.';

  @override
  String get onboardingHomeEmptyTitle => 'Your saved grids';

  @override
  String get onboardingHomeEmptyBody =>
      'Each gaze you create appears here. You have not made one yet. Tap the blue button below to start your first labeled grid.';

  @override
  String get onboardingHomeCreateTitle => 'Create a gaze';

  @override
  String get onboardingHomeCreateBody =>
      'Tap New Gaze to name your grid and begin importing photos.';

  @override
  String get onboardingCreateNameTitle => 'Name this gaze';

  @override
  String get onboardingCreateNameBody =>
      'Only a name is required. Choose something you will recognize in the list.';

  @override
  String get onboardingCreateNotesTitle => 'Notes (optional)';

  @override
  String get onboardingCreateNotesBody =>
      'Optional notes for your own reference, such as a session label or date.';

  @override
  String get onboardingCreateSubmitTitle => 'Open your grid';

  @override
  String get onboardingCreateSubmitBody =>
      'Tap Create Gaze. You will assign photos to each labeled slot next.';

  @override
  String get onboardingDetailSlotsTitle => 'Nine labeled slots';

  @override
  String get onboardingDetailSlotsBody =>
      'Each slot matches a gaze direction. Tap a slot to import one photo from your gallery. Select several photos at once and 9Gaze fills empty slots in order.';

  @override
  String get onboardingDetailPickTitle => 'Import from gallery';

  @override
  String get onboardingDetailPickBody =>
      'Tap a slot (centre is a good first pick) and choose one or more photos. No in-app camera needed.';

  @override
  String get onboardingDetailAutoAlignTitle => 'Automatic eye alignment';

  @override
  String get onboardingDetailAutoAlignBody =>
      '9Gaze detects the eye in each photo, centers it vertically, and fits the image to the horizontal boundaries of the slot so every cell looks consistently framed.';

  @override
  String get onboardingDetailFineTuneTitle => 'Manual override';

  @override
  String get onboardingDetailFineTuneBody =>
      'Auto-alignment is not perfect on every photo. Open a slot for full control, or use Edit on this screen to adjust positions in the grid.';

  @override
  String get onboardingDetailLayoutTitle => 'Layout options';

  @override
  String get onboardingDetailLayoutBody =>
      'Compact Mode uses shorter slot cells. Dual Primary splits the centre slot into top and bottom. Only one layout option can be active at a time.';

  @override
  String get onboardingDetailInfoTitle => 'Gaze details';

  @override
  String get onboardingDetailInfoBody =>
      'The name and notes for this grid are here. Tap Update to change them anytime.';

  @override
  String get onboardingDetailTapSlotTitle => 'Fine-tune this slot';

  @override
  String get onboardingDetailTapSlotBody =>
      'Tap the slot you just filled. You can adjust position, zoom, and rotation on the next screen.';

  @override
  String get onboardingSlotGesturesTitle => 'Adjust the framing';

  @override
  String get onboardingSlotGesturesBody =>
      'Pinch to zoom, drag to pan, twist to rotate. Try a small adjustment if auto-alignment needs a nudge.';

  @override
  String get onboardingSlotUndoTitle => 'Undo and redo';

  @override
  String get onboardingSlotUndoBody =>
      'Tap Undo to step back, then Redo if you want to restore a change.';

  @override
  String get onboardingSlotToolsTitle => 'Slot tools';

  @override
  String get onboardingSlotToolsBody =>
      'Recenter runs automatic eye alignment again. Reset clears manual edits from this session. Replace imports a different photo for this slot.';

  @override
  String get onboardingSlotSaveTitle => 'Save this slot';

  @override
  String get onboardingSlotSaveBody => 'Tap Save to return to your gaze grid.';
}
