import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:local_auth/local_auth.dart';
import 'services/app_lock_service.dart';
import 'services/home_widget_service.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'services/folders_repository.dart';
import 'services/notes_repository.dart';
import 'services/project_documents_repository.dart';
import 'services/sharing_service.dart';
import 'widgets/share_receive_sheet.dart';
import 'services/crash_reporting_service.dart';
import 'services/settings_repository.dart';
import 'services/backup_service.dart';
import 'theme.dart';
import 'nav.dart';
import 'providers/settings_provider.dart';
import 'providers/notes_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge display — transparent system navigation bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  await HiveService.initialize();
  await HiveService.migrateTranscriptVersions();
  await HiveService.migrateDefaultTranscriptionMode();
  await HiveService.ensureDefaultFolder();
  await HiveService.migrateProjectsIntoFolders();
  await HiveService.migrateNotePrefixes();
  await HiveService.validateIntegrity();
  await NotificationService.instance.initialize();
  await HomeWidgetService.initialize();
  SharingService.cleanupTempExports(); // fire-and-forget
  // Initialize crash reporting if user opted in
  final settings = HiveService.settingsBox.get('user_settings');
  if (settings?.crashReportingEnabled == true) {
    await CrashReportingService.instance.initialize();
    CrashReportingService.setupFlutterErrorHandler();
  }
  // Increment session count for Gesture FAB hint logic
  SettingsRepository().incrementSessionCount();
  // Auto-purge trash items older than 30 days
  NotesRepository().purgeExpiredTrash();
  FoldersRepository().purgeExpiredTrash();
  ProjectDocumentsRepository().purgeExpiredTrash();
  // Auto-backup if enabled and due
  _runAutoBackupIfDue(settings);
  // Pre-check for widget launch URI so splash can skip animation
  await _preCheckWidgetLaunch();
  runApp(const ProviderScope(child: VaanixApp()));
}

/// Check for widget launch URI before splash page builds,
/// so splash can skip its animation when a deep link is pending.
Future<void> _preCheckWidgetLaunch() async {
  try {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri == null) return;
    final uriStr = uri.toString();
    if (uriStr == 'vaanix://record') {
      VaanixApp.pendingDeepLink = AppRoutes.recording;
    } else if (uriStr == 'vaanix://search') {
      VaanixApp.pendingDeepLink = AppRoutes.search;
    } else if (uriStr == 'vaanix://home-notes') {
      VaanixApp.pendingDeepLink = AppRoutes.home;
      VaanixApp.pendingHomeTab = 0;
    } else if (uriStr == 'vaanix://home-tasks') {
      VaanixApp.pendingDeepLink = AppRoutes.home;
      VaanixApp.pendingHomeTab = 1;
    }
  } catch (_) {
    // Widget launch check is non-critical
  }
}

/// Fire-and-forget auto-backup check on app launch.
void _runAutoBackupIfDue(dynamic settings) {
  if (settings == null) return;
  if (!settings.autoBackupEnabled) return;
  if (!BackupService.isAutoBackupDue(
    frequency: settings.autoBackupFrequency,
    lastRun: settings.autoBackupLastRun,
  )) return;

  // Run in background — don't block startup
  Future(() async {
    final success = await BackupService.runAutoBackup(
      maxCount: settings.autoBackupMaxCount,
    );
    if (success) {
      await SettingsRepository().setAutoBackupLastRun(DateTime.now());
      // Also update lastBackupDate so the reminder banner stays hidden
      await SettingsRepository().setLastBackupDate(DateTime.now());
    }
  });
}

class VaanixApp extends ConsumerStatefulWidget {
  const VaanixApp({super.key});

  /// Pending deep-link from widget tap (consumed by SplashPage._navigateForward).
  static String? pendingDeepLink;

  /// Pending home tab index from widget tap (0 = Notes, 1 = Tasks).
  static int? pendingHomeTab;

  @override
  ConsumerState<VaanixApp> createState() => _VaanixAppState();
}

class _VaanixAppState extends ConsumerState<VaanixApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWidgetLaunch();
      _checkFileIntent();
      _checkShareIntent();
      _refreshWidget();
      // Recover any transcriptions that were interrupted by app kill
      ref.read(notesProvider.notifier).recoverStuckTranscriptions();
    });
    // Listen for widget taps while app is running
    HomeWidget.widgetClicked.listen(_onWidgetClicked);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = ref.read(settingsProvider);
    if (!settings.appLockEnabled) return;

    if (state == AppLifecycleState.paused) {
      // Only record background time if app is unlocked.
      // If locked (biometric dialog open) or in widget recording session, skip.
      if (!AppLockService.instance.isLocked &&
          !AppLockService.instance.isInWidgetRecordingSession) {
        AppLockService.instance.onAppPaused();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Don't lock during widget recording session (user is recording without auth)
      if (!AppLockService.instance.isLocked &&
          !AppLockService.instance.isInWidgetRecordingSession) {
        final shouldLock = AppLockService.instance
            .shouldLockOnResume(settings.autoLockTimeoutSeconds);
        if (shouldLock) {
          AppLockService.instance.lock();
          // Navigate to splash which handles the lock screen
          AppRouter.router.go(AppRoutes.splash);
        }
      }
      _refreshWidget();
      // Check for warm-start share intent (app was already running)
      _checkShareIntent();
    }
  }

  /// Handle URI from a widget tap that launched the app cold.
  /// On cold start, _preCheckWidgetLaunch already consumed the URI,
  /// so this is a no-op (pendingDeepLink already set). Kept for safety.
  Future<void> _checkWidgetLaunch() async {
    // Skip if _preCheckWidgetLaunch already handled the cold-start URI
    if (VaanixApp.pendingDeepLink != null) return;
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    _onWidgetClicked(uri);
  }

  /// Route a deep-link URI (widget tap or app shortcut) to the appropriate screen.
  void _onWidgetClicked(Uri? uri) {
    if (uri == null) return;
    final uriStr = uri.toString();
    String? route;
    if (uriStr == 'vaanix://record') {
      route = AppRoutes.recording;
    } else if (uriStr == 'vaanix://search') {
      route = AppRoutes.search;
    } else if (uriStr == 'vaanix://home-notes') {
      route = AppRoutes.home;
      VaanixApp.pendingHomeTab = 0;
    } else if (uriStr == 'vaanix://home-tasks') {
      route = AppRoutes.home;
      VaanixApp.pendingHomeTab = 1;
    }
    if (route == null) return;

    // Store for splash page to consume on cold start
    VaanixApp.pendingDeepLink = route;

    // Widget recording bypass: if app lock is enabled and locked, and user
    // tapped record widget, start a widget recording session so the lock check
    // in didChangeAppLifecycleState doesn't override navigation to splash.
    final settings = ref.read(settingsProvider);
    if (route == AppRoutes.recording &&
        settings.appLockEnabled &&
        AppLockService.instance.isLocked) {
      AppLockService.instance.startWidgetRecordingSession();
      // Dismiss any active biometric dialog from the lock screen —
      // it persists as a system overlay even after go_router replaces the page.
      LocalAuthentication().stopAuthentication();
    }

    // If app lock is enabled and locked, and this is NOT a recording bypass,
    // route through splash → lock screen so user must authenticate first.
    final targetRoute = (settings.appLockEnabled &&
            AppLockService.instance.isLocked &&
            route != AppRoutes.recording)
        ? AppRoutes.splash
        : route;

    // Schedule navigation after current frame to avoid issues when
    // called during lifecycle transitions (inactive state).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppRouter.router.go(targetRoute);
    });
  }

  /// Check if the app was launched by opening a .vnbak file.
  Future<void> _checkFileIntent() async {
    const channel = MethodChannel('com.vaanix.app/file_intent');
    try {
      final String? filePath = await channel.invokeMethod('getOpenFilePath');
      if (filePath != null && filePath.isNotEmpty) {
        // Validate the file before navigating
        if (!filePath.toLowerCase().endsWith('.vnbak')) {
          _showFileError('Only .vnbak backup files are supported.');
          return;
        }
        final file = File(filePath);
        if (!await file.exists()) {
          _showFileError('The file could not be found.');
          return;
        }
        final fileSize = await file.length();
        if (fileSize > 500 * 1024 * 1024) {
          _showFileError('Backup file is too large (max 500 MB).');
          return;
        }
        // Navigate to backup restore page with the file path
        AppRouter.router.go(AppRoutes.backupRestore, extra: {'restoreFilePath': filePath});
      }
    } catch (_) {
      // Channel not available or no file — ignore
    }
  }

  void _showFileError(String message) {
    final ctx = AppRouter.router.routerDelegate.navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  /// Check if the app was launched by sharing an audio file.
  Future<void> _checkShareIntent() async {
    const channel = MethodChannel('com.vaanix.app/file_intent');
    try {
      final result = await channel.invokeMethod('getSharedAudioInfo');
      if (result != null && result is Map) {
        final path = result['path'] as String?;
        final filename = result['filename'] as String?;
        if (path != null && path.isNotEmpty) {
          // Small delay to ensure navigation is ready
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;
          final ctx = AppRouter.router.routerDelegate.navigatorKey.currentContext;
          if (ctx != null) {
            showModalBottomSheet(
              context: ctx,
              isScrollControlled: true,
              isDismissible: false,
              enableDrag: false,
              builder: (_) => ShareReceiveSheet(
                audioPath: path,
                originalFilename: filename,
              ),
            );
          }
        }
      }
    } catch (_) {
      // Channel not available or no shared audio — ignore
    }
  }

  /// Push fresh data to the home screen widget (fire-and-forget).
  void _refreshWidget() {
    final settings = ref.read(settingsProvider);
    HomeWidgetService.updateWidgetData(
      appLockEnabled: settings.appLockEnabled,
      widgetPrivacyLevel: settings.widgetPrivacyLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    // Deep-link to note when user taps a reminder notification
    NotificationService.onNotificationTapped = (noteId) {
      if (noteId != null && noteId.isNotEmpty) {
        AppRouter.router.go(AppRoutes.noteDetail, extra: {'noteId': noteId});
      }
    };

    // Update nav bar icon brightness based on theme
    final brightness = settings.themeMode == ThemeMode.dark ||
            (settings.themeMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark)
        ? Brightness.light
        : Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: brightness,
    ));

    return MaterialApp.router(
      title: 'Vaanix',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: settings.isAmoled ? amoledTheme : darkTheme,
      themeMode: settings.themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
