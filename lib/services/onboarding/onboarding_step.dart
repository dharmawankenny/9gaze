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

  /// True for the bulk-edit tour on the gaze detail screen.
  bool get isBulkEditStep {
    return switch (this) {
      detailBulkEditButton ||
      detailEditMenu ||
      detailReposition ||
      detailRearrange ||
      detailText => true,
      _ => false,
    };
  }
}

/// Which control a bulk-edit step is highlighting.
enum OnboardingBulkFocus {
  /// The mode button on the edit menu, before that mode opens.
  pickMode,

  /// Grid, edit menu, or Add Text, depending on the step.
  primary,

  /// Text-mode explanation after a label is added.
  coach,

  /// Save action for the current edit mode.
  save,

  /// Done, which leaves edit mode.
  exit,
}
