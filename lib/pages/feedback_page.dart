import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

const _feedbackCategories = [
  'Bug Report',
  'Feature Request',
  'General Feedback',
];

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  String _selectedCategory = _feedbackCategories.last;
  final _feedbackController = TextEditingController();
  bool _showCategoryMenu = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _sendFeedback() {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your feedback before sending.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final subject = 'VoiceNotes AI Feedback: $_selectedCategory';
    final body = 'Category: $_selectedCategory\n\n$text';

    // Open share sheet so user can pick email client
    Share.share(
      'To: hdmpixels@gmail.com\nSubject: $subject\n\n$body',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final charCount = _feedbackController.text.length;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icons/logo.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Send Feedback'),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category selector
                    GestureDetector(
                      onTap: () {
                        setState(() => _showCategoryMenu = !_showCategoryMenu);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedCategory,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              _showCategoryMenu
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Dropdown options
                    if (_showCategoryMenu)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: _feedbackCategories.map((category) {
                            final isSelected = category == _selectedCategory;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                  _showCategoryMenu = false;
                                });
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primaryContainer
                                          .withValues(alpha: 0.3)
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  category,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Feedback label
                    Text(
                      'Your Feedback',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Text field
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _feedbackController,
                            maxLines: 8,
                            maxLength: 1000,
                            buildCounter: (context,
                                    {required currentLength,
                                    required isFocused,
                                    required maxLength}) =>
                                null,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Tell us what you think...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (charCount > 0 && charCount < 20)
                                  Text(
                                    'Min 20 characters',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                Text(
                                  '$charCount/1000',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: charCount > 900
                                        ? Colors.red
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Send button at bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed:
                      _feedbackController.text.trim().length < 20 ? null : _sendFeedback,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Send Feedback',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
