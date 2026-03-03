import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'services/app_lock_service.dart';
import 'services/home_widget_service.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'services/folders_repository.dart';
import 'services/notes_repository.dart';
import 'services/project_documents_repository.dart';
import 'services/sharing_service.dart';
import 'services/crash_reporting_service.dart';
import 'pages/lock_screen_page.dart';
import 'theme.dart';
import 'nav.dart';
import 'providers/settings_provider.dart';

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
  // Auto-purge trash items older than 30 days
  NotesRepository().purgeExpiredTrash();
  FoldersRepository().purgeExpiredTrash();
  ProjectDocumentsRepository().purgeExpiredTrash();
  runApp(const ProviderScope(child: VoiceNotesApp()));
}

class VoiceNotesApp extends ConsumerStatefulWidget {
  const VoiceNotesApp({super.key});

  @override
  ConsumerState<VoiceNotesApp> createState() => _VoiceNotesAppState();
}

class _VoiceNotesAppState extends ConsumerState<VoiceNotesApp>
    with WidgetsBindingObserver {
  bool _lockScreenShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Show lock on cold start after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkColdStartLock();
      _checkWidgetLaunch();
      _refreshWidget();
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
      AppLockService.instance.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      final shouldLock = AppLockService.instance
          .shouldLockOnResume(settings.autoLockTimeoutSeconds);
      if (shouldLock) {
        AppLockService.instance.lock();
        _showLockScreen();
      }
      // Keep widget data fresh whenever the app comes back to foreground
      _refreshWidget();
    }
  }

  void _checkColdStartLock() {
    final settings = ref.read(settingsProvider);
    if (settings.appLockEnabled &&
        settings.appLockPinHash != null &&
        AppLockService.instance.isLocked) {
      _showLockScreen();
    }
  }

  /// Handle URI from a widget tap that launched the app cold.
  Future<void> _checkWidgetLaunch() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    _onWidgetClicked(uri);
  }

  /// Route a widget-click URI to the appropriate screen.
  void _onWidgetClicked(Uri? uri) {
    if (uri == null) return;
    if (uri.toString() == 'voicenotesai://record') {
      // Navigate straight to Recording — App Lock will gate reading notes
      // once the user returns to the main app.
      AppRouter.router.go(AppRoutes.recording);
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

  void _showLockScreen() {
    if (_lockScreenShown) return;
    final settings = ref.read(settingsProvider);
    if (settings.appLockPinHash == null) return;

    _lockScreenShown = true;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => LockScreenPage(
          pinHash: settings.appLockPinHash!,
          biometricEnabled: settings.biometricEnabled,
          onUnlocked: () {
            Navigator.of(context).pop();
            _lockScreenShown = false;
          },
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
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
      title: 'VoiceNotes AI',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: settings.isAmoled ? amoledTheme : darkTheme,
      themeMode: settings.themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
