import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../widgets/settings_widgets.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
