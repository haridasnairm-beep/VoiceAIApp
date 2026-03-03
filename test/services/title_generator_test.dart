import 'package:flutter_test/flutter_test.dart';
import 'package:voicenotes_ai/services/title_generator_service.dart';

void main() {
  group('TitleGeneratorService', () {
    group('empty/null input', () {
      test('returns null for empty transcription', () {
        expect(TitleGeneratorService.generate(''), isNull);
      });
    });

    group('filler phrase removal', () {
      test('strips "so" filler from beginning', () {
        final title = TitleGeneratorService.generate(
            'So I need to pick up groceries later today.');
        expect(title, isNotNull);
        expect(title!.startsWith('So'), false);
        expect(title, contains('groceries'));
      });

      test('strips "okay" filler from beginning', () {
        final title = TitleGeneratorService.generate(
            'Okay the meeting is at three today.');
        expect(title, isNotNull);
        expect(title!.startsWith('Okay'), false);
      });

      test('strips "um" filler from beginning', () {
        final title = TitleGeneratorService.generate(
            'Um I have to finish the report by Friday.');
        expect(title, isNotNull);
        expect(title!.startsWith('Um'), false);
      });

      test('strips "remind me to" filler', () {
        final title = TitleGeneratorService.generate(
            'Remind me to call the dentist tomorrow morning.');
        expect(title, isNotNull);
        expect(title!.toLowerCase().startsWith('remind'), false);
      });

      test('strips stacked fillers', () {
        final title = TitleGeneratorService.generate(
            'So like I was thinking about the new project.');
        expect(title, isNotNull);
        // Should strip "so", "like", "I was thinking"
        expect(title!.toLowerCase().startsWith('so'), false);
      });
    });

    group('sentence extraction', () {
      test('uses first substantive sentence', () {
        final title = TitleGeneratorService.generate(
            'Ok. The quarterly review is scheduled for next Tuesday.');
        expect(title, isNotNull);
        expect(title, contains('quarterly'));
      });

      test('skips short sentences (<= 2 words)', () {
        final title = TitleGeneratorService.generate(
            'Yes. No. The project deadline has been moved to next month.');
        expect(title, isNotNull);
        expect(title, contains('project deadline'));
      });

      test('returns null when all sentences are too short', () {
        final title = TitleGeneratorService.generate('Hi. Ok. Bye.');
        expect(title, isNull);
      });
    });

    group('truncation', () {
      test('truncates long titles with ellipsis at word boundary', () {
        final title = TitleGeneratorService.generate(
            'The comprehensive quarterly business review meeting is scheduled for next Tuesday afternoon at three o clock in the large conference room on the second floor.');
        expect(title, isNotNull);
        expect(title!.length, lessThanOrEqualTo(63)); // 60 + "..."
        expect(title.endsWith('...'), true);
      });

      test('does not truncate short titles', () {
        final title = TitleGeneratorService.generate(
            'Buy eggs and milk from the store.');
        expect(title, isNotNull);
        expect(title!.endsWith('...'), false);
      });
    });

    group('trailing conjunction removal', () {
      test('removes trailing "and"', () {
        final title = TitleGeneratorService.generate(
            'Pick up the groceries and the dry cleaning and');
        expect(title, isNotNull);
        expect(title!.endsWith('and'), false);
      });
    });

    group('task-based fallback titles', () {
      test('falls back to first todo', () {
        final title = TitleGeneratorService.generate('ok',
            todos: ['Buy groceries']);
        expect(title, 'Tasks: Buy groceries');
      });

      test('falls back to first reminder if no todo', () {
        final title = TitleGeneratorService.generate('um',
            reminders: ['Dentist at 3pm']);
        expect(title, 'Reminder: Dentist at 3pm');
      });

      test('falls back to first action if no todo/reminder', () {
        final title = TitleGeneratorService.generate('uh',
            actions: ['Call John']);
        expect(title, 'Action: Call John');
      });

      test('prefers transcription over task fallback', () {
        final title = TitleGeneratorService.generate(
            'Schedule the team sync for Monday.',
            todos: ['Some todo']);
        expect(title, isNotNull);
        expect(title!.contains('Schedule'), true);
      });
    });

    group('capitalization', () {
      test('capitalizes first letter of title', () {
        final title = TitleGeneratorService.generate(
            'the meeting starts at noon today.');
        expect(title, isNotNull);
        expect(title![0], 'T');
      });
    });
  });
}
