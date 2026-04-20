// Bottom sheet form for creating a new Gaze entry. Shows a
// single patient-name field and a submit button. On submit it
// writes to the DB, switches the button to a 'Created' state,
// waits 500 ms, then closes the sheet.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/db/database_provider.dart';
import 'package:kensa_9gaze/repositories/gazes_repository.dart';
import 'package:kensa_9gaze/screens/gaze_detail/gaze_detail_screen.dart';
import 'package:kensa_9gaze/widgets/animated_gaze_face.dart';

/// Modal bottom sheet content for the "New Gaze" flow.
///
/// Owns the text field, submission logic, and the transient
/// 'Created' confirmation state before auto-closing.
class NewGazeSheet extends StatefulWidget {
  const NewGazeSheet({super.key});

  @override
  State<NewGazeSheet> createState() => _NewGazeSheetState();
}

class _NewGazeSheetState extends State<NewGazeSheet> {
  final _repo = GazesRepository(appDatabase);
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _focusNode = FocusNode();

  /// True while the async insert is in-flight.
  bool _loading = false;

  /// True after a successful insert, triggers the confirmation UI.
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Validates, inserts the gaze, shows confirmation, closes the
  /// sheet, then pushes [GazeDetailScreen] with the new row.
  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _loading || _submitted) return;

    setState(() => _loading = true);

    final notes = _notesController.text.trim();
    final newId = await _repo.create(name, notes: notes.isEmpty ? null : notes);
    final newGaze = await _repo.getById(newId);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _submitted = true;
    });

    // Brief confirmation pause before navigating away.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    // Pop the sheet first, then push the detail screen so the
    // back button on the detail screen returns to home.
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GazeDetailScreen(gaze: newGaze)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hintColor = kWhite.withValues(alpha: 0.5);
    // Pad above keyboard so the field stays visible.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 32 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ──────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: kWhite.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Sheet title ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Gaze Details',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kWhite,
              ),
            ),
          ),

          // ── Patient name field ───────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            decoration: BoxDecoration(
              color: kDarkBlue,
              borderRadius: BorderRadius.circular(50),
            ),
            child: TextField(
              controller: _nameController,
              focusNode: _focusNode,
              autofocus: true,
              enabled: !_submitted,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleSubmit(),
              style: GoogleFonts.bricolageGrotesque(
                color: kWhite,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Patient name',
                hintStyle: GoogleFonts.bricolageGrotesque(
                  color: hintColor,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Notes textarea ───────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: kDarkBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _notesController,
              enabled: !_submitted,
              maxLines: 4,
              minLines: 3,
              textInputAction: TextInputAction.newline,
              style: GoogleFonts.bricolageGrotesque(
                color: kWhite,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Notes (optional)',
                hintStyle: GoogleFonts.bricolageGrotesque(
                  color: hintColor,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Submit button ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitted ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _submitted
                    ? kAccentBlue.withValues(alpha: 0.6)
                    : kAccentBlue,
                foregroundColor: kWhite,
                disabledBackgroundColor: _submitted
                    ? kAccentBlue.withValues(alpha: 0.6)
                    : null,
                disabledForegroundColor: kWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _submitted
                  ? _buildSubmittedContent()
                  : _buildIdleContent(),
            ),
          ),
        ],
      ),
    );
  }

  /// Button content after successful insert.
  Widget _buildSubmittedContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        AnimatedGazeFace.static(
          direction: GazeDirection.levoelevation,
          size: 28,
          eyeColor: kAccentBlue.withValues(alpha: 0.6),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Created',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kWhite,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ),
        const Icon(Icons.check, color: kWhite, size: 24),
      ],
    );
  }

  /// Default idle button content.
  Widget _buildIdleContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Create Gaze',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kWhite,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ),
        const Icon(Icons.arrow_forward, color: kWhite, size: 24),
      ],
    );
  }
}
