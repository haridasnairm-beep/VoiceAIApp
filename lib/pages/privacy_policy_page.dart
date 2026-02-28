import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
        title: const Text('Privacy & Data Policy'),
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
                  'PRIVACY & DATA POLICY',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'VOICENOTES AI',
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
                  'YOUR DATA LIVES ON YOUR DEVICE. VoiceNotes AI is a privacy-first, '
                  'local-only application. No data is sent to the cloud. No account is required. '
                  'Everything stays on your phone.',
                  style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // 1. LOCAL-FIRST ARCHITECTURE
              _sectionHeader('1. LOCAL-FIRST ARCHITECTURE', headingStyle),
              Text(
                'All your data — voice recordings, transcriptions, notes, folders, projects, '
                'reminders, and settings — is stored exclusively on your device using an encrypted '
                'local database (Hive with AES-256 encryption). Your device is the only data store. '
                'There is no cloud component, no server, and no remote database. The app works '
                'entirely offline.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 2. WHAT DATA IS STORED LOCALLY
              _sectionHeader('2. WHAT DATA IS STORED LOCALLY', headingStyle),
              _bulletItem('Voice recordings (audio files stored on device)', bulletStyle),
              _bulletItem('Transcriptions generated on-device from your recordings', bulletStyle),
              _bulletItem('Text notes you create manually', bulletStyle),
              _bulletItem('Folders and organizational structure', bulletStyle),
              _bulletItem('Project Documents and linked note references', bulletStyle),
              _bulletItem('Todo items, action items, and reminders', bulletStyle),
              _bulletItem('Image attachments', bulletStyle),
              _bulletItem('App settings and preferences (theme, audio quality, prefixes)', bulletStyle),
              _bulletItem('Notification scheduling data', bulletStyle),
              const SizedBox(height: 20),

              // 3. ON-DEVICE TRANSCRIPTION
              _sectionHeader('3. ON-DEVICE TRANSCRIPTION', headingStyle),
              Text(
                'VoiceNotes AI offers two transcription modes, both of which operate entirely '
                'on your device:\n\n'
                'Live Transcription uses your device\'s built-in speech recognition engine. '
                'No audio is sent to external servers.\n\n'
                'Whisper AI (Record & Transcribe) uses an on-device AI model that is downloaded '
                'once and runs locally. The model download is the only network operation — after '
                'that, all transcription happens offline on your device. Your audio never leaves '
                'your phone.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 4. NO ACCOUNT REQUIRED
              _sectionHeader('4. NO ACCOUNT REQUIRED', headingStyle),
              Text(
                'VoiceNotes AI does not require any account creation, login, or sign-in. '
                'There is no authentication system. You start using the app immediately '
                'with zero setup. No email, no password, no phone number — nothing.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 5. NOTIFICATIONS
              _sectionHeader('5. NOTIFICATIONS', headingStyle),
              Text(
                'VoiceNotes AI uses local notifications to deliver reminders you set manually. '
                'These notifications are scheduled entirely on-device using the system notification '
                'service. No push notification tokens are sent to any server. No cloud messaging '
                'service is used.\n\n'
                'Notification permission is requested by your device operating system. If you deny '
                'permission, reminders will still be saved but notifications will not appear. '
                'The app functions fully without notification permission.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 6. WHAT WE DON'T DO
              _sectionHeader('6. WHAT WE DON\'T DO', headingStyle),
              _dontItem('We don\'t collect, transmit, or store your data on any server.', bulletStyle),
              _dontItem('We don\'t use analytics, telemetry, or tracking of any kind.', bulletStyle),
              _dontItem('We don\'t sell, rent, or share your data with third parties.', bulletStyle),
              _dontItem('We don\'t use your data for advertising or profiling.', bulletStyle),
              _dontItem('We don\'t use cookies, tracking pixels, or device fingerprinting.', bulletStyle),
              _dontItem('We don\'t require an internet connection to function.', bulletStyle),
              _dontItem('We don\'t have ads and never will.', bulletStyle),
              _dontItem('We don\'t make any network calls except for the one-time Whisper model download.', bulletStyle),
              const SizedBox(height: 20),

              // 7. MICROPHONE ACCESS
              _sectionHeader('7. MICROPHONE ACCESS', headingStyle),
              Text(
                'VoiceNotes AI requests microphone permission to record voice notes. '
                'The microphone is used exclusively for recording audio that is saved locally '
                'on your device. Audio is never streamed, uploaded, or transmitted anywhere. '
                'You can revoke microphone permission at any time via your device settings — '
                'text note features will continue to work without it.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 8. STORAGE ACCESS
              _sectionHeader('8. STORAGE ACCESS', headingStyle),
              Text(
                'The app stores voice recordings and the Whisper AI model in your device\'s '
                'app-private storage directory. This storage is accessible only to VoiceNotes AI '
                'and is automatically deleted when you uninstall the app. All database content '
                'is encrypted with AES-256 encryption.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 9. YOUR RIGHTS
              _sectionHeader('9. YOUR RIGHTS', headingStyle),
              Text(
                'You own all your data. You can:',
                style: bodyStyle,
              ),
              const SizedBox(height: 4),
              _bulletItem('Delete individual notes, folders, or projects at any time', bulletStyle),
              _bulletItem('Delete all voice recordings from Settings', bulletStyle),
              _bulletItem('Delete the Whisper AI model from Settings', bulletStyle),
              _bulletItem('Delete all data from Settings (Danger Zone)', bulletStyle),
              _bulletItem('Delete everything by uninstalling the app', bulletStyle),
              _bulletItem('Export or share individual notes as you wish', bulletStyle),
              const SizedBox(height: 20),

              // 10. CHILDREN'S PRIVACY
              _sectionHeader('10. CHILDREN\'S PRIVACY', headingStyle),
              Text(
                'VoiceNotes AI is intended for users 13 years and older. Since the app does '
                'not collect any data or communicate with any server, there is no data '
                'collection from children or any other users.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 11. DATA SECURITY
              _sectionHeader('11. DATA SECURITY', headingStyle),
              Text(
                'All local data is stored in an AES-256 encrypted Hive database within your '
                'device\'s app-private storage. This storage is sandboxed by the operating system '
                'and accessible only to VoiceNotes AI. No data is transmitted over any network '
                '(except the one-time Whisper model download over HTTPS).',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 12. CHANGES TO THIS POLICY
              _sectionHeader('12. CHANGES TO THIS POLICY', headingStyle),
              Text(
                'We will notify you of any changes to this privacy policy through app updates.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 13. CONTACT
              _sectionHeader('13. CONTACT', headingStyle),
              Text(
                'For questions about privacy, email: support@hdmpixels.com',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),

              // 14. DEVELOPER
              _sectionHeader('14. DEVELOPER', headingStyle),
              Text(
                'VoiceNotes AI is developed by HDMPixels.',
                style: bodyStyle,
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

  static Widget _dontItem(String text, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('  \u2717  ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
