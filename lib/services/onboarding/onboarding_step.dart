// Ordered steps for the first-run and manual-replay onboarding tours.

/// Every showcase or dialog step in the onboarding flow.
enum OnboardingStep {
  welcome,
  homeEmptyList,
  homeCreateButton,
  createName,
  createNotes,
  createSubmit,
  detailSlotsGrid,
  detailPickSlot,
  detailAutoAlign,
  detailFineTuneIntro,
  detailCompactDual,
  detailInfoEdit,
  detailTapFilledSlot,
  slotEditorGestures,
  slotEditorUndoRedo,
  slotEditorTools,
  slotEditorSave,
  detailBulkEditButton,
  detailEditMenu,
  detailReposition,
  detailRearrange,
  detailText,
  detailExport,
  complete;

  /// True for the gaze-detail intro, before the slot editor.
  bool get isGazeDetailIntro {
    return switch (this) {
      detailSlotsGrid ||
      detailPickSlot ||
      detailAutoAlign ||
      detailFineTuneIntro ||
      detailCompactDual ||
      detailInfoEdit => true,
      _ => false,
    };
  }

  /// True while the tour is on the slot editor screen.
  bool get isSlotEditorStep {
    return switch (this) {
      slotEditorGestures ||
      slotEditorUndoRedo ||
      slotEditorTools ||
      slotEditorSave => true,
      _ => false,
    };
  }
}
