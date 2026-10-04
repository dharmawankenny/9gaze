// Confirmation dialog before the user skips the onboarding tour.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/l10n/app_localizations.dart';

/// Asks the user to confirm skipping the tour.
class OnboardingSkipConfirmDialog {
  OnboardingSkipConfirmDialog._();

  /// Returns true when the user confirms skip.
  ///
  /// Inserts above the tour overlay. Cancel leaves that overlay in place.
  static Future<bool> show(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overlay = context.findRootAncestorStateOfType<OverlayState>();
    if (overlay == null) return Future<bool>.value(false);

    final completer = Completer<bool>();
    late OverlayEntry entry;

    /// Removes the alert and finishes [show] with [confirmed].
    void finish(bool confirmed) {
      if (completer.isCompleted) return;
      entry.remove();
      completer.complete(confirmed);
    }

    entry = OverlayEntry(
      builder: (_) => _SkipConfirmLayer(
        title: l10n.onboardingSkipConfirmTitle,
        body: l10n.onboardingSkipConfirmBody,
        cancelLabel: l10n.cancel,
        confirmLabel: l10n.yes,
        onCancel: () => finish(false),
        onConfirm: () => finish(true),
      ),
    );
    overlay.insert(entry);
    return completer.future;
  }
}

/// Full-screen dimmer and the skip alert, above the tour overlay.
class _SkipConfirmLayer extends StatefulWidget {
  const _SkipConfirmLayer({
    required this.title,
    required this.body,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  final String title;
  final String body;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  State<_SkipConfirmLayer> createState() => _SkipConfirmLayerState();
}

class _SkipConfirmLayerState extends State<_SkipConfirmLayer>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Treats system back as Cancel so the page underneath stays put.
  @override
  Future<bool> didPopRoute() async {
    widget.onCancel();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          const ModalBarrier(dismissible: false, color: Color(0xBF000000)),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Material(
                  color: kBlack,
                  elevation: 12,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.bricolageGrotesque(
                            color: kWhite,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.body,
                          style: GoogleFonts.bricolageGrotesque(
                            color: kWhite.withValues(alpha: 0.75),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: widget.onCancel,
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFF3A3A3A),
                                  foregroundColor: kWhite,
                                  minimumSize: const Size.fromHeight(48),
                                  alignment: Alignment.center,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  widget.cancelLabel,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.bricolageGrotesque(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextButton(
                                onPressed: widget.onConfirm,
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFD32F2F),
                                  foregroundColor: kWhite,
                                  minimumSize: const Size.fromHeight(48),
                                  alignment: Alignment.center,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  widget.confirmLabel,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.bricolageGrotesque(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
