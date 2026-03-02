import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/hive_service.dart';
import '../services/whisper_service.dart';

/// Group container for settings items with a title header.
class SettingsGroup extends StatelessWidget {
  final String title;
  final Color? titleColor;
  final List<Widget> children;

  const SettingsGroup({
    super.key,
    required this.title,
    this.titleColor,
    required this.children,
  });

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
                  color: titleColor ?? Theme.of(context).colorScheme.secondary,
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

enum SettingsType { toggle, chevron, value }

/// Individual settings row with icon, label, sublabel, and trailing widget.
class SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String? sublabel;
  final SettingsType type;
  final bool switchValue;
  final String? valueText;
  final bool hasSublabel;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.sublabel,
    required this.type,
    this.switchValue = false,
    this.valueText,
    this.hasSublabel = false,
    this.onChanged,
    this.onTap,
  });

  String _truncateValue(String value) {
    if (value.length <= 6) return value;
    return '${value.substring(0, 6)}..';
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
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
                          fontSize: 11,
                        ),
                  ),
              ],
            ),
          ),
          if (type == SettingsType.toggle)
            Switch(
              value: switchValue,
              onChanged: onChanged ?? (val) {},
              activeThumbColor: Theme.of(context).colorScheme.primary,
            )
          else if (type == SettingsType.chevron)
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).hintColor, size: 20)
          else if (type == SettingsType.value)
            Text(
              _truncateValue(valueText ?? ""),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}

/// Danger zone item with alarming red/orange tint.
class DangerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  final bool isDestructive;

  const DangerItem({
    super.key,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: isDestructive ? const Color(0x22FF5722) : const Color(0x10FF5722),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Icon(icon, color: const Color(0xFFD32F2F), size: 20),
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
                  Text(
                    sublabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).hintColor, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Storage breakdown section showing Whisper model, recordings, and text data sizes.
class StorageBreakdownSection extends StatefulWidget {
  final int noteCount;
  final int folderCount;

  const StorageBreakdownSection({
    super.key,
    required this.noteCount,
    required this.folderCount,
  });

  @override
  State<StorageBreakdownSection> createState() =>
      _StorageBreakdownSectionState();
}

class _StorageBreakdownSectionState extends State<StorageBreakdownSection> {
  Map<String, int>? _breakdown;
  int _whisperBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadBreakdown();
  }

  Future<void> _loadBreakdown() async {
    final breakdown = await HiveService.getStorageBreakdown();
    final whisperSize = await WhisperService.instance.getModelSizeBytes();
    if (mounted) {
      setState(() {
        _breakdown = breakdown;
        _whisperBytes = whisperSize;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = (_breakdown?['total'] ?? 0) + _whisperBytes;

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Local Storage",
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                "${widget.noteCount} notes · ${widget.folderCount} folders",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StorageRow(
            icon: Icons.downloading_rounded,
            color: const Color(0xFFE65100),
            label: 'Whisper Model',
            size: _whisperBytes > 0
                ? HiveService.formatBytes(_whisperBytes)
                : 'Not installed',
          ),
          const SizedBox(height: 10),
          _StorageRow(
            icon: Icons.graphic_eq_rounded,
            color: const Color(0xFF2E7D32),
            label: 'Voice Recordings',
            size: HiveService.formatBytes(_breakdown?['recordings'] ?? 0),
          ),
          const SizedBox(height: 10),
          _StorageRow(
            icon: Icons.text_snippet_rounded,
            color: const Color(0xFF1565C0),
            label: 'Notes & Database',
            size: HiveService.formatBytes(_breakdown?['hive'] ?? 0),
          ),
          if ((_breakdown?['images'] ?? 0) > 0) ...[
            const SizedBox(height: 10),
            _StorageRow(
              icon: Icons.image_rounded,
              color: const Color(0xFF7B1FA2),
              label: 'Images',
              size: HiveService.formatBytes(_breakdown?['images'] ?? 0),
            ),
          ],
          Divider(height: 24, color: theme.dividerColor),
          _StorageRow(
            icon: Icons.storage_rounded,
            color: theme.colorScheme.primary,
            label: 'Total',
            size: HiveService.formatBytes(total),
            isBold: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: theme.hintColor, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "All data is stored locally on this device.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorageRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String size;
  final bool isBold;

  const _StorageRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.size,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final weight = isBold ? FontWeight.w700 : FontWeight.w500;
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: weight,
                ),
          ),
        ),
        Text(
          size,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isBold
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.secondary,
                fontWeight: weight,
              ),
        ),
      ],
    );
  }
}


/// Wrapper to distinguish null (Automatic) from dialog dismissal.
class LanguageChoice {
  final String? code;
  const LanguageChoice(this.code);
}

/// Converts a language code (e.g. 'en', 'hi') to a friendly display name.
/// Falls back to the uppercased code if the code is not in [languageOptions].
String friendlyLanguageName(String code) {
  return languageOptions[code] ?? code.toUpperCase();
}

/// Language options map for detection language picker.
const languageOptions = <String?, String>{
  'en': 'English',
  'es': 'Spanish',
  'fr': 'French',
  'de': 'German',
  'hi': 'Hindi',
  'ar': 'Arabic',
  'pt': 'Portuguese',
  'zh': 'Chinese',
  'ja': 'Japanese',
  'ko': 'Korean',
  'ru': 'Russian',
  'it': 'Italian',
};
