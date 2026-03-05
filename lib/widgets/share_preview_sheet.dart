import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/sharing_service.dart';
import '../theme.dart';

/// A bottom-sheet that shows a live preview of share content with toggle
/// controls for title, timestamp, and plain-text mode, plus export buttons.
class SharePreviewSheet extends StatefulWidget {
  /// Title used for the email subject line.
  final String title;

  /// Whether this is a project document (shows Markdown export button).
  final bool isProject;

  /// Builds the share text for the current [ShareOptions].
  final String Function(ShareOptions options) assembleText;

  /// Generates a PDF file for the current options. Null hides the button.
  final Future<File> Function(ShareOptions options)? onExportPdf;

  /// Generates a Markdown file. Null hides the button. Projects only.
  final Future<File> Function()? onExportMarkdown;

  const SharePreviewSheet({
    super.key,
    required this.title,
    required this.isProject,
    required this.assembleText,
    this.onExportPdf,
    this.onExportMarkdown,
  });

  @override
  State<SharePreviewSheet> createState() => _SharePreviewSheetState();
}

class _SharePreviewSheetState extends State<SharePreviewSheet> {
  bool _includeTitle = true;
  bool _includeTimestamp = false;
  bool _plainTextOnly = false;
  bool _includeNoteTitles = true;
  bool _exporting = false;

  ShareOptions get _options => ShareOptions(
        includeTitle: _includeTitle,
        includeTimestamp: _includeTimestamp,
        plainTextOnly: _plainTextOnly,
        includeNoteTitles: _includeNoteTitles,
      );

  /// Preview text assembled with current options (including rich text format).
  String get _previewText => widget.assembleText(_options);

  String get _subject => widget.isProject
      ? SharingService.documentSubject(widget.title)
      : SharingService.noteSubject(widget.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _previewText;
    final isEmpty = preview.trim().isEmpty ||
        preview.trim() == '— Shared from Vaanix';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withAlpha(50),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Title row
            Row(
              children: [
                Icon(Icons.share_rounded,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Share Preview',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Toggle switches
            _ToggleRow(
              label: 'Include Title',
              value: _includeTitle,
              onChanged: (v) => setState(() => _includeTitle = v),
            ),
            _ToggleRow(
              label: 'Include Timestamp',
              value: _includeTimestamp,
              onChanged: (v) => setState(() => _includeTimestamp = v),
            ),
            _ToggleRow(
              label: 'Plain Text Only',
              value: _plainTextOnly,
              onChanged: (v) => setState(() => _plainTextOnly = v),
            ),
            if (widget.isProject)
              _ToggleRow(
                label: 'Include Note Titles',
                value: _includeNoteTitles,
                onChanged: (v) => setState(() => _includeNoteTitles = v),
              ),
            const SizedBox(height: 8),

            // Preview area — expands to fill available space
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: theme.colorScheme.outline.withAlpha(60)),
                ),
                child: SingleChildScrollView(
                  child: isEmpty
                      ? Text('(No content to share)',
                          style: TextStyle(
                              color: theme.hintColor,
                              fontStyle: FontStyle.italic))
                      : _plainTextOnly
                          ? Text(
                              preview,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: theme.colorScheme.onSurface,
                              ),
                            )
                          : _buildRichPreview(preview, theme),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            if (_exporting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Share as Text
                  FilledButton.icon(
                    onPressed: isEmpty
                        ? null
                        : () {
                            Share.share(preview, subject: _subject);
                            Navigator.pop(context);
                          },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share as Text'),
                  ),
                  const SizedBox(height: 8),

                  // Export as PDF
                  if (widget.onExportPdf != null)
                    OutlinedButton.icon(
                      onPressed: isEmpty ? null : _exportPdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded,
                          size: 18),
                      label: const Text('Export as PDF'),
                    ),

                  // Export as Markdown (projects only)
                  if (widget.onExportMarkdown != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: isEmpty ? null : _exportMarkdown,
                      icon: const Icon(Icons.description_rounded,
                          size: 18),
                      label: const Text('Export as Markdown'),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Renders preview text with basic markdown formatting (bold, italic).
  Widget _buildRichPreview(String text, ThemeData theme) {
    final baseStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 11,
      color: theme.colorScheme.onSurface,
    );

    final lines = text.split('\n');
    final children = <Widget>[];

    for (final line in lines) {
      children.add(RichText(
        text: TextSpan(
          style: baseStyle,
          children: _parseMarkdownSpans(line, baseStyle),
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// Parses a single line for **bold** and *italic* markdown markers.
  List<TextSpan> _parseMarkdownSpans(String text, TextStyle? baseStyle) {
    final spans = <TextSpan>[];
    // Match **bold** and *italic* patterns
    final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Text before the match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      if (match.group(1) != null) {
        // **bold**
        spans.add(TextSpan(
          text: match.group(1),
          style: baseStyle?.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(2) != null) {
        // *italic*
        spans.add(TextSpan(
          text: match.group(2),
          style: baseStyle?.copyWith(fontStyle: FontStyle.italic),
        ));
      }

      lastEnd = match.end;
    }

    // Remaining text after last match
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }

    return spans;
  }

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final file = await widget.onExportPdf!(_options);
      if (!mounted) return;
      Navigator.pop(context);
      await Share.shareXFiles([XFile(file.path)], subject: _subject);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportMarkdown() async {
    setState(() => _exporting = true);
    try {
      final file = await widget.onExportMarkdown!();
      if (!mounted) return;
      Navigator.pop(context);
      await Share.shareXFiles([XFile(file.path)], subject: _subject);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export Markdown: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

/// Compact toggle row for the share preview sheet.
class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: Text(label,
          style: Theme.of(context).textTheme.bodyMedium),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
