import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Settings",
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      Text(
                        "Personalize your recording experience",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Icon(Icons.person,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Profile Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      child: const Text("JD"),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Jane Doe",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          Text(
                            "jane.doe@example.com",
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: const Text("Edit"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Preferences Group
              _SettingsGroup(
                title: "PREFERENCES",
                children: [
                  _SettingsItem(
                    icon: Icons.language_rounded,
                    iconBg: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF1976D2),
                    label: "Detection Language",
                    sublabel: "Auto-detect is active",
                    type: _SettingsType.value,
                    valueText: "Automatic",
                    hasSublabel: true,
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsItem(
                    icon: Icons.notifications_active_rounded,
                    iconBg: const Color(0xFFF1F8E9),
                    iconColor: const Color(0xFF388E3C),
                    label: "Smart Reminders",
                    type: _SettingsType.toggle,
                    switchValue: true,
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsItem(
                    icon: Icons.dark_mode_rounded,
                    iconBg: const Color(0xFFF3E5F5),
                    iconColor: const Color(0xFF7B1FA2),
                    label: "Appearance",
                    type: _SettingsType.value,
                    valueText: "System",
                  ),
                ],
              ),

              // Audio & AI Group
              _SettingsGroup(
                title: "AUDIO & AI",
                children: [
                  _SettingsItem(
                    icon: Icons.high_quality_rounded,
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFF57C00),
                    label: "Audio Quality",
                    sublabel: "Higher quality uses more space",
                    type: _SettingsType.value,
                    valueText: "HD",
                    hasSublabel: true,
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsItem(
                    icon: Icons.psychology_rounded,
                    iconBg: const Color(0xFFE0F2F1),
                    iconColor: const Color(0xFF00796B),
                    label: "AI Follow-up",
                    sublabel: "Generate smart suggestions",
                    type: _SettingsType.toggle,
                    switchValue: true,
                    hasSublabel: true,
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsItem(
                    icon: Icons.cloud_done_rounded,
                    iconBg: const Color(0xFFE8EAF6),
                    iconColor: const Color(0xFF3F51B5),
                    label: "Cloud Sync",
                    type: _SettingsType.toggle,
                    switchValue: true,
                  ),
                ],
              ),

              // Storage Usage
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Local Storage",
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        Text(
                          "1.2 GB of 5 GB",
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: 0.24,
                        minHeight: 8,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Theme.of(context).hintColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "Your voice notes are backed up to the cloud.",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Support Group
              _SettingsGroup(
                title: "SUPPORT",
                children: [
                  _SettingsItem(
                    icon: Icons.help_outline_rounded,
                    iconBg: Theme.of(context).scaffoldBackgroundColor,
                    iconColor: Theme.of(context).colorScheme.secondary,
                    label: "Help Center",
                    type: _SettingsType.chevron,
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsItem(
                    icon: Icons.description_outlined,
                    iconBg: Theme.of(context).scaffoldBackgroundColor,
                    iconColor: Theme.of(context).colorScheme.secondary,
                    label: "Terms of Service",
                    type: _SettingsType.chevron,
                  ),
                ],
              ),

              // Log Out
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text(
                  "Log Out",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),

              const SizedBox(height: 32),
              Center(
                child: Text(
                  "VoiceNotes AI v2.4.0",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

enum _SettingsType { toggle, chevron, value }

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String? sublabel;
  final _SettingsType type;
  final bool switchValue;
  final String? valueText;
  final bool hasSublabel;

  const _SettingsItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.sublabel,
    required this.type,
    this.switchValue = false,
    this.valueText,
    this.hasSublabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                if (hasSublabel && sublabel != null)
                  Text(
                    sublabel!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
              ],
            ),
          ),
          if (type == _SettingsType.toggle)
            Switch(
              value: switchValue,
              onChanged: (val) {},
              activeColor: Theme.of(context).colorScheme.primary,
            )
          else if (type == _SettingsType.chevron)
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).hintColor, size: 20)
          else if (type == _SettingsType.value)
            Row(
              children: [
                Text(
                  valueText ?? "",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    color: Theme.of(context).hintColor, size: 20),
              ],
            ),
        ],
      ),
    );
  }
}
