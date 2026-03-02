import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/settings_provider.dart';
import '../services/app_lock_service.dart';
import '../widgets/settings_widgets.dart';

class SecurityPage extends ConsumerStatefulWidget {
  const SecurityPage({super.key});

  @override
  ConsumerState<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends ConsumerState<SecurityPage> {
  final _localAuth = LocalAuthentication();
  bool _hasBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final available = await _localAuth.getAvailableBiometrics();
      if (mounted) {
        setState(() => _hasBiometrics = canCheck && available.isNotEmpty);
      }
    } catch (_) {
      // No biometric hardware
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        title: const Text('Security'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsItem(
            icon: Icons.lock_rounded,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1565C0),
            label: 'App Lock',
            type: SettingsType.toggle,
            switchValue: settings.appLockEnabled,
            onChanged: (val) {
              if (val) {
                _showPinSetupFlow();
              } else {
                _confirmDisableAppLock();
              }
            },
          ),
          if (settings.appLockEnabled) ...[
            const Divider(height: 1, indent: 56),
            SettingsItem(
              icon: Icons.dialpad_rounded,
              iconBg: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFE65100),
              label: 'Change PIN',
              type: SettingsType.chevron,
              onTap: () => _showChangePinFlow(),
            ),
            if (_hasBiometrics) ...[
              const Divider(height: 1, indent: 56),
              SettingsItem(
                icon: Icons.fingerprint_rounded,
                iconBg: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF2E7D32),
                label: 'Biometric Unlock',
                type: SettingsType.toggle,
                switchValue: settings.biometricEnabled,
                onChanged: (val) async {
                  if (val) {
                    // Test biometric first
                    try {
                      final didAuth = await _localAuth.authenticate(
                        localizedReason: 'Verify biometric to enable',
                        options: const AuthenticationOptions(
                          biometricOnly: true,
                        ),
                      );
                      if (didAuth) {
                        ref.read(settingsProvider.notifier)
                            .setBiometricEnabled(true);
                      }
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Biometric not available')),
                        );
                      }
                    }
                  } else {
                    ref.read(settingsProvider.notifier)
                        .setBiometricEnabled(false);
                  }
                },
              ),
            ],
            const Divider(height: 1, indent: 56),
            SettingsItem(
              icon: Icons.timer_rounded,
              iconBg: const Color(0xFFF3E5F5),
              iconColor: const Color(0xFF7B1FA2),
              label: 'Auto-Lock Timeout',
              type: SettingsType.value,
              valueText: _timeoutLabel(settings.autoLockTimeoutSeconds),
              onTap: () => _showTimeoutPicker(settings.autoLockTimeoutSeconds),
            ),
          ],
          const SizedBox(height: 24),
          // Info text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              settings.appLockEnabled
                  ? 'Your notes are protected. The app will lock after the timeout period.'
                  : 'Enable App Lock to protect your notes with a PIN or biometric authentication.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _timeoutLabel(int seconds) {
    switch (seconds) {
      case 0:
        return 'Immediately';
      case 60:
        return '1 minute';
      case 300:
        return '5 minutes';
      case 900:
        return '15 minutes';
      default:
        return 'Immediately';
    }
  }

  void _showTimeoutPicker(int currentTimeout) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Auto-Lock Timeout'),
        children: [
          for (final entry in {
            0: 'Immediately',
            60: 'After 1 minute',
            300: 'After 5 minutes',
            900: 'After 15 minutes',
          }.entries)
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(settingsProvider.notifier)
                    .setAutoLockTimeout(entry.key);
              },
              child: Row(
                children: [
                  if (entry.key == currentTimeout)
                    Icon(Icons.check_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 12),
                  Text(entry.value),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showPinSetupFlow() {
    _showPinEntry(
      title: 'Create a PIN',
      subtitle: 'Enter a 4-6 digit PIN',
      onComplete: (pin) {
        // Confirm step
        _showPinEntry(
          title: 'Confirm PIN',
          subtitle: 'Re-enter your PIN',
          onComplete: (confirmPin) async {
            if (pin == confirmPin) {
              final hash = await AppLockService.hashPin(pin);
              final notifier = ref.read(settingsProvider.notifier);
              await notifier.setAppLockPinHash(hash);
              await notifier.setAppLockEnabled(true);
              if (_hasBiometrics && mounted) {
                _promptBiometric();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('App Lock enabled')),
                );
              }
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PINs did not match. Try again.')),
              );
            }
          },
        );
      },
    );
  }

  void _showChangePinFlow() {
    final currentHash = ref.read(settingsProvider).appLockPinHash;
    if (currentHash == null) return;

    _showPinEntry(
      title: 'Current PIN',
      subtitle: 'Enter your current PIN',
      onComplete: (currentPin) async {
        final isValid = await AppLockService.verifyPin(currentPin, currentHash);
        if (!isValid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incorrect PIN')),
            );
          }
          return;
        }
        if (!mounted) return;
        _showPinEntry(
          title: 'New PIN',
          subtitle: 'Enter a new 4-6 digit PIN',
          onComplete: (newPin) {
            _showPinEntry(
              title: 'Confirm New PIN',
              subtitle: 'Re-enter your new PIN',
              onComplete: (confirmPin) async {
                if (newPin == confirmPin) {
                  final hash = await AppLockService.hashPin(newPin);
                  await ref.read(settingsProvider.notifier)
                      .setAppLockPinHash(hash);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN changed')),
                    );
                  }
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('PINs did not match. Try again.')),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  void _confirmDisableAppLock() {
    final currentHash = ref.read(settingsProvider).appLockPinHash;
    if (currentHash == null) {
      ref.read(settingsProvider.notifier).setAppLockEnabled(false);
      return;
    }

    _showPinEntry(
      title: 'Disable App Lock',
      subtitle: 'Enter your PIN to confirm',
      onComplete: (pin) async {
        final isValid = await AppLockService.verifyPin(pin, currentHash);
        if (isValid) {
          final notifier = ref.read(settingsProvider.notifier);
          await notifier.setAppLockEnabled(false);
          await notifier.setAppLockPinHash(null);
          await notifier.setBiometricEnabled(false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('App Lock disabled')),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect PIN')),
          );
        }
      },
    );
  }

  void _promptBiometric() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable Biometric?'),
        content: const Text(
            'Use fingerprint or Face ID to unlock VoiceNotes AI?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App Lock enabled (PIN only)')),
              );
            },
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final didAuth = await _localAuth.authenticate(
                  localizedReason: 'Verify biometric to enable',
                  options:
                      const AuthenticationOptions(biometricOnly: true),
                );
                if (didAuth) {
                  ref.read(settingsProvider.notifier)
                      .setBiometricEnabled(true);
                }
              } catch (_) {}
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('App Lock enabled')),
                );
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  /// Show a PIN entry dialog. Calls onComplete with the entered PIN.
  void _showPinEntry({
    required String title,
    required String subtitle,
    required void Function(String pin) onComplete,
  }) {
    String pin = '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(subtitle,
                  style: Theme.of(ctx).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(ctx).hintColor)),
              const SizedBox(height: 16),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? Theme.of(ctx).colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: filled
                            ? Theme.of(ctx).colorScheme.primary
                            : Theme.of(ctx).hintColor,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Simple keypad
              ..._buildDialogKeypad(ctx, pin, (newPin) {
                setDialogState(() => pin = newPin);
              }),
              const SizedBox(height: 8),
              Text(
                'If you forget your PIN, you\'ll need to reinstall the app.',
                style: Theme.of(ctx).textTheme.labelSmall
                    ?.copyWith(color: Theme.of(ctx).hintColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: pin.length >= 4
                  ? () {
                      Navigator.pop(ctx);
                      onComplete(pin);
                    }
                  : null,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDialogKeypad(
    BuildContext ctx,
    String currentPin,
    void Function(String) onUpdate,
  ) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return rows.map((row) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: row.map((key) {
          if (key.isEmpty) return const SizedBox(width: 56, height: 48);
          final isBack = key == '⌫';
          return SizedBox(
            width: 56,
            height: 48,
            child: TextButton(
              onPressed: () {
                if (isBack) {
                  if (currentPin.isNotEmpty) {
                    onUpdate(
                        currentPin.substring(0, currentPin.length - 1));
                  }
                } else if (currentPin.length < 6) {
                  onUpdate(currentPin + key);
                }
              },
              style: TextButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: isBack
                  ? Icon(Icons.backspace_outlined,
                      size: 18,
                      color: Theme.of(ctx).colorScheme.onSurface)
                  : Text(key,
                      style: Theme.of(ctx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
            ),
          );
        }).toList(),
      );
    }).toList();
  }
}
