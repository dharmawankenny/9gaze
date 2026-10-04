// Settings: backups, storage usage, tutorial, and about.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kensa_9gaze/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/services/app_storage_info.dart';
import 'package:kensa_9gaze/services/data_backup.dart';

/// Full settings page opened from the home header.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onRestartTutorial});

  /// Restarts the home tutorial after this page is closed.
  final Future<void> Function() onRestartTutorial;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppStorageSnapshot? _storage;
  String? _versionLabel;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadStorage();
    _loadVersion();
  }

  /// Reads photo and database paths plus their sizes.
  Future<void> _loadStorage() async {
    final snapshot = await AppStorageInfo.load();
    if (!mounted) return;
    setState(() => _storage = snapshot);
  }

  /// Reads the installed version for the About section.
  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final label = '${info.version} (${info.buildNumber})';
      if (!mounted) return;
      setState(() => _versionLabel = label);
    } catch (_) {
      if (!mounted) return;
      setState(() => _versionLabel = '1.2.0 (3)');
    }
  }

  /// Writes a `.9gaze` zip and hands it to the system save dialog.
  Future<void> _handleExport() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final bytes = await DataBackup.exportBytes();
      final now = DateTime.now();
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      final saved = await FilePicker.saveFile(
        dialogTitle: l10n.settingsExportData,
        fileName: '9gaze-${now.year}-$month-$day.9gaze',
        bytes: bytes,
        allowedExtensions: const ['9gaze'],
      );
      if (!mounted || saved == null) return;
      _showMessage(l10n.settingsExportSuccess);
    } on BackupException catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(l10n, error), isError: true);
    } catch (_) {
      if (!mounted) return;
      _showMessage(l10n.settingsBackupFailed, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Picks a backup, confirms replacement, then restores it.
  Future<void> _handleImport() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    // Android filters the picker by MIME type. .9gaze has none, so a
    // custom filter leaves the exported file visible but untappable.
    // Accept any file, then reject archives that are not a backup.
    final picked = await FilePicker.pickFile(
      dialogTitle: l10n.settingsImportData,
      type: FileType.any,
    );
    if (picked == null || !mounted) return;

    final confirmed = await _confirmImport(l10n);
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      final file = await _materializePickedFile(picked);
      await DataBackup.importFile(file);
      await _loadStorage();
      if (!mounted) return;
      _showMessage(l10n.settingsImportSuccess);
    } on BackupException catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(l10n, error), isError: true);
    } catch (_) {
      if (!mounted) return;
      _showMessage(l10n.settingsBackupFailed, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Asks before a restore that deletes every gaze on device.
  Future<bool> _confirmImport(AppLocalizations l10n) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kDarkBlue,
          title: Text(
            l10n.settingsImportConfirmTitle,
            style: GoogleFonts.bricolageGrotesque(
              color: kWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            l10n.settingsImportConfirmBody,
            style: GoogleFonts.bricolageGrotesque(
              color: kWhite.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                l10n.cancel,
                style: GoogleFonts.bricolageGrotesque(color: kWhite),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                l10n.settingsImportConfirmAction,
                style: GoogleFonts.bricolageGrotesque(color: kAccentBlue),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Copies a content-URI pick into a real temp file when needed.
  Future<File> _materializePickedFile(PlatformFile picked) async {
    final path = picked.path;
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) return file;
    }
    final bytes = await picked.readAsBytes();
    final dir = await getTemporaryDirectory();
    final file = File(
      p.join(
        dir.path,
        '9gaze-picked-${DateTime.now().millisecondsSinceEpoch}.9gaze',
      ),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Closes settings, then starts the tutorial on the home screen.
  Future<void> _handleRestartTutorial() async {
    if (_busy) return;
    final restart = widget.onRestartTutorial;
    Navigator.of(context).pop();
    await restart();
  }

  /// Maps a backup failure to a localized sentence.
  String _messageFor(AppLocalizations l10n, BackupException error) {
    switch (error.failure) {
      case BackupFailure.unsupported:
        return l10n.settingsBackupUnsupported;
      case BackupFailure.unreadable:
        return l10n.settingsBackupUnreadable;
    }
  }

  /// Shows a short result under the page.
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.redAccent : kDarkBlue,
        content: Text(
          message,
          style: GoogleFonts.bricolageGrotesque(color: kWhite),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final storage = _storage;
    final version = _versionLabel;

    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        backgroundColor: kDarkBlue,
        foregroundColor: kWhite,
        title: Text(
          l10n.settings,
          style: GoogleFonts.bricolageGrotesque(
            color: kWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              _SectionLabel(l10n.settingsBackups),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.file_upload_outlined,
                    title: l10n.settingsExportData,
                    subtitle: l10n.settingsExportBody,
                    onTap: _busy ? null : _handleExport,
                  ),
                  _SettingsTile(
                    icon: Icons.file_download_outlined,
                    title: l10n.settingsImportData,
                    subtitle: l10n.settingsImportBody,
                    onTap: _busy ? null : _handleImport,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionLabel(l10n.settingsStorage),
              _SettingsCard(
                children: [
                  if (storage == null)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    _StorageBlock(
                      title: l10n.settingsPhotos,
                      path: storage.imagesPath,
                      usage: formatStorageBytes(storage.imagesBytes),
                    ),
                    _StorageBlock(
                      title: l10n.settingsDatabase,
                      path: storage.databasePath,
                      usage: formatStorageBytes(storage.databaseBytes),
                    ),
                    _StorageBlock(
                      title: l10n.settingsTotalUsage,
                      usage: formatStorageBytes(storage.totalBytes),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              _SectionLabel(l10n.settingsTutorial),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.replay,
                    title: l10n.restartTutorial,
                    subtitle: l10n.settingsRestartBody,
                    onTap: _busy ? null : _handleRestartTutorial,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionLabel(l10n.aboutApp),
              _SettingsCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appTitle,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: kWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          version == null ? '' : l10n.aboutVersion(version),
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 14,
                            color: kWhite.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.aboutAppBody,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 15,
                            height: 1.45,
                            color: kWhite.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          '9gaze@atelierkensa.com',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: kAccentBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_busy)
            const ModalBarrier(dismissible: false, color: Color(0x88000000)),
          if (_busy) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

/// Small heading above a settings group.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: kWhite.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

/// Rounded group of settings rows.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: kDarkBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// One tappable row inside a settings card.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: onTap != null,
      leading: Icon(icon, color: kWhite),
      title: Text(
        title,
        style: GoogleFonts.bricolageGrotesque(
          color: kWhite,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.bricolageGrotesque(
          color: kWhite.withValues(alpha: 0.55),
          height: 1.35,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// Path and size for one storage location.
class _StorageBlock extends StatelessWidget {
  const _StorageBlock({required this.title, required this.usage, this.path});

  final String title;
  final String usage;
  final String? path;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.bricolageGrotesque(
                    color: kWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                usage,
                style: GoogleFonts.bricolageGrotesque(
                  color: kAccentBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (path != null) ...[
            const SizedBox(height: 6),
            SelectableText(
              path!,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 12,
                height: 1.35,
                color: kWhite.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
