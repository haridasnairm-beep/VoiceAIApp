import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../main.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/settings_provider.dart';
import '../services/app_lock_service.dart';
import '../services/update_check_service.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  /// Cached optional update result for home page to display.
  static UpdateCheckResult? pendingOptionalUpdate;

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _logoScale;

  // Lock screen state
  bool _isLocked = false;
  final _localAuth = LocalAuthentication();
  String _enteredPin = '';
  bool _showPinPad = false;
  String? _errorText;
  bool _isAuthenticating = false;
  bool _biometricAvailable = false;
  Timer? _lockoutTimer;
  Duration? _lockoutRemaining;
  bool _unlockSuccess = false;
  Future<UpdateCheckResult?>? _updateCheckFuture;

  String? _pinHash;
  bool _biometricEnabled = false;
  int _pinLength = 4;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    final settings = ref.read(settingsProvider);
    _pinHash = AppLockService.getStoredPinHash();
    _biometricEnabled = settings.biometricEnabled;
    _pinLength = settings.pinLength;

    // Start update check in parallel with splash animation
    _updateCheckFuture = _runUpdateCheck(settings);

    if (settings.appLockEnabled &&
        _pinHash != null &&
        AppLockService.instance.isLocked) {
      // Widget recording bypass: allow recording without auth
      if (VaanixApp.pendingDeepLink == AppRoutes.recording) {
        AppLockService.instance.startWidgetRecordingSession();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final route = VaanixApp.pendingDeepLink!;
            VaanixApp.pendingDeepLink = null;
            context.go(route);
          }
        });
      } else {
        // Restore persisted lockout state
        AppLockService.instance.initFromSettings(
          settings.failedPinAttempts,
          settings.pinLockoutUntil,
        );
        // App lock is on — show lock UI instead of auto-navigating
        _isLocked = true;
        // Resume lockout timer if still active
        final remaining = AppLockService.instance.lockoutRemaining;
        if (remaining != null) {
          _showPinPad = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startLockoutTimer(remaining);
          });
        }
        _checkBiometricAvailability();
      }
    } else if (VaanixApp.pendingDeepLink != null) {
      // Widget deep-link — skip splash animation, navigate immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _navigateForward();
      });
    } else {
      // No lock, no deep-link — show splash for 2 seconds
      Timer(const Duration(seconds: 2), () {
        if (mounted) _navigateForward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<UpdateCheckResult?> _runUpdateCheck(SettingsState settings) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final result = await UpdateCheckService.checkForUpdate(
        currentVersion: packageInfo.version,
        lastCheckDate: settings.lastUpdateCheckDate,
        dismissedVersion: settings.dismissedUpdateVersion,
      );
      // Persist check timestamp
      if (result != null || settings.lastUpdateCheckDate == null ||
          DateTime.now().difference(settings.lastUpdateCheckDate!).inHours >= 24) {
        ref.read(settingsProvider.notifier).setLastUpdateCheckDate(DateTime.now());
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> _navigateForward() async {
    // Check for pending widget deep-link (cold start from widget tap)
    final deepLink = VaanixApp.pendingDeepLink;
    if (deepLink != null) {
      VaanixApp.pendingDeepLink = null; // consume it
      context.go(deepLink);
      return;
    }

    // Check for force update
    final updateResult = await _updateCheckFuture;
    if (updateResult != null && updateResult.isForceUpdate && mounted) {
      context.go(AppRoutes.forceUpdate, extra: {
        'version': updateResult.latestVersion,
        'releaseNotes': updateResult.releaseNotes,
        'downloadUrl': updateResult.downloadUrl,
      });
      return;
    }

    // Cache optional update for home page
    if (updateResult != null && !updateResult.isForceUpdate) {
      SplashPage.pendingOptionalUpdate = updateResult;
    }

    if (!mounted) return;
    final settings = ref.read(settingsProvider);
    if (!settings.onboardingCompleted) {
      context.go(AppRoutes.onboarding);
    } else if (!settings.permissionScreenShown) {
      context.go(AppRoutes.permissions);
    } else {
      context.go(AppRoutes.home);
    }
  }

  // --- Biometric ---

  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      debugPrint('Splash biometric: canCheck=$canCheck isSupported=$isSupported');
      if (mounted) {
        setState(() => _biometricAvailable = canCheck || isSupported);
        if (_biometricEnabled && _biometricAvailable) {
          // Auto-trigger biometric on cold start
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _tryBiometric());
        }
      }
    } catch (e) {
      debugPrint('Splash biometric check failed: $e');
    }
  }

  Future<void> _tryBiometric() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    try {
      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Unlock Vaanix',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      debugPrint('Splash biometric: didAuth=$didAuth');
      if (didAuth && mounted) {
        AppLockService.instance.unlock();
        setState(() => _unlockSuccess = true);
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) _navigateForward();
      }
    } catch (e) {
      debugPrint('Splash biometric error: $e');
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  // --- PIN ---

  void _onDigit(String digit) {
    if (_enteredPin.length >= 6) return;
    final lockout = AppLockService.instance.lockoutRemaining;
    if (lockout != null) return;

    setState(() {
      _enteredPin += digit;
      _errorText = null;
    });

    if (_enteredPin.length == _pinLength) {
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
    if (_pinHash == null) return;
    final isValid = await AppLockService.verifyPin(_enteredPin, _pinHash!);
    if (!mounted) return;

    if (isValid) {
      AppLockService.instance.unlock();
      // Clear persisted lockout
      final notifier = ref.read(settingsProvider.notifier);
      notifier.setFailedPinAttempts(0);
      notifier.setPinLockoutUntil(null);
      setState(() => _unlockSuccess = true);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _navigateForward();
    } else {
      final lockoutDuration = AppLockService.instance.recordFailedAttempt();
      // Persist failed attempts + lockout deadline
      final notifier = ref.read(settingsProvider.notifier);
      notifier.setFailedPinAttempts(AppLockService.instance.failedAttempts);
      if (lockoutDuration != null) {
        notifier.setPinLockoutUntil(DateTime.now().add(lockoutDuration));
      }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      AppColors.darkBackground,
                      const Color(0xFF1A2332),
                      AppColors.darkBackground,
                    ]
                  : [
                      AppColors.lightBackground,
                      const Color(0xFFE8F0FE),
                      AppColors.lightBackground,
                    ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: _isLocked ? _buildLockUI(theme, primaryColor) : _buildSplashUI(theme, primaryColor),
            ),
          ),
        ),
      ),
    );
  }

  // --- Normal splash (no lock) ---
  Widget _buildSplashUI(ThemeData theme, Color primaryColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 3),
        _buildLogo(primaryColor, size: 140),
        const SizedBox(height: 32),
        Text(
          'Vaanix',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'Your voice, perfectly organized.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const Spacer(flex: 2),
        Text.rich(
          TextSpan(
            style: theme.textTheme.bodySmall?.copyWith(
              color: primaryColor.withValues(alpha: 0.7),
              fontSize: 11,
            ),
            children: [
              const TextSpan(text: 'By using this app you agree to the\n'),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.termsConditions),
                  child: Text(
                    'Terms & Conditions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: primaryColor.withValues(alpha: 0.9),
                      decoration: TextDecoration.underline,
                      decorationColor: primaryColor.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'by HDMPixels',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 72),
      ],
    );
  }

  // --- Lock screen UI ---
  Widget _buildLockUI(ThemeData theme, Color primaryColor) {
    final hasBiometric = _biometricEnabled && _biometricAvailable;
    // Show tip if biometric is available but not enabled by the user
    final showBiometricTip = _biometricAvailable && !_biometricEnabled;

    return Column(
      children: [
        // Logo positioned in upper third so biometric popup doesn't cover it
        const Spacer(flex: 1),
        _buildLogo(primaryColor, size: 120),
        const SizedBox(height: 24),
        Text(
          'Vaanix',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _showPinPad ? 'Enter your PIN' : 'Your voice, perfectly organized.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _showPinPad ? theme.hintColor : theme.colorScheme.secondary,
          ),
        ),
        const Spacer(),

        if (!_showPinPad) ...[
          // Biometric + Use PIN buttons
          if (hasBiometric)
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
          // Biometric tip for users who haven't enabled it
          if (showBiometricTip) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.fingerprint_rounded,
                        size: 20, color: primaryColor.withValues(alpha: 0.7)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tip: Enable biometric unlock in Settings > Security for faster access.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ] else ...[
          // PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final filled = i < _enteredPin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? primaryColor : Colors.transparent,
                  border: Border.all(
                    color: filled ? primaryColor : theme.hintColor,
                    width: 2,
                  ),
                ),
              );
            }),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(_errorText!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 24),
          _buildKeypad(theme),
          const SizedBox(height: 12),
          if (hasBiometric)
            TextButton.icon(
              onPressed: _tryBiometric,
              icon: const Icon(Icons.fingerprint_rounded, size: 18),
              label: const Text('Use Biometric'),
            ),
        ],
        const Spacer(),

        // Bottom section — same as splash
        Text.rich(
          TextSpan(
            style: theme.textTheme.bodySmall?.copyWith(
              color: primaryColor.withValues(alpha: 0.7),
              fontSize: 11,
            ),
            children: [
              const TextSpan(text: 'By using this app you agree to the\n'),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.termsConditions),
                  child: Text(
                    'Terms & Conditions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: primaryColor.withValues(alpha: 0.9),
                      decoration: TextDecoration.underline,
                      decorationColor: primaryColor.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'by HDMPixels',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLogo(Color primaryColor, {required double size}) {
    return ScaleTransition(
      scale: _logoScale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.28),
          child: Image.asset('assets/icons/logo.png', fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    final isLockedOut = _lockoutRemaining != null;
    final digits = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '\u232B'],
    ];

    return Column(
      children: digits.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) {
              return const SizedBox(width: 80, height: 64);
            }
            final isBackspace = key == '\u232B';
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
