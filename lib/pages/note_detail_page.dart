import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voicenotes_ai/theme.dart';

class NoteDetailPage extends StatelessWidget {
  final String? recordingPath;

  const NoteDetailPage({super.key, this.recordingPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Theme.of(context).colorScheme.onSurface,
                    onPressed: () => context.pop(),
                  ),
                  Column(
                    children: [
                      Text(
                        "Project Alpha Sync",
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.lightSuccess,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Detected: English",
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    color: Theme.of(context).colorScheme.onSurface,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Audio Player Card
                    Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.play_circle_filled_rounded,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(
                                      height: 32,
                                      child: CustomPaint(
                                        painter: WaveformPainter(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "0:00",
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                        ),
                                        Text(
                                          "—",
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.share_rounded,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ],
                          ),
                          if (recordingPath != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.08),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.mic_rounded,
                                      size: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      recordingPath!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Transcription
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionHeader(
                            icon: Icons.notes_rounded,
                            title: "Transcription",
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                  color: Theme.of(context).dividerColor),
                            ),
                            child: Text(
                              "We need to finalize the UI for the dashboard by Friday. Also, don't forget to send the updated API documentation to Sarah. I'm thinking we should add a dark mode toggle in the settings. Remind me to call the design team tomorrow at 10 AM.",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    height: 1.6,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Items
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SectionHeader(
                            icon: Icons.checklist_rounded,
                            title: "Action Items",
                            color: AppColors.lightSuccess,
                          ),
                          _TaskItem(
                            content: "Finalize Dashboard UI",
                            checked: false,
                            hasMeta: true,
                            metaIcon: Icons.calendar_today,
                            metaText: "Due Friday",
                          ),
                          _TaskItem(
                            content: "Send API docs to Sarah",
                            checked: true,
                            hasMeta: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reminders
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SectionHeader(
                            icon: Icons.alarm_rounded,
                            title: "Reminders",
                            color: AppColors.lightAccent,
                          ),
                          _TaskItem(
                            content: "Call design team",
                            checked: false,
                            hasMeta: true,
                            metaIcon: Icons.schedule,
                            metaText: "Tomorrow, 10:00 AM",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // AI Follow-up
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF8F3),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: const Color(0xFFF5E6D3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.lightbulb_rounded,
                                  color: Color(0xFFD97706), size: 20),
                              SizedBox(width: 8),
                              Text(
                                "AI Follow-up Questions",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const _AiSuggestion(
                            text:
                                "Would you like me to schedule the call with the design team in your calendar?",
                          ),
                          const _AiSuggestion(
                            text:
                                "Should I create a sub-task list for the Dashboard UI finalization?",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border:
              Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_note_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Edit Note",
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_fix_high_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Ask AI",
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String content;
  final bool checked;
  final bool hasMeta;
  final IconData? metaIcon;
  final String? metaText;

  const _TaskItem({
    required this.content,
    required this.checked,
    this.hasMeta = false,
    this.metaIcon,
    this.metaText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            checked
                ? Icons.check_box_rounded
                : Icons.check_box_outline_blank_rounded,
            color: checked
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: checked
                            ? Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.7)
                            : Theme.of(context).colorScheme.onSurface,
                        decoration: checked ? TextDecoration.lineThrough : null,
                      ),
                ),
                if (hasMeta) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(metaIcon,
                          size: 14,
                          color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        metaText!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSuggestion extends StatelessWidget {
  final String text;

  const _AiSuggestion({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFD1E9FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.onPrimary, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          Icon(Icons.chevron_right,
              color: Theme.of(context).colorScheme.primary, size: 20),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final Color color;

  WaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Simple mock waveform
    for (double i = 0; i < size.width; i += 6) {
      final h = (i % 20 == 0)
          ? size.height
          : size.height * 0.5; // Just random-ish pattern
      final y = size.height / 2;
      canvas.drawLine(Offset(i, y - h / 2), Offset(i, y + h / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
