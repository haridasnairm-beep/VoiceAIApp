import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    initialLocation: AppRoutes.onboarding,
    routes: [
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
        pageBuilder: (context, state) => const NoTransitionPage(
          child: RecordingPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.noteDetail,
        name: 'note_detail',
        pageBuilder: (context, state) {
          final extra = state.extra;
          String? recordingPath;
          if (extra is Map) {
            final v = extra['recordingPath'];
            if (v is String && v.isNotEmpty) recordingPath = v;
          }
          return NoTransitionPage(
              child: NoteDetailPage(recordingPath: recordingPath));
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
        pageBuilder: (context, state) => const NoTransitionPage(
          child: FolderDetailPage(),
        ),
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
  static const String onboarding = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String recording = '/recording';
  static const String noteDetail = '/note_detail';
  static const String folders = '/folders';
  static const String folderDetail = '/folder_detail';
  static const String settings = '/settings';
  static const String search = '/search';
}
