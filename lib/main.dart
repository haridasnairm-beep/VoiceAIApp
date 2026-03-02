import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/app_lock_service.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'services/folders_repository.dart';
import 'services/notes_repository.dart';
import 'services/project_documents_repository.dart';
import 'services/sharing_service.dart';
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
  await NotificationService.instance.initialize();
  SharingService.cleanupTempExports(); // fire-and-forget
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkColdStartLock());
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
