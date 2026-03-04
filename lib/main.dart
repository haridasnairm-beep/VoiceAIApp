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
import 'services/settings_repository.dart';
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
  runApp(const ProviderScope(child: VoiceNotesApp()));
}

class VoiceNotesApp extends ConsumerStatefulWidget {
  const VoiceNotesApp({super.key});

  @override
  ConsumerState<VoiceNotesApp> createState() => _VoiceNotesAppState();
}

class _VoiceNotesAppState extends ConsumerState<VoiceNotesApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWidgetLaunch();
      _checkFileIntent();
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
      // If locked (biometric dialog open), skip to avoid re-lock loop.
      if (!AppLockService.instance.isLocked) {
        AppLockService.instance.onAppPaused();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!AppLockService.instance.isLocked) {
        final shouldLock = AppLockService.instance
            .shouldLockOnResume(settings.autoLockTimeoutSeconds);
        if (shouldLock) {
          AppLockService.instance.lock();
          // Navigate to splash which handles the lock screen
          AppRouter.router.go(AppRoutes.splash);
        }
      }
      _refreshWidget();
    }
  }

  /// Handle URI from a widget tap that launched the app cold.
  Future<void> _checkWidgetLaunch() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    _onWidgetClicked(uri);
  }

  /// Route a deep-link URI (widget tap or app shortcut) to the appropriate screen.
  void _onWidgetClicked(Uri? uri) {
    if (uri == null) return;
    final uriStr = uri.toString();
    if (uriStr == 'voicenotesai://record') {
      AppRouter.router.go(AppRoutes.recording);
    } else if (uriStr == 'voicenotesai://search') {
      AppRouter.router.go(AppRoutes.search);
    }
  }

  /// Check if the app was launched by opening a .vnbak file.
  Future<void> _checkFileIntent() async {
    const channel = MethodChannel('com.hariappbuilders.voicenotesai/file_intent');
    try {
      final String? filePath = await channel.invokeMethod('getOpenFilePath');
      if (filePath != null && filePath.isNotEmpty) {
        // Navigate to backup restore page with the file path
        AppRouter.router.go(AppRoutes.backupRestore, extra: {'restoreFilePath': filePath});
      }
    } catch (_) {
      // Channel not available or no file — ignore
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
      title: 'VoiceNotes AI',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: settings.isAmoled ? amoledTheme : darkTheme,
      themeMode: settings.themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
