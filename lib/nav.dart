import 'package:go_router/go_router.dart';
import 'pages/splash_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/recording_page.dart';
import 'pages/note_detail_page.dart';
import 'pages/folders_page.dart';
import 'pages/folder_detail_page.dart';
import 'pages/settings_page.dart';
import 'pages/search_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: OnboardingPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: HomePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.recording,
        name: 'recording',
        pageBuilder: (context, state) {
          final extra = state.extra;
          String? folderId;
          if (extra is Map) {
            final f = extra['folderId'];
            if (f is String && f.isNotEmpty) folderId = f;
          }
          return NoTransitionPage(
            child: RecordingPage(folderId: folderId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.noteDetail,
        name: 'note_detail',
        pageBuilder: (context, state) {
          final extra = state.extra;
          String? recordingPath;
          String? noteId;
          String? transcription;
          int? duration;
          String? detectedLanguage;
          if (extra is Map) {
            final v = extra['recordingPath'];
            if (v is String && v.isNotEmpty) recordingPath = v;
            final n = extra['noteId'];
            if (n is String && n.isNotEmpty) noteId = n;
            final t = extra['transcription'];
            if (t is String) transcription = t;
            final d = extra['duration'];
            if (d is int) duration = d;
            final l = extra['detectedLanguage'];
            if (l is String && l.isNotEmpty) detectedLanguage = l;
          }
          String? folderId;
          if (extra is Map) {
            final f = extra['folderId'];
            if (f is String && f.isNotEmpty) folderId = f;
          }
          return NoTransitionPage(
              child: NoteDetailPage(
            recordingPath: recordingPath,
            noteId: noteId,
            transcription: transcription,
            duration: duration,
            detectedLanguage: detectedLanguage,
            folderId: folderId,
          ));
        },
      ),
      GoRoute(
        path: AppRoutes.folders,
        name: 'folders',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: FoldersPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.folderDetail,
        name: 'folder_detail',
        pageBuilder: (context, state) {
          final extra = state.extra;
          String? folderId;
          if (extra is Map) {
            final f = extra['folderId'];
            if (f is String && f.isNotEmpty) folderId = f;
          }
          return NoTransitionPage(
              child: FolderDetailPage(folderId: folderId));
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SettingsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SearchPage(),
        ),
      ),
    ],
  );
}

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String recording = '/recording';
  static const String noteDetail = '/note_detail';
  static const String folders = '/folders';
  static const String folderDetail = '/folder_detail';
  static const String settings = '/settings';
  static const String search = '/search';
}
