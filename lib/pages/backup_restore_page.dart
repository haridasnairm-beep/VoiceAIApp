import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import '../theme.dart';

const _frequencyLabels = {
  'daily': 'Daily',
  'every3days': 'Every 3 days',
  'weekly': 'Weekly',
};

const _maxCountOptions = [3, 5, 10];

String _fmtDate(DateTime dt) {
  final d = dt.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '${months[d.month - 1]} ${d.day}, ${d.year}  $h:$m $ampm';
}

class BackupRestorePage extends ConsumerStatefulWidget {
  final String? restoreFilePath;

  const BackupRestorePage({super.key, this.restoreFilePath});

  @override
  ConsumerState<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends ConsumerState<BackupRestorePage> {
  // Section expansion state
  bool _autoBackupExpanded = true;
  bool _createBackupExpanded = false;
  bool _restoreBackupExpanded = false;

  // Auto-backup state
  final _autoPassCtrl = TextEditingController();
  bool _autoPassVisible = false;
  bool _isAutoPassSet = false;

  // Create backup state
  final _createPassCtrl = TextEditingController();
  final _createConfirmCtrl = TextEditingController();
  bool _createPassVisible = false;
  bool _createConfirmVisible = false;
  bool _includeAudio = true;
  bool _isCreating = false;
  String _createStatus = '';
  double _createProgress = 0;

  // Restore backup state
  String? _restoreFilePath;
  final _restorePassCtrl = TextEditingController();
  bool _restorePassVisible = false;
  bool _isPreviewLoading = false;
  bool _isRestoring = false;
  BackupManifest? _previewManifest;
  String _restoreStatus = '';
  double _restoreProgress = 0;

  @override
  void initState() {
    super.initState();
    _checkAutoPassphrase();
    if (widget.restoreFilePath != null) {
      _restoreFilePath = widget.restoreFilePath;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _previewBackup();
      });
    }
  }

  Future<void> _checkAutoPassphrase() async {
    final pass = await BackupService.getAutoBackupPassphrase();
    if (mounted) {
      setState(() => _isAutoPassSet = pass != null && pass.isNotEmpty);
    }
  }

  @override
  void dispose() {
    _autoPassCtrl.dispose();
    _createPassCtrl.dispose();
    _createConfirmCtrl.dispose();
    _restorePassCtrl.dispose();
    super.dispose();
  }

  String _nextAutoBackupLabel(String frequency, DateTime? lastRun) {
    if (lastRun == null) return 'first backup on next launch';
    final Duration interval;
    switch (frequency) {
      case 'daily':
        interval = const Duration(hours: 24);
        break;
      case 'every3days':
        interval = const Duration(hours: 72);
        break;
      case 'weekly':
      default:
        interval = const Duration(days: 7);
    }
    final next = lastRun.add(interval);
    final now = DateTime.now();
    if (next.isBefore(now)) return 'next launch';
    final diff = next.difference(now);
    if (diff.inDays > 0) return 'in ${diff.inDays}d';
    if (diff.inHours > 0) return 'in ${diff.inHours}h';
    return 'soon';
  }

  // ─── Auto-Backup ───────────────────────────────────────────────────────────

  Future<void> _enableAutoBackup() async {
    final pass = _autoPassCtrl.text.trim();
    if (pass.isEmpty) {
      _showError('Please enter a passphrase for auto-backup.');
      return;
    }
    if (pass.length < 6) {
      _showError('Passphrase must be at least 6 characters.');
      return;
    }
    await BackupService.setAutoBackupPassphrase(pass);
    await ref.read(settingsProvider.notifier).setAutoBackupEnabled(true);
    setState(() {
      _isAutoPassSet = true;
      _autoPassCtrl.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-backup enabled.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _disableAutoBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable Auto-Backup?'),
        content: const Text(
          'Your existing auto-backup files will be kept, but no new ones will be created automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await BackupService.clearAutoBackupPassphrase();
    await ref.read(settingsProvider.notifier).setAutoBackupEnabled(false);
    setState(() => _isAutoPassSet = false);
  }

  Future<void> _changeAutoPassphrase() async {
    final ctrl = TextEditingController();
    bool visible = false;
    final newPass = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change Passphrase'),
          content: TextField(
            controller: ctrl,
            obscureText: !visible,
            decoration: InputDecoration(
              labelText: 'New passphrase',
              hintText: 'Min. 6 characters',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setDialogState(() => visible = !visible),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final p = ctrl.text.trim();
                if (p.length < 6) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Passphrase must be at least 6 characters.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, p);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (newPass != null) {
      await BackupService.setAutoBackupPassphrase(newPass);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-backup passphrase updated.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ─── Create Backup ─────────────────────────────────────────────────────────

  Future<void> _createBackup() async {
    final pass = _createPassCtrl.text.trim();
    final confirm = _createConfirmCtrl.text.trim();
    if (pass.isEmpty) {
      _showError('Please enter a passphrase.');
      return;
    }
    if (pass.length < 6) {
      _showError('Passphrase must be at least 6 characters.');
      return;
    }
    if (pass != confirm) {
      _showError('Passphrases do not match.');
      return;
    }

    setState(() {
      _isCreating = true;
      _createStatus = 'Starting…';
      _createProgress = 0;
    });

    try {
      final manifest = await BackupService.createAndShareBackup(
        passphrase: pass,
        includeAudio: _includeAudio,
        onProgress: (status, progress) {
          if (mounted) {
            setState(() {
              _createStatus = status;
              _createProgress = progress;
            });
          }
        },
      );

      // Save last backup date
      await ref.read(settingsProvider.notifier).setLastBackupDate(manifest.createdAt);

      if (mounted) {
        setState(() {
          _isCreating = false;
          _createStatus = '';
          _createProgress = 0;
        });
        _createPassCtrl.clear();
        _createConfirmCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup created: ${manifest.noteCount} notes, ${manifest.folderCount} folders.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _createStatus = '';
          _createProgress = 0;
        });
        _showError('Backup failed: $e');
      }
    }
  }

  // ─── Restore Backup ────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _restoreFilePath = result.files.single.path;
        _previewManifest = null;
        _restorePassCtrl.clear();
      });
    }
  }

  Future<void> _previewBackup() async {
    final pass = _restorePassCtrl.text.trim();
    if (_restoreFilePath == null) {
      _showError('Please select a backup file first.');
      return;
    }
    if (pass.isEmpty) {
      _showError('Please enter the backup passphrase.');
      return;
    }

    setState(() {
      _isPreviewLoading = true;
      _previewManifest = null;
    });

    try {
      final manifest = await BackupService.previewBackup(
        filePath: _restoreFilePath!,
        passphrase: pass,
      );
      if (mounted) {
        setState(() {
          _isPreviewLoading = false;
          _previewManifest = manifest;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPreviewLoading = false;
        });
        String msg = e.toString();
        if (msg.contains('padding') || msg.contains('decrypt') || msg.contains('Invalid')) {
          msg = 'Wrong passphrase or corrupted backup file.';
        }
        _showError('Preview failed: $msg');
      }
    }
  }

  Future<void> _confirmAndRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text(
          'This will permanently replace ALL current notes, folders, and settings with the backup data.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isRestoring = true;
      _restoreStatus = 'Starting…';
      _restoreProgress = 0;
    });

    try {
      await BackupService.restoreBackup(
        filePath: _restoreFilePath!,
        passphrase: _restorePassCtrl.text.trim(),
        onProgress: (status, progress) {
          if (mounted) {
            setState(() {
              _restoreStatus = status;
              _restoreProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        // Reload providers after restore
        ref.invalidate(settingsProvider);

        setState(() {
          _isRestoring = false;
          _restoreStatus = '';
          _restoreProgress = 0;
          _restoreFilePath = null;
          _previewManifest = null;
          _restorePassCtrl.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restore complete! Please restart the app.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRestoring = false;
          _restoreStatus = '';
          _restoreProgress = 0;
        });
        _showError('Restore failed: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: const Text('Backup & Restore'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Last backup info
              if (settings.lastBackupDate != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: _InfoCard(
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
                    message:
                        'Last backup: ${_fmtDate(settings.lastBackupDate!)}',
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // ── AUTO BACKUP ───────────────────────────────────────────────
              _CollapsibleSection(
                icon: Icons.schedule_rounded,
                label: 'Auto Backup',
                color: scheme.tertiary,
                initiallyExpanded: _autoBackupExpanded,
                onExpansionChanged: (v) => _autoBackupExpanded = v,
                children: [
                  const _InfoCard(
                    icon: Icons.info_outline,
                    message:
                        'Automatically backs up your data on a schedule. Backups are encrypted and stored on your device.',
                  ),
                  const SizedBox(height: 16),

                  if (!settings.autoBackupEnabled) ...[
                    // Setup: passphrase entry + enable
                    if (!_isAutoPassSet) ...[
                      TextField(
                        controller: _autoPassCtrl,
                        obscureText: !_autoPassVisible,
                        decoration: InputDecoration(
                          labelText: 'Auto-backup passphrase',
                          hintText: 'Min. 6 characters',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _autoPassVisible ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _autoPassVisible = !_autoPassVisible,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton.tonal(
                      onPressed: _isAutoPassSet
                          ? () async {
                              await ref.read(settingsProvider.notifier).setAutoBackupEnabled(true);
                            }
                          : _enableAutoBackup,
                      child: const Text('Enable Auto Backup'),
                    ),
                  ] else ...[
                    // Active: show settings
                    _ToggleRow(
                      icon: Icons.schedule_rounded,
                      label: 'Auto Backup',
                      sublabel: 'Next: ${_nextAutoBackupLabel(settings.autoBackupFrequency, settings.autoBackupLastRun)}',
                      value: true,
                      onChanged: (_) => _disableAutoBackup(),
                    ),
                    const SizedBox(height: 12),

                    // Frequency picker
                    Container(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.repeat_rounded, size: 22),
                        title: const Text('Frequency'),
                        trailing: DropdownButton<String>(
                          value: settings.autoBackupFrequency,
                          underline: const SizedBox.shrink(),
                          items: _frequencyLabels.entries
                              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              ref.read(settingsProvider.notifier).setAutoBackupFrequency(v);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Max count picker
                    Container(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.inventory_2_outlined, size: 22),
                        title: const Text('Keep last'),
                        trailing: DropdownButton<int>(
                          value: settings.autoBackupMaxCount,
                          underline: const SizedBox.shrink(),
                          items: _maxCountOptions
                              .map((n) => DropdownMenuItem(value: n, child: Text('$n backups')))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              ref.read(settingsProvider.notifier).setAutoBackupMaxCount(v);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Change passphrase
                    TextButton.icon(
                      onPressed: _changeAutoPassphrase,
                      icon: const Icon(Icons.key_rounded, size: 18),
                      label: const Text('Change passphrase'),
                    ),

                    if (settings.autoBackupLastRun != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last auto-backup: ${_fmtDate(settings.autoBackupLastRun!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // ── CREATE BACKUP ──────────────────────────────────────────────
              _CollapsibleSection(
                icon: Icons.upload_file_rounded,
                label: 'Create Backup',
                color: scheme.primary,
                initiallyExpanded: _createBackupExpanded,
                onExpansionChanged: (v) => _createBackupExpanded = v,
                children: [
                  const _InfoCard(
                    icon: Icons.info_outline,
                    message:
                        'Creates an encrypted .vnbak file containing all your notes, folders, settings, and images. Store it in a safe place — you will need your passphrase to restore.',
                  ),
                  const SizedBox(height: 16),

                  // Passphrase
                  TextField(
                    controller: _createPassCtrl,
                    obscureText: !_createPassVisible,
                    decoration: InputDecoration(
                      labelText: 'Backup passphrase',
                      hintText: 'Min. 6 characters',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _createPassVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _createPassVisible = !_createPassVisible,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Confirm passphrase
                  TextField(
                    controller: _createConfirmCtrl,
                    obscureText: !_createConfirmVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirm passphrase',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _createConfirmVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _createConfirmVisible = !_createConfirmVisible,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Include audio toggle
                  _ToggleRow(
                    icon: Icons.music_note_outlined,
                    label: 'Include audio recordings',
                    sublabel: 'Backup may be significantly larger',
                    value: _includeAudio,
                    onChanged: (v) => setState(() => _includeAudio = v),
                  ),
                  const SizedBox(height: 16),

                  // Progress
                  if (_isCreating) ...[
                    LinearProgressIndicator(value: _createProgress),
                    const SizedBox(height: 8),
                    Text(
                      _createStatus,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],

                  FilledButton.icon(
                    onPressed: _isCreating ? null : _createBackup,
                    icon: _isCreating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.backup),
                    label: Text(_isCreating ? 'Creating…' : 'Create Backup'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── RESTORE BACKUP ─────────────────────────────────────────────
              _CollapsibleSection(
                icon: Icons.cloud_download_outlined,
                label: 'Restore Backup',
                color: scheme.secondary,
                initiallyExpanded: _restoreBackupExpanded,
                onExpansionChanged: (v) => _restoreBackupExpanded = v,
                children: [
                  const _InfoCard(
                    icon: Icons.warning_amber_outlined,
                    iconColor: Colors.orange,
                    message:
                        'Restoring will replace ALL current data. Make sure you have selected the correct backup file and remember your passphrase.',
                  ),
                  const SizedBox(height: 16),

                  // File picker
                  OutlinedButton.icon(
                    onPressed: (_isRestoring || _isPreviewLoading) ? null : _pickFile,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: Text(
                      _restoreFilePath != null
                          ? _restoreFilePath!.split(Platform.pathSeparator).last
                          : 'Select .vnbak file',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  if (_restoreFilePath != null) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _restorePassCtrl,
                      obscureText: !_restorePassVisible,
                      decoration: InputDecoration(
                        labelText: 'Backup passphrase',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _restorePassVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _restorePassVisible = !_restorePassVisible,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Preview button
                    OutlinedButton.icon(
                      onPressed:
                          (_isPreviewLoading || _isRestoring) ? null : _previewBackup,
                      icon: _isPreviewLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.preview_outlined),
                      label: Text(
                        _isPreviewLoading ? 'Verifying…' : 'Verify & Preview',
                      ),
                    ),
                  ],

                  // Manifest preview card
                  if (_previewManifest != null) ...[
                    const SizedBox(height: 16),
                    _ManifestCard(manifest: _previewManifest!),
                    const SizedBox(height: 16),

                    // Progress
                    if (_isRestoring) ...[
                      LinearProgressIndicator(value: _restoreProgress),
                      const SizedBox(height: 8),
                      Text(
                        _restoreStatus,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                    ],

                    FilledButton.icon(
                      onPressed: _isRestoring ? null : _confirmAndRestore,
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                      ),
                      icon: _isRestoring
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.restore),
                      label: Text(_isRestoring ? 'Restoring…' : 'Restore Backup'),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _CollapsibleSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final List<Widget> children;

  const _CollapsibleSection({
    required this.icon,
    required this.label,
    required this.color,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        children: children,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String message;

  const _InfoCard({
    required this.icon,
    this.iconColor,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18,
              color: iconColor ?? scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    this.sublabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, size: 22),
        title: Text(label),
        subtitle: sublabel != null ? Text(sublabel!) : null,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _ManifestCard extends StatelessWidget {
  final BackupManifest manifest;

  const _ManifestCard({required this.manifest});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, color: scheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Backup verified',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ManifestRow('Created', _fmtDate(manifest.createdAt)),
          _ManifestRow('App version', manifest.appVersion),
          _ManifestRow('Notes', '${manifest.noteCount}'),
          _ManifestRow('Folders', '${manifest.folderCount}'),
          _ManifestRow('Projects', '${manifest.projectDocumentCount}'),
          _ManifestRow('Images', '${manifest.imageCount}'),
          _ManifestRow(
              'Audio included', manifest.includesAudio ? 'Yes' : 'No'),
        ],
      ),
    );
  }
}

class _ManifestRow extends StatelessWidget {
  final String label;
  final String value;

  const _ManifestRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
