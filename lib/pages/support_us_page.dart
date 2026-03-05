import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../nav.dart';

class SupportUsPage extends StatelessWidget {
  const SupportUsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Support Us'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Heart icon
              Icon(Icons.favorite_rounded,
                  color: theme.colorScheme.error, size: 56),
              const SizedBox(height: 16),
              Text(
                'Keep Vaanix\nFree & Ad-Free',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Why support us
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _PromiseRow(
                      icon: Icons.money_off_rounded,
                      text: 'Always free to use — no subscriptions',
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _PromiseRow(
                      icon: Icons.block_rounded,
                      text: 'No ads, ever — your experience matters',
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _PromiseRow(
                      icon: Icons.shield_outlined,
                      text: 'No data tracking — your privacy is sacred',
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _PromiseRow(
                      icon: Icons.phonelink_lock_rounded,
                      text: 'Everything stays on your device',
                      theme: theme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Message
              Text(
                'Building and maintaining great software takes time and resources. '
                'If Vaanix has been helpful to you, consider buying us a coffee!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your support directly funds new features and keeps Vaanix running.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Buy Me a Coffee button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Share.share('https://buymeacoffee.com/hdmpixels');
                  },
                  icon: const Icon(Icons.coffee_rounded),
                  label: const Text('Buy Me a Coffee'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Any amount helps!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Share the app
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.share_rounded,
                        color: theme.colorScheme.primary, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      'Another way to help?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share Vaanix with friends and family!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromiseRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeData theme;

  const _PromiseRow({
    required this.icon,
    required this.text,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
          ),
        ),
      ],
    );
  }
}
