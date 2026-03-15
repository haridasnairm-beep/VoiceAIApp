import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/settings_provider.dart';
import '../services/whisper_service.dart';
import '../utils/responsive.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// True when opened from Settings (voluntary), false on first-run.
  bool get _isFromSettings =>
      ref.read(settingsProvider).onboardingCompleted;

  void _finish() {
    if (!_isFromSettings) {
      ref.read(settingsProvider.notifier).setOnboardingCompleted(true);
      // Show permission request screen on first run
      context.go(AppRoutes.permissions);
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages(context);
    final isLastPage = _currentPage == pages.length - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _isFromSettings
          ? AppBar(
              title: const Text('Quick Guide'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (first-run only)
            if (!_isFromSettings)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 20),
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ),
                ),
              ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: pages,
              ),
            ),

            // Dot indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ResponsiveCenter(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLastPage) {
                      _finish();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    textStyle:
                        Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                  ),
                  child: Text(isLastPage
                      ? (_isFromSettings ? 'Got It' : 'Get Started')
                      : 'Next'),
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPages(BuildContext context) {
    return [
      // Page 1: Welcome
      _GuidePage(
        icon: null,
        useLogoAsset: true,
        title: 'Vaanix',
        subtitle: 'Your voice, perfectly organized.',
        description:
            'Transform your spoken ideas into perfectly organized notes. '
            'Record, transcribe, and find everything instantly.',
      ),

      // Page 2: Record & Transcribe
      _GuidePage(
        icon: Icons.mic_rounded,
        iconBg: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        title: 'Record & Transcribe',
        subtitle: 'Speak naturally, we handle the rest.',
        description:
            'Choose Live Transcription for real-time text as you speak, '
            'or Record & Transcribe mode to save audio and get text afterwards. '
            'Switch anytime in Settings.',
      ),

      // Page 3: Organize Your Way
      _GuidePage(
        icon: Icons.folder_special_rounded,
        iconBg: const Color(0xFFF3E5F5),
        iconColor: const Color(0xFF7B1FA2),
        title: 'Organize Your Way',
        subtitle: 'Folders, tags, and projects.',
        description:
            'Create folders and add tags to organize notes by topic. '
            'Build Project Documents that combine notes, text, images, and tasks '
            'into one canvas. Search across everything instantly.',
      ),

      // Page 4: Tasks & Reminders
      _GuidePage(
        icon: Icons.task_alt_rounded,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFE65100),
        title: 'Tasks & Reminders',
        subtitle: 'Turn voice into action.',
        description:
            'Add action items and to-dos directly inside your notes. '
            'Set reminders with date and time — see all tasks across notes '
            'in one place from the Tasks tab on your home screen.',
      ),

      // Page 5: Stay Secure
      _GuidePage(
        icon: Icons.lock_rounded,
        iconBg: const Color(0xFFE8EAF6),
        iconColor: const Color(0xFF283593),
        title: 'Stay Secure',
        subtitle: 'Lock, backup, and quick access.',
        description:
            'Protect notes with PIN or fingerprint lock. '
            'Create encrypted backups to keep your data safe. '
            'Add home screen widgets for quick recording and stats at a glance.',
      ),

      // Page 6: Prepare Your App
      _WhisperSetupPage(
        onSetupTap: () {
          // Navigate to settings with highlight
          context.push(AppRoutes.audioSettings, extra: {'highlightWhisper': true});
        },
      ),

      // Page 5: Privacy First
      _GuidePage(
        icon: Icons.shield_rounded,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1565C0),
        title: 'Privacy First',
        subtitle: 'Your data stays on your device.',
        description:
            'All notes and recordings are stored locally with AES-256 encryption. '
            'No cloud uploads, no accounts required, no tracking. '
            'Your thoughts remain yours.',
      ),
    ];
  }
}

class _GuidePage extends StatelessWidget {
  final IconData? icon;
  final Color? iconBg;
  final Color? iconColor;
  final bool useLogoAsset;
  final String title;
  final String subtitle;
  final String description;

  const _GuidePage({
    this.icon,
    this.iconBg,
    this.iconColor,
    this.useLogoAsset = false,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Icon or logo
          if (useLogoAsset)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                      blurRadius: 50,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.asset(
                    'assets/icons/logo.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          else if (icon != null)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: iconBg ?? const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor ?? Theme.of(context).colorScheme.primary,
                  size: 56,
                ),
              ),
            ),
          const SizedBox(height: 40),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 20),
          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  height: 1.6,
                ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

/// Onboarding page that explains whisper model setup and offers a button
/// to navigate to Settings for download.
class _WhisperSetupPage extends StatefulWidget {
  final VoidCallback onSetupTap;

  const _WhisperSetupPage({required this.onSetupTap});

  @override
  State<_WhisperSetupPage> createState() => _WhisperSetupPageState();
}

class _WhisperSetupPageState extends State<_WhisperSetupPage> {
  bool _isDownloaded = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkModel();
  }

  Future<void> _checkModel() async {
    final downloaded = await WhisperService.instance.isModelDownloaded();
    if (!mounted) return;
    setState(() {
      _isDownloaded = downloaded;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3E0),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.downloading_rounded,
                color: Color(0xFFE65100),
                size: 56,
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Title
          Text(
            'Prepare Your App',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            'One-time setup for best results.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 20),
          // Description
          Text(
            'Vaanix uses an on-device Whisper model for high-quality '
            'transcription. Download it once (~140 MB) and all transcription '
            'happens privately on your phone — no internet needed.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  height: 1.6,
                ),
          ),
          const SizedBox(height: 28),
          // Action button
          if (!_isChecking && !_isDownloaded)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onSetupTap,
                icon: const Icon(Icons.settings_rounded),
                label: const Text("Let's Set It Up"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                ),
              ),
            )
          else if (_isDownloaded)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32), size: 20),
                const SizedBox(width: 8),
                Text(
                  "You're all set!",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
