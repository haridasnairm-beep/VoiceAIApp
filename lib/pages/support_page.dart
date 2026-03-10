import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';

class SupportPage extends ConsumerStatefulWidget {
  final bool highlightHomeTips;

  const SupportPage({super.key, this.highlightHomeTips = false});

  @override
  ConsumerState<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends ConsumerState<SupportPage> {
  final GlobalKey _homeTipsKey = GlobalKey();
  bool _highlightActive = false;

  @override
  void initState() {
    super.initState();
    if (widget.highlightHomeTips) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToAndHighlight();
      });
    }
  }

  void _scrollToAndHighlight() {
    final ctx = _homeTipsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.3);
    }
    setState(() => _highlightActive = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightActive = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
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
        title: const Text('Help & Support'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsGroup(
                title: "SUPPORT",
                children: [
                  SettingsItem(
                    icon: Icons.auto_stories_rounded,
                    iconBg: const Color(0xFFF3E5F5),
                    iconColor: const Color(0xFF7B1FA2),
                    label: "User Guide",
                    sublabel: "Full feature walkthrough",
                    type: SettingsType.chevron,
                    hasSublabel: true,
                    onTap: () {
                      context.push(AppRoutes.userGuide);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsItem(
                    icon: Icons.menu_book_rounded,
                    iconBg: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF1565C0),
                    label: "Quick Guide",
                    sublabel: "Learn how Vaanix works",
                    type: SettingsType.chevron,
                    hasSublabel: true,
                    onTap: () {
                      context.push(AppRoutes.onboarding);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsItem(
                    icon: Icons.feedback_outlined,
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFF57C00),
                    label: "Send Feedback",
                    sublabel: "Bug reports, ideas & suggestions",
                    type: SettingsType.chevron,
                    hasSublabel: true,
                    onTap: () {
                      context.push(AppRoutes.feedback);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsItem(
                    icon: Icons.favorite_rounded,
                    iconBg: const Color(0xFFFFEBEE),
                    iconColor: const Color(0xFFD32F2F),
                    label: "Support Us",
                    sublabel: "Help keep Vaanix free & ad-free",
                    type: SettingsType.chevron,
                    hasSublabel: true,
                    onTap: () {
                      context.push(AppRoutes.supportUs);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  // Home Tips toggle — highlight target
                  AnimatedContainer(
                    key: _homeTipsKey,
                    duration: const Duration(milliseconds: 400),
                    decoration: BoxDecoration(
                      color: _highlightActive
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SettingsItem(
                      icon: Icons.tips_and_updates_rounded,
                      iconBg: const Color(0xFFFFF8E1),
                      iconColor: const Color(0xFFF9A825),
                      label: "Home Tips",
                      sublabel: "Show tips on the home screen",
                      type: SettingsType.toggle,
                      hasSublabel: true,
                      switchValue: !settings.tipTileDismissed,
                      onChanged: (value) {
                        ref
                            .read(settingsProvider.notifier)
                            .setTipTileDismissed(!value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SettingsGroup(
                title: "LEGAL",
                children: [
                  SettingsItem(
                    icon: Icons.shield_outlined,
                    iconBg: const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF2E7D32),
                    label: "Privacy Policy",
                    sublabel: "How we handle your data",
                    type: SettingsType.chevron,
                    hasSublabel: true,
                    onTap: () {
                      context.push(AppRoutes.privacyPolicy);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsItem(
                    icon: Icons.description_outlined,
                    iconBg: const Color(0xFFEDE7F6),
                    iconColor: const Color(0xFF5E35B1),
                    label: "Terms & Conditions",
                    sublabel: "Usage terms for Vaanix",
                    type: SettingsType.chevron,
                    hasSublabel: true,
                    onTap: () {
                      context.push(AppRoutes.termsConditions);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
