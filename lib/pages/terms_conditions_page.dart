import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.primary,
    );
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      height: 1.6,
    );
    final bulletStyle = theme.textTheme.bodyMedium?.copyWith(
      height: 1.6,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Text(
                  'TERMS & CONDITIONS',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'VAANIX',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Last Updated: February 2026',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Highlight box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'BY USING THIS APP, YOU AGREE TO THESE TERMS. '
                  'IF YOU DO NOT AGREE, DO NOT USE THE APP.',
                  style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // 1. ACCEPTANCE OF TERMS
              _sectionHeader('1. ACCEPTANCE OF TERMS', headingStyle),
              Text(
                'By accessing or using Vaanix ("the App"), you agree to be bound by these '
                'Terms & Conditions. These terms apply to all users of the App.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 2. LICENSE TO USE
              _sectionHeader('2. LICENSE TO USE', headingStyle),
              Text(
                'We grant you a limited, non-exclusive, non-transferable, revocable license to use '
                'Vaanix for personal, non-commercial purposes in accordance with these Terms.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 3. INTELLECTUAL PROPERTY RIGHTS
              _sectionHeader('3. INTELLECTUAL PROPERTY RIGHTS', headingStyle),
              Text(
                '3.1 App Ownership',
                style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _bulletItem(
                'Vaanix, including its source code, design, features, graphics, logo, '
                'and user interface, is owned by HDMPixels and protected by copyright laws.',
                bulletStyle,
              ),
              _bulletItem(
                'All rights, title, and interest in the App remain with HDMPixels.',
                bulletStyle,
              ),
              const SizedBox(height: 12),
              Text(
                '3.2 Your Content',
                style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _bulletItem(
                'You retain ownership of all voice recordings, transcriptions, notes, and content '
                'you create in the App.',
                bulletStyle,
              ),
              _bulletItem(
                'Your data is stored exclusively on your device. No cloud services are used.',
                bulletStyle,
              ),
              const SizedBox(height: 12),
              Text(
                '3.3 Restrictions',
                style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text('You may NOT:', style: bodyStyle),
              _restrictionItem('Copy, modify, or reverse engineer the App', bulletStyle),
              _restrictionItem('Remove copyright notices or branding', bulletStyle),
              _restrictionItem('Create derivative works based on the App', bulletStyle),
              _restrictionItem('Sell, rent, lease, or distribute the App', bulletStyle),
              _restrictionItem('Use the App for commercial purposes without permission', bulletStyle),
              _restrictionItem('Extract or scrape data from the App using automated means', bulletStyle),
              const SizedBox(height: 20),

              // 4. COPYRIGHT PROTECTION
              _sectionHeader('4. COPYRIGHT PROTECTION', headingStyle),
              Text(
                '4.1 Original Work',
                style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _bulletItem(
                'Vaanix is an original work created by HDMPixels.',
                bulletStyle,
              ),
              _bulletItem(
                'The app concept, design, implementation, and documentation are protected by copyright.',
                bulletStyle,
              ),
              _bulletItem(
                'Copyright \u00A9 2026 HDMPixels. All rights reserved.',
                bulletStyle,
              ),
              const SizedBox(height: 12),
              Text(
                '4.2 Trademark',
                style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _bulletItem(
                '"Vaanix" and the Vaanix logo are trademarks of HDMPixels.',
                bulletStyle,
              ),
              _bulletItem(
                'Unauthorized use of our trademarks is prohibited.',
                bulletStyle,
              ),
              const SizedBox(height: 12),
              Text(
                '4.3 Reporting Infringement',
                style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _bulletItem(
                'If you believe someone has copied Vaanix, report to: support@hdmpixels.com',
                bulletStyle,
              ),
              _bulletItem(
                'We take copyright infringement seriously and will pursue legal action when necessary.',
                bulletStyle,
              ),
              const SizedBox(height: 20),

              // 5. PROHIBITED USES
              _sectionHeader('5. PROHIBITED USES', headingStyle),
              Text('You agree NOT to:', style: bodyStyle),
              _restrictionItem('Violate any laws or regulations', bulletStyle),
              _restrictionItem('Infringe on intellectual property rights', bulletStyle),
              _restrictionItem('Attempt to gain unauthorized access to the App', bulletStyle),
              _restrictionItem('Interfere with the App\'s operation', bulletStyle),
              _restrictionItem('Impersonate HDMPixels or claim ownership of the App', bulletStyle),
              _restrictionItem(
                'Create a competing product by copying our features, design, or code',
                bulletStyle,
              ),
              const SizedBox(height: 20),

              // 6. LOCAL DATA & STORAGE
              _sectionHeader('6. LOCAL DATA & STORAGE', headingStyle),
              Text(
                '6.1 Your device is the sole data store. All data — voice recordings, transcriptions, '
                'notes, folders, projects, reminders, and settings — is stored locally on your device '
                'using an encrypted database (Hive with AES-256 encryption). There is no cloud component.',
                style: bodyStyle,
              ),
              const SizedBox(height: 8),
              Text(
                '6.2 The App works entirely offline. The only network operation is the optional one-time '
                'download of the Whisper transcription model (~140 MB). After download, all '
                'transcription happens on-device.',
                style: bodyStyle,
              ),
              const SizedBox(height: 8),
              Text(
                '6.3 All local data is stored in your device\'s app-private storage, accessible only '
                'to Vaanix and encrypted with AES-256.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 7. ON-DEVICE TRANSCRIPTION
              _sectionHeader('7. ON-DEVICE TRANSCRIPTION', headingStyle),
              Text(
                '7.1 Vaanix offers two transcription modes: Live Transcription (using your '
                'device\'s built-in speech recognition) and Whisper (using a locally downloaded '
                'AI model). Both operate entirely on your device.',
                style: bodyStyle,
              ),
              const SizedBox(height: 8),
              Text(
                '7.2 The Whisper model is downloaded once over the internet and thereafter runs '
                'completely offline. Your audio recordings are never transmitted to any server.',
                style: bodyStyle,
              ),
              const SizedBox(height: 8),
              Text(
                '7.3 Transcription accuracy depends on audio quality, background noise, and language. '
                'We do not guarantee perfect transcription results.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 8. NOTIFICATIONS
              _sectionHeader('8. NOTIFICATIONS', headingStyle),
              Text(
                '8.1 Vaanix uses local notifications (not push notifications) to deliver '
                'reminders you set manually. No notification tokens are sent to any server.',
                style: bodyStyle,
              ),
              const SizedBox(height: 8),
              Text(
                '8.2 Notification permission is requested by your device operating system. You are '
                'never required to grant notification permission — the app functions fully without it.',
                style: bodyStyle,
              ),
              const SizedBox(height: 8),
              Text(
                '8.3 You can revoke notification permission at any time via your device settings.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 9. MICROPHONE ACCESS
              _sectionHeader('9. MICROPHONE ACCESS', headingStyle),
              Text(
                '9.1 Vaanix requests microphone permission to record voice notes. The '
                'microphone is used exclusively for recording audio that is saved locally on your device.',
                style: bodyStyle,
              ),
              const SizedBox(height: 8),
              Text(
                '9.2 Audio is never streamed, uploaded, or transmitted anywhere. You can revoke '
                'microphone permission at any time — text note features will continue to work.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 10. USER RESPONSIBILITIES
              _sectionHeader('10. USER RESPONSIBILITIES', headingStyle),
              Text('You are responsible for:', style: bodyStyle),
              _bulletItem('Maintaining the security of your device', bulletStyle),
              _bulletItem('All activity that occurs through your use of the App', bulletStyle),
              _bulletItem('Ensuring your device has adequate storage and updates', bulletStyle),
              _bulletItem(
                'Backing up your data (your device is the sole data store — uninstalling '
                'the app deletes all data)',
                bulletStyle,
              ),
              const SizedBox(height: 20),

              // 11. DISCLAIMER OF WARRANTIES
              _sectionHeader('11. DISCLAIMER OF WARRANTIES', headingStyle),
              Text(
                'THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, '
                'INCLUDING BUT NOT LIMITED TO:',
                style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _bulletItem('Merchantability', bulletStyle),
              _bulletItem('Fitness for a particular purpose', bulletStyle),
              _bulletItem('Non-infringement', bulletStyle),
              _bulletItem('Uninterrupted or error-free operation', bulletStyle),
              const SizedBox(height: 8),
              Text(
                'We do not guarantee that the App will meet your requirements or be free from bugs.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 12. LIMITATION OF LIABILITY
              _sectionHeader('12. LIMITATION OF LIABILITY', headingStyle),
              Text(
                'To the maximum extent permitted by law:',
                style: bodyStyle,
              ),
              _bulletItem(
                'HDMPixels is not liable for any indirect, incidental, special, or consequential damages',
                bulletStyle,
              ),
              _bulletItem(
                'Our total liability will not exceed the amount you paid for the App '
                '(the App is free, so liability is \$0)',
                bulletStyle,
              ),
              _bulletItem(
                'We are not responsible for data loss due to device issues, uninstallation, or user error',
                bulletStyle,
              ),
              _bulletItem(
                'We are not responsible for transcription inaccuracies',
                bulletStyle,
              ),
              const SizedBox(height: 20),

              // 13. INDEMNIFICATION
              _sectionHeader('13. INDEMNIFICATION', headingStyle),
              Text(
                'You agree to indemnify and hold HDMPixels harmless from any claims, damages, losses, '
                'or expenses (including legal fees) arising from:',
                style: bodyStyle,
              ),
              _bulletItem('Your use of the App', bulletStyle),
              _bulletItem('Your violation of these Terms', bulletStyle),
              _bulletItem('Your violation of any third-party rights', bulletStyle),
              const SizedBox(height: 20),

              // 14. UPDATES AND MODIFICATIONS
              _sectionHeader('14. UPDATES AND MODIFICATIONS', headingStyle),
              Text(
                '14.1 App Updates',
                style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _bulletItem(
                'We may update the App to add features, fix bugs, or improve performance',
                bulletStyle,
              ),
              _bulletItem('Updates may change how the App works', bulletStyle),
              _bulletItem(
                'Continued use after updates means you accept the changes',
                bulletStyle,
              ),
              const SizedBox(height: 12),
              Text(
                '14.2 Terms Changes',
                style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _bulletItem('We may modify these Terms at any time', bulletStyle),
              _bulletItem(
                'Changes will be communicated through app updates',
                bulletStyle,
              ),
              _bulletItem(
                'Your continued use constitutes acceptance of new Terms',
                bulletStyle,
              ),
              const SizedBox(height: 20),

              // 15. TERMINATION
              _sectionHeader('15. TERMINATION', headingStyle),
              Text(
                '15.1 By You',
                style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _bulletItem(
                'You may stop using the App at any time by uninstalling it',
                bulletStyle,
              ),
              _bulletItem(
                'You may delete all data from Settings > Danger Zone at any time',
                bulletStyle,
              ),
              const SizedBox(height: 12),
              Text(
                '15.2 By Us',
                style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _bulletItem(
                'We may discontinue the App at any time with or without notice',
                bulletStyle,
              ),
              const SizedBox(height: 12),
              Text(
                '15.3 Effect of Termination',
                style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _bulletItem(
                'Upon termination, your license to use the App ends immediately',
                bulletStyle,
              ),
              _bulletItem(
                'Your local data remains on your device until you uninstall the App',
                bulletStyle,
              ),
              const SizedBox(height: 20),

              // 16. GOVERNING LAW
              _sectionHeader('16. GOVERNING LAW', headingStyle),
              Text(
                'These Terms are governed by applicable laws in your jurisdiction.\n\n'
                'Disputes will be resolved through:\n'
                '\u2022  Good faith negotiation first\n'
                '\u2022  Binding arbitration if negotiation fails\n'
                '\u2022  Small claims court for claims under jurisdictional limits',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 17. DISPUTE RESOLUTION
              _sectionHeader('17. DISPUTE RESOLUTION', headingStyle),
              Text(
                'Before filing any legal action:',
                style: bodyStyle,
              ),
              _bulletItem('Contact us at support@hdmpixels.com', bulletStyle),
              _bulletItem('We commit to resolving disputes within 30 days', bulletStyle),
              _bulletItem('Most issues can be resolved through communication', bulletStyle),
              const SizedBox(height: 20),

              // 18. SEVERABILITY
              _sectionHeader('18. SEVERABILITY', headingStyle),
              Text(
                'If any provision of these Terms is found to be unenforceable, the remaining '
                'provisions will continue in full force and effect.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 19. ENTIRE AGREEMENT
              _sectionHeader('19. ENTIRE AGREEMENT', headingStyle),
              Text(
                'These Terms, along with our Privacy & Data Policy, constitute the entire '
                'agreement between you and HDMPixels regarding the App.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 20. CONTACT INFORMATION
              _sectionHeader('20. CONTACT INFORMATION', headingStyle),
              Text(
                'For questions about these Terms:\n'
                'Email: support@hdmpixels.com\n'
                'Developer: HDMPixels',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 21. ACKNOWLEDGMENT
              _sectionHeader('21. ACKNOWLEDGMENT', headingStyle),
              Text(
                'BY USING VAANIX, YOU ACKNOWLEDGE THAT:',
                style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _bulletItem('You have read and understood these Terms', bulletStyle),
              _bulletItem('You agree to be bound by these Terms', bulletStyle),
              _bulletItem('You are at least 13 years old', bulletStyle),
              _bulletItem(
                'You will use the App in compliance with all applicable laws',
                bulletStyle,
              ),
              _bulletItem(
                'You understand that your device is the sole data store and no cloud services are used',
                bulletStyle,
              ),
              _bulletItem(
                'You understand that uninstalling the app permanently deletes all data',
                bulletStyle,
              ),
              _bulletItem(
                'You understand that notification and microphone permissions are optional',
                bulletStyle,
              ),
              const SizedBox(height: 28),

              // Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Copyright \u00A9 2026 HDMPixels. All Rights Reserved.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vaanix and the Vaanix logo are trademarks of HDMPixels.\n\n'
                      'Unauthorized copying, distribution, or modification is strictly prohibited '
                      'and may result in legal action.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
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

  static Widget _sectionHeader(String text, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: style),
    );
  }

  static Widget _bulletItem(String text, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('  \u2022  ', style: style),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }

  static Widget _restrictionItem(String text, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('  \u2717  ',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
