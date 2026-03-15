import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/settings_provider.dart';
import '../utils/responsive.dart';

/// One-time permission request screen shown after onboarding completes.
class PermissionPage extends ConsumerStatefulWidget {
  const PermissionPage({super.key});

  @override
  ConsumerState<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends ConsumerState<PermissionPage> {
  PermissionStatus _micStatus = PermissionStatus.denied;
  PermissionStatus _notifStatus = PermissionStatus.denied;
  bool _requesting = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkStatuses();
  }

  Future<void> _checkStatuses() async {
    final mic = await Permission.microphone.status;
    final notif = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _micStatus = mic;
        _notifStatus = notif;
        _checked = true;
      });
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _requesting = true);

    // Request microphone
    final micResult = await Permission.microphone.request();
    if (mounted) setState(() => _micStatus = micResult);

    // Request notifications (Android 13+ only; older versions auto-grant)
    final notifResult = await Permission.notification.request();
    if (mounted) setState(() => _notifStatus = notifResult);

    if (mounted) setState(() => _requesting = false);

    // If mic permanently denied, show guidance instead of finishing
    if (micResult.isPermanentlyDenied && mounted) {
      _showPermanentlyDeniedDialog();
      return;
    }

    _finish();
  }

  void _finish() {
    ref.read(settingsProvider.notifier).setPermissionScreenShown(true);
    context.go(AppRoutes.home);
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Microphone Access Required'),
        content: const Text(
          'Microphone permission was denied permanently. '
          'Please open Settings and grant microphone access '
          'to use voice recording features.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finish();
            },
            child: const Text('Skip for Now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: ResponsiveCenter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _requesting ? null : _finish,
                    child: Text('Later',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: theme.hintColor)),
                  ),
                ),
                const Spacer(flex: 2),
                // Shield icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(Icons.security_rounded,
                        color: primary, size: 56),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'App Permissions',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Privacy-first, always.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                // Permission cards
                _PermissionCard(
                  icon: Icons.mic_rounded,
                  iconColor: const Color(0xFF2E7D32),
                  iconBg: const Color(0xFFE8F5E9),
                  title: 'Microphone',
                  description:
                      'Record and transcribe your voice notes on-device. '
                      'Audio never leaves your phone.',
                  status: _micStatus,
                  checked: _checked,
                ),
                const SizedBox(height: 12),
                _PermissionCard(
                  icon: Icons.notifications_rounded,
                  iconColor: const Color(0xFF1565C0),
                  iconBg: const Color(0xFFE3F2FD),
                  title: 'Notifications',
                  description:
                      'Get reminders for your tasks and notes. '
                      'You can skip this.',
                  status: _notifStatus,
                  checked: _checked,
                  isOptional: true,
                ),
                const Spacer(flex: 3),
                // Grant button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _requesting ? null : _requestPermissions,
                    icon: _requesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                        _requesting ? 'Requesting...' : 'Grant Access'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You can change these anytime in Settings.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;
  final PermissionStatus status;
  final bool checked;
  final bool isOptional;

  const _PermissionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.status,
    required this.checked,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGranted = status.isGranted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted && checked
              ? const Color(0xFF2E7D32).withValues(alpha: 0.3)
              : theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(icon, color: iconColor, size: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (isOptional) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.hintColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Optional',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.hintColor,
                              fontSize: 10,
                            )),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(description,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor, height: 1.4)),
              ],
            ),
          ),
          if (checked && isGranted) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF2E7D32),
              size: 22,
            ),
          ],
        ],
      ),
    );
  }
}
