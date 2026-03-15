import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../utils/responsive.dart';

/// Full-screen blocking page shown when a force/critical update is required.
/// The user cannot dismiss or navigate away — they must update.
class ForceUpdatePage extends StatelessWidget {
  final String version;
  final String? releaseNotes;
  final String downloadUrl;

  const ForceUpdatePage({
    super.key,
    required this.version,
    this.releaseNotes,
    required this.downloadUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      AppColors.darkBackground,
                      const Color(0xFF1A2332),
                      AppColors.darkBackground,
                    ]
                  : [
                      AppColors.lightBackground,
                      const Color(0xFFE8F0FE),
                      AppColors.lightBackground,
                    ],
            ),
          ),
          child: SafeArea(
            child: ResponsiveCenter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // App icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: Image.asset('assets/icons/logo.png',
                          fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Title
                  Text(
                    'Update Required',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Text(
                    'A critical update (v$version) is available.\nPlease update to continue using Vaanix.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.secondary,
                      height: 1.5,
                    ),
                  ),
                  // Release notes (if any)
                  if (releaseNotes != null && releaseNotes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 160),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          releaseNotes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.8),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(flex: 2),
                  // Update button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(downloadUrl),
                          mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.system_update_rounded),
                      label: const Text('Update Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        textStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}
