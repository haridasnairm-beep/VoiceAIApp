import 'package:go_router/go_router.dart';
import 'pages/splash_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/recording_page.dart';
import 'pages/note_detail_page.dart';
import 'pages/folders_page.dart';
import 'pages/folder_detail_page.dart';
import 'pages/preferences_page.dart';
import 'pages/audio_settings_page.dart';
import 'pages/storage_page.dart';
import 'pages/support_page.dart';
import 'pages/danger_zone_page.dart';
import 'pages/security_page.dart';
import 'pages/trash_page.dart';
import 'pages/search_page.dart';
import 'pages/project_documents_page.dart';
import 'pages/project_document_detail_page.dart';
import 'pages/note_picker_page.dart';
import 'pages/version_history_page.dart';
import 'pages/privacy_policy_page.dart';
import 'pages/terms_conditions_page.dart';
import 'pages/about_page.dart';
import 'pages/feedback_page.dart';
import 'pages/support_us_page.dart';
import 'pages/backup_restore_page.dart';
import 'pages/tags_page.dart';
import 'pages/calendar_page.dart';
import 'pages/permission_page.dart';
import 'pages/user_guide_page.dart';
import 'pages/retranscribe_page.dart';
import 'pages/force_update_page.dart';

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
          String? projectId;
          if (extra is Map) {
            final f = extra['folderId'];
            if (f is String && f.isNotEmpty) folderId = f;
            final p = extra['projectId'];
            if (p is String && p.isNotEmpty) projectId = p;
          }
          return NoTransitionPage(
            child: RecordingPage(folderId: folderId, projectId: projectId),
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
          bool isNewTextNote = false;
          String? templateContent;
          String? templateTitle;
          String? projectId;
          if (extra is Map) {
            final txt = extra['isNewTextNote'];
            if (txt == true) isNewTextNote = true;
            final tc = extra['templateContent'];
            if (tc is String) templateContent = tc;
            final tt = extra['templateTitle'];
            if (tt is String) templateTitle = tt;
            final p = extra['projectId'];
            if (p is String && p.isNotEmpty) projectId = p;
          }
          return NoTransitionPage(
              child: NoteDetailPage(
            recordingPath: recordingPath,
            noteId: noteId,
            transcription: transcription,
            duration: duration,
            detectedLanguage: detectedLanguage,
            folderId: folderId,
            isNewTextNote: isNewTextNote,
            templateContent: templateContent,
            templateTitle: templateTitle,
            projectId: projectId,
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
        path: AppRoutes.preferences,
        name: 'preferences',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PreferencesPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.audioSettings,
        name: 'audio_settings',
        pageBuilder: (context, state) {
          final extra = state.extra;
          bool highlightWhisper = false;
          if (extra is Map) {
            final h = extra['highlightWhisper'];
            if (h == true) highlightWhisper = true;
          }
          return NoTransitionPage(
            child: AudioSettingsPage(highlightWhisper: highlightWhisper),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.storage,
        name: 'storage',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: StoragePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.support,
        name: 'support',
        pageBuilder: (context, state) {
          final extra = state.extra;
          bool highlightHomeTips = false;
          if (extra is Map) {
            highlightHomeTips = extra['highlightHomeTips'] == true;
          }
          return NoTransitionPage(
            child: SupportPage(highlightHomeTips: highlightHomeTips),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.security,
        name: 'security',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SecurityPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.trash,
        name: 'trash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: TrashPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.dangerZone,
        name: 'danger_zone',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: DangerZonePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        pageBuilder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return NoTransitionPage(
            child: SearchPage(
              initialFolderId: extras?['folderId'] as String?,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.projectDocuments,
        name: 'project_documents',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ProjectDocumentsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.projectDocumentDetail,
        name: 'project_document_detail',
        pageBuilder: (context, state) {
          final extra = state.extra;
          String? documentId;
          if (extra is Map) {
            final d = extra['documentId'];
            if (d is String && d.isNotEmpty) documentId = d;
          }
          return NoTransitionPage(
            child: ProjectDocumentDetailPage(documentId: documentId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notePickerRoute,
        name: 'note_picker',
        pageBuilder: (context, state) {
          final extra = state.extra;
          String? documentId;
          String? filterType;
          if (extra is Map) {
            final d = extra['documentId'];
            if (d is String && d.isNotEmpty) documentId = d;
            final ft = extra['filterType'];
            if (ft is String && ft.isNotEmpty) filterType = ft;
          }
          return NoTransitionPage(
            child: NotePickerPage(documentId: documentId, filterType: filterType),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.versionHistory,
        name: 'version_history',
        pageBuilder: (context, state) {
          final extra = state.extra;
          String? noteId;
          if (extra is Map) {
            final n = extra['noteId'];
            if (n is String && n.isNotEmpty) noteId = n;
          }
          return NoTransitionPage(
            child: VersionHistoryPage(noteId: noteId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        name: 'privacy_policy',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PrivacyPolicyPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.termsConditions,
        name: 'terms_conditions',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: TermsConditionsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AboutPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.feedback,
        name: 'feedback',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: FeedbackPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.supportUs,
        name: 'support_us',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SupportUsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.backupRestore,
        name: 'backup_restore',
        pageBuilder: (context, state) {
          String? restoreFilePath;
          final extra = state.extra;
          if (extra is Map) {
            final p = extra['restoreFilePath'];
            if (p is String && p.isNotEmpty) restoreFilePath = p;
          }
          return NoTransitionPage(
            child: BackupRestorePage(restoreFilePath: restoreFilePath),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.tags,
        name: 'tags',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: TagsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.calendar,
        name: 'calendar',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: CalendarPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.permissions,
        name: 'permissions',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PermissionPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.userGuide,
        name: 'user_guide',
        pageBuilder: (context, state) {
          final extra = state.extra;
          int? openSectionIndex;
          if (extra is Map) {
            final s = extra['openSectionIndex'];
            if (s is int) openSectionIndex = s;
          }
          return NoTransitionPage(
            child: UserGuidePage(openSectionIndex: openSectionIndex),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.retranscribe,
        name: 'retranscribe',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: RetranscribePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.forceUpdate,
        name: 'force_update',
        pageBuilder: (context, state) {
          final extra = state.extra;
          String version = '';
          String? releaseNotes;
          String downloadUrl = '';
          if (extra is Map) {
            version = extra['version'] as String? ?? '';
            releaseNotes = extra['releaseNotes'] as String?;
            downloadUrl = extra['downloadUrl'] as String? ?? '';
          }
          return NoTransitionPage(
            child: ForceUpdatePage(
              version: version,
              releaseNotes: releaseNotes,
              downloadUrl: downloadUrl,
            ),
          );
        },
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
  static const String preferences = '/preferences';
  static const String audioSettings = '/audio_settings';
  static const String storage = '/storage';
  static const String support = '/support';
  static const String security = '/security';
  static const String trash = '/trash';
  static const String dangerZone = '/danger_zone';
  static const String search = '/search';
  static const String projectDocuments = '/project_documents';
  static const String projectDocumentDetail = '/project_document_detail';
  static const String notePickerRoute = '/note_picker';
  static const String versionHistory = '/version_history';
  static const String privacyPolicy = '/privacy_policy';
  static const String termsConditions = '/terms_conditions';
  static const String about = '/about';
  static const String feedback = '/feedback';
  static const String supportUs = '/support_us';
  static const String backupRestore = '/backup_restore';
  static const String tags = '/tags';
  static const String calendar = '/calendar';
  static const String permissions = '/permissions';
  static const String userGuide = '/user_guide';
  static const String retranscribe = '/retranscribe';
  static const String forceUpdate = '/force_update';
}
