import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'9Gaze'**
  String get appTitle;

  /// No description provided for @searchByNameHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name...'**
  String get searchByNameHint;

  /// No description provided for @newGaze.
  ///
  /// In en, this message translates to:
  /// **'New Gaze'**
  String get newGaze;

  /// No description provided for @gazeDetails.
  ///
  /// In en, this message translates to:
  /// **'Gaze Details'**
  String get gazeDetails;

  /// No description provided for @gazeDetail.
  ///
  /// In en, this message translates to:
  /// **'Gaze Detail'**
  String get gazeDetail;

  /// No description provided for @gazeDetailName.
  ///
  /// In en, this message translates to:
  /// **'Gaze name'**
  String get gazeDetailName;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @createGaze.
  ///
  /// In en, this message translates to:
  /// **'Create Gaze'**
  String get createGaze;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @updateGaze.
  ///
  /// In en, this message translates to:
  /// **'Update Gaze'**
  String get updateGaze;

  /// No description provided for @failedLoadGazes.
  ///
  /// In en, this message translates to:
  /// **'Failed to load gazes.'**
  String get failedLoadGazes;

  /// No description provided for @noGazeFound.
  ///
  /// In en, this message translates to:
  /// **'No gaze found, try searching for another name'**
  String get noGazeFound;

  /// No description provided for @noGazeYet.
  ///
  /// In en, this message translates to:
  /// **'No gaze yet, make one by clicking the blue button below'**
  String get noGazeYet;

  /// No description provided for @deleteGazeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete gaze?'**
  String get deleteGazeTitle;

  /// No description provided for @deleteGazeMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove \"{name}\" and cannot be undone.'**
  String deleteGazeMessage(Object name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @lastEdited.
  ///
  /// In en, this message translates to:
  /// **'Last edited: {date}'**
  String lastEdited(Object date);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @editGaze.
  ///
  /// In en, this message translates to:
  /// **'Edit gaze'**
  String get editGaze;

  /// No description provided for @editReposition.
  ///
  /// In en, this message translates to:
  /// **'Edit Position'**
  String get editReposition;

  /// No description provided for @editRearrange.
  ///
  /// In en, this message translates to:
  /// **'Edit Arrangement'**
  String get editRearrange;

  /// No description provided for @editTexts.
  ///
  /// In en, this message translates to:
  /// **'Edit Texts'**
  String get editTexts;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get exporting;

  /// No description provided for @exportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Exported successfully'**
  String get exportedSuccessfully;

  /// No description provided for @saveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Export to Gallery'**
  String get saveToGallery;

  /// No description provided for @compactMode.
  ///
  /// In en, this message translates to:
  /// **'Compact Mode?'**
  String get compactMode;

  /// No description provided for @dualPrimary.
  ///
  /// In en, this message translates to:
  /// **'Dual Primary?'**
  String get dualPrimary;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @reposition.
  ///
  /// In en, this message translates to:
  /// **'Reposition'**
  String get reposition;

  /// No description provided for @rearrange.
  ///
  /// In en, this message translates to:
  /// **'Rearrange'**
  String get rearrange;

  /// No description provided for @texts.
  ///
  /// In en, this message translates to:
  /// **'Texts'**
  String get texts;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @addText.
  ///
  /// In en, this message translates to:
  /// **'Add Text'**
  String get addText;

  /// No description provided for @overlayTextHint.
  ///
  /// In en, this message translates to:
  /// **'Overlay text'**
  String get overlayTextHint;

  /// No description provided for @dragMovePinchScale.
  ///
  /// In en, this message translates to:
  /// **'Drag to move. Pinch selected text to scale.'**
  String get dragMovePinchScale;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(Object error);

  /// No description provided for @tapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap to add'**
  String get tapToAdd;

  /// No description provided for @slotTopLeft.
  ///
  /// In en, this message translates to:
  /// **'Top-left'**
  String get slotTopLeft;

  /// No description provided for @slotTopCenter.
  ///
  /// In en, this message translates to:
  /// **'Top-center'**
  String get slotTopCenter;

  /// No description provided for @slotTopRight.
  ///
  /// In en, this message translates to:
  /// **'Top-right'**
  String get slotTopRight;

  /// No description provided for @slotCenterLeft.
  ///
  /// In en, this message translates to:
  /// **'Center-left'**
  String get slotCenterLeft;

  /// No description provided for @slotCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get slotCenter;

  /// No description provided for @slotCenterRight.
  ///
  /// In en, this message translates to:
  /// **'Center-right'**
  String get slotCenterRight;

  /// No description provided for @slotBottomLeft.
  ///
  /// In en, this message translates to:
  /// **'Bottom-left'**
  String get slotBottomLeft;

  /// No description provided for @slotBottomCenter.
  ///
  /// In en, this message translates to:
  /// **'Bottom-center'**
  String get slotBottomCenter;

  /// No description provided for @slotBottomRight.
  ///
  /// In en, this message translates to:
  /// **'Bottom-right'**
  String get slotBottomRight;

  /// No description provided for @slotCenter2.
  ///
  /// In en, this message translates to:
  /// **'Center 2'**
  String get slotCenter2;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @pinchZoomDragTwist.
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom · Drag to pan · Twist to rotate'**
  String get pinchZoomDragTwist;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @recenter.
  ///
  /// In en, this message translates to:
  /// **'Recenter'**
  String get recenter;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @exportVerb.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportVerb;

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get exportDone;

  /// No description provided for @textDefault.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textDefault;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to 9Gaze'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Import your eye movement photos from the gallery and arrange them into a clean, labeled 3×3 grid. Auto-alignment handles the framing; you can fine-tune any slot. Export one composed image when you are done.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get onboardingGotIt;

  /// No description provided for @onboardingSkipTour.
  ///
  /// In en, this message translates to:
  /// **'Skip tour'**
  String get onboardingSkipTour;

  /// No description provided for @onboardingSkipConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip the tour?'**
  String get onboardingSkipConfirmTitle;

  /// No description provided for @onboardingSkipConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You can restart the tutorial anytime from the settings menu.'**
  String get onboardingSkipConfirmBody;

  /// No description provided for @onboardingHomeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your saved grids'**
  String get onboardingHomeEmptyTitle;

  /// No description provided for @onboardingHomeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Each gaze you create appears here. You have not made one yet. Tap the blue button below to start your first labeled grid.'**
  String get onboardingHomeEmptyBody;

  /// No description provided for @onboardingHomeCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a gaze'**
  String get onboardingHomeCreateTitle;

  /// No description provided for @onboardingHomeCreateBody.
  ///
  /// In en, this message translates to:
  /// **'Tap New Gaze to name your grid and begin importing photos.'**
  String get onboardingHomeCreateBody;

  /// No description provided for @onboardingCreateNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Name this gaze'**
  String get onboardingCreateNameTitle;

  /// No description provided for @onboardingCreateNameBody.
  ///
  /// In en, this message translates to:
  /// **'Only a name is required. Choose something you will recognize in the list.'**
  String get onboardingCreateNameBody;

  /// No description provided for @onboardingCreateNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get onboardingCreateNotesTitle;

  /// No description provided for @onboardingCreateNotesBody.
  ///
  /// In en, this message translates to:
  /// **'Optional notes for your own reference, such as a session label or date.'**
  String get onboardingCreateNotesBody;

  /// No description provided for @onboardingCreateSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Open your grid'**
  String get onboardingCreateSubmitTitle;

  /// No description provided for @onboardingCreateSubmitBody.
  ///
  /// In en, this message translates to:
  /// **'Tap Create Gaze. You will assign photos to each labeled slot next.'**
  String get onboardingCreateSubmitBody;

  /// No description provided for @onboardingDetailSlotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nine labeled slots'**
  String get onboardingDetailSlotsTitle;

  /// No description provided for @onboardingDetailSlotsBody.
  ///
  /// In en, this message translates to:
  /// **'Each slot matches a gaze direction. Tap a slot to import one photo from your gallery. Select several photos at once and 9Gaze fills empty slots in order.'**
  String get onboardingDetailSlotsBody;

  /// No description provided for @onboardingDetailPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from gallery'**
  String get onboardingDetailPickTitle;

  /// No description provided for @onboardingDetailPickBody.
  ///
  /// In en, this message translates to:
  /// **'Tap a slot (centre is a good first pick) and choose one or more photos. No in-app camera needed.'**
  String get onboardingDetailPickBody;

  /// No description provided for @onboardingDetailAutoAlignTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic eye alignment'**
  String get onboardingDetailAutoAlignTitle;

  /// No description provided for @onboardingDetailAutoAlignBody.
  ///
  /// In en, this message translates to:
  /// **'9Gaze detects the eye in each photo, centers it vertically, and fits the image to the horizontal boundaries of the slot so every cell looks consistently framed.'**
  String get onboardingDetailAutoAlignBody;

  /// No description provided for @onboardingDetailFineTuneTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual override'**
  String get onboardingDetailFineTuneTitle;

  /// No description provided for @onboardingDetailFineTuneBody.
  ///
  /// In en, this message translates to:
  /// **'Auto-alignment is not perfect on every photo. Open a slot for full control, or use Edit on this screen to adjust positions in the grid.'**
  String get onboardingDetailFineTuneBody;

  /// No description provided for @onboardingDetailLayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Layout options'**
  String get onboardingDetailLayoutTitle;

  /// No description provided for @onboardingDetailLayoutBody.
  ///
  /// In en, this message translates to:
  /// **'Compact Mode uses shorter slot cells. Dual Primary splits the centre slot into top and bottom. Only one layout option can be active at a time.'**
  String get onboardingDetailLayoutBody;

  /// No description provided for @onboardingDetailInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Gaze details'**
  String get onboardingDetailInfoTitle;

  /// No description provided for @onboardingDetailInfoBody.
  ///
  /// In en, this message translates to:
  /// **'The name and notes for this grid are here. Tap Update to change them anytime.'**
  String get onboardingDetailInfoBody;

  /// No description provided for @onboardingDetailTapSlotTitle.
  ///
  /// In en, this message translates to:
  /// **'Fine-tune this slot'**
  String get onboardingDetailTapSlotTitle;

  /// No description provided for @onboardingDetailTapSlotBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the slot you just filled. You can adjust position, zoom, and rotation on the next screen.'**
  String get onboardingDetailTapSlotBody;

  /// No description provided for @onboardingSlotGesturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust the framing'**
  String get onboardingSlotGesturesTitle;

  /// No description provided for @onboardingSlotGesturesBody.
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom, drag to pan, twist to rotate. Try a small adjustment if auto-alignment needs a nudge.'**
  String get onboardingSlotGesturesBody;

  /// No description provided for @onboardingSlotUndoTitle.
  ///
  /// In en, this message translates to:
  /// **'Undo and redo'**
  String get onboardingSlotUndoTitle;

  /// No description provided for @onboardingSlotUndoBody.
  ///
  /// In en, this message translates to:
  /// **'Tap Undo to step back, then Redo if you want to restore a change.'**
  String get onboardingSlotUndoBody;

  /// No description provided for @onboardingSlotToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Slot tools'**
  String get onboardingSlotToolsTitle;

  /// No description provided for @onboardingSlotToolsBody.
  ///
  /// In en, this message translates to:
  /// **'Recenter runs automatic eye alignment again. Reset clears manual edits from this session. Replace imports a different photo for this slot.'**
  String get onboardingSlotToolsBody;

  /// No description provided for @onboardingSlotSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save this slot'**
  String get onboardingSlotSaveTitle;

  /// No description provided for @onboardingSlotSaveBody.
  ///
  /// In en, this message translates to:
  /// **'Tap Save to return to your gaze grid.'**
  String get onboardingSlotSaveBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
