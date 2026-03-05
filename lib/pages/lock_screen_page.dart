import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/app_lock_service.dart';

/// Full-screen lock overlay. Must authenticate to dismiss.
class LockScreenPage extends StatefulWidget {
  final String pinHash;
  final bool biometricEnabled;
  final VoidCallback onUnlocked;

  const LockScreenPage({
    super.key,
    required this.pinHash,
    required this.biometricEnabled,
    required this.onUnlocked,
  });

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage>
    with SingleTickerProviderStateMixin {
  final _localAuth = LocalAuthentication();
  String _enteredPin = '';
  bool _showPinPad = false;
  String? _errorText;
  bool _isAuthenticating = false;
  late AnimationController _shakeController;
  Timer? _lockoutTimer;
  Duration? _lockoutRemaining;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Auto-trigger biometric if enabled
    if (widget.biometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      print('LockScreen biometric: canCheck=$canCheck isSupported=$isSupported');
      if ((!canCheck && !isSupported) || !mounted) {
        print('LockScreen biometric: not available, skipping');
        setState(() => _isAuthenticating = false);
        return;
      }
      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Unlock Vaanix',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      print('LockScreen biometric: didAuth=$didAuth');
      if (didAuth && mounted) {
        AppLockService.instance.unlock();
        widget.onUnlocked();
      }
    } catch (e) {
      print('LockScreen biometric error: $e');
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void _onDigit(String digit) {
    if (_enteredPin.length >= 6) return;
    final lockout = AppLockService.instance.lockoutRemaining;
    if (lockout != null) return;

    setState(() {
      _enteredPin += digit;
      _errorText = null;
    });

    // Auto-verify at 4-6 digits
    if (_enteredPin.length >= 4) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorText = null;
    });
  }

  Future<void> _verifyPin() async {
    final isValid =
        await AppLockService.verifyPin(_enteredPin, widget.pinHash);
    if (!mounted) return;

    if (isValid) {
      AppLockService.instance.unlock();
      widget.onUnlocked();
    } else {
      final lockoutDuration =
          AppLockService.instance.recordFailedAttempt();
      _shakeController.forward(from: 0);
      setState(() {
        _enteredPin = '';
        if (lockoutDuration != null) {
          _errorText =
              'Too many attempts. Try again in ${lockoutDuration.inSeconds}s';
          _startLockoutTimer(lockoutDuration);
        } else {
          _errorText = 'Incorrect PIN';
        }
      });
    }
  }

  void _startLockoutTimer(Duration duration) {
    _lockoutRemaining = duration;
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = AppLockService.instance.lockoutRemaining;
      if (remaining == null || !mounted) {
        timer.cancel();
        setState(() {
          _lockoutRemaining = null;
          _errorText = null;
        });
      } else {
        setState(() {
          _lockoutRemaining = remaining;
          _errorText = 'Try again in ${remaining.inSeconds}s';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/icons/logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
              Text('Vaanix',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _showPinPad ? 'Enter your PIN' : 'Locked',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor),
              ),
              const Spacer(),

              if (!_showPinPad) ...[
                // Biometric + Use PIN buttons
                if (widget.biometricEnabled)
                  FilledButton.icon(
                    onPressed: _isAuthenticating ? null : _tryBiometric,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: Text(_isAuthenticating
                        ? 'Authenticating...'
                        : 'Unlock with Biometric'),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _showPinPad = true),
                  icon: const Icon(Icons.dialpad_rounded),
                  label: const Text('Use PIN'),
                ),
              ] else ...[
                // PIN dots
                _buildShakeWidget(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) {
                      final filled = i < _enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? primary : Colors.transparent,
                          border: Border.all(
                            color: filled ? primary : theme.hintColor,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorText!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 24),
                // PIN keypad
                _buildKeypad(theme),
                const SizedBox(height: 12),
                if (widget.biometricEnabled)
                  TextButton.icon(
                    onPressed: _tryBiometric,
                    icon: const Icon(Icons.fingerprint_rounded, size: 18),
                    label: const Text('Use Biometric'),
                  ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShakeWidget({required Widget child}) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, _) {
        final dx = _shakeController.value > 0
            ? 10 * (1 - _shakeController.value) *
                (((_shakeController.value * 8).round() % 2 == 0) ? 1 : -1)
            : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    final isLockedOut = _lockoutRemaining != null;
    final digits = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: digits.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) {
              return const SizedBox(width: 80, height: 64);
            }
            final isBackspace = key == '⌫';
            return SizedBox(
              width: 80,
              height: 64,
              child: TextButton(
                onPressed: isLockedOut
                    ? null
                    : isBackspace
                        ? _onBackspace
                        : () => _onDigit(key),
                style: TextButton.styleFrom(
                  shape: const CircleBorder(),
                ),
                child: isBackspace
                    ? Icon(Icons.backspace_outlined,
                        size: 22, color: theme.colorScheme.onSurface)
                    : Text(key,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        )),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
