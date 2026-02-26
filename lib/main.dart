import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
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
  await NotificationService.instance.initialize();
  runApp(const ProviderScope(child: VoiceNotesApp()));
}

class VoiceNotesApp extends ConsumerWidget {
  const VoiceNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // Deep-link to note when user taps a reminder notification
    NotificationService.onNotificationTapped = (noteId) {
      if (noteId != null && noteId.isNotEmpty) {
        AppRouter.router.go(AppRoutes.noteDetail, extra: {'noteId': noteId});
      }
    };

    return MaterialApp.router(
      title: 'VoiceNotes AI',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: settings.themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
