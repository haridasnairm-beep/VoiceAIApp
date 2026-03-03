import 'package:flutter_test/flutter_test.dart';
import 'package:voicenotes_ai/utils/voice_command_parser.dart';

void main() {
  group('VoiceCommandParser', () {
    group('No command keywords', () {
      test('returns full text when no keywords present', () {
        final result = VoiceCommandParser.parse('buy groceries tomorrow');
        expect(result.hasCommand, false);
        expect(result.noteContent, 'buy groceries tomorrow');
        expect(result.folderName, isNull);
        expect(result.projectName, isNull);
        expect(result.tagNames, isEmpty);
      });

      test('returns empty string for empty input', () {
        final result = VoiceCommandParser.parse('');
        expect(result.hasCommand, false);
        expect(result.noteContent, '');
      });

      test('returns trimmed text for whitespace input', () {
        final result = VoiceCommandParser.parse('   ');
        expect(result.hasCommand, false);
        expect(result.noteContent, '');
      });
    });

    group('"Start" keyword', () {
      test('strips "Start" prefix and returns content', () {
        final result = VoiceCommandParser.parse('Start buy milk');
        expect(result.hasCommand, true);
        expect(result.noteContent, 'buy milk');
      });

      test('case-insensitive Start', () {
        final result = VoiceCommandParser.parse('start my note here');
        expect(result.hasCommand, true);
        expect(result.noteContent, 'my note here');
      });
    });

    group('Folder keyword', () {
      test('extracts folder name before Start', () {
        final result =
            VoiceCommandParser.parse('Folder Kitchen Start buy groceries');
        expect(result.hasCommand, true);
        expect(result.folderName, 'Kitchen');
        expect(result.noteContent, 'buy groceries');
      });

      test('extracts multi-word folder name', () {
        final result = VoiceCommandParser.parse(
            'Folder My Work Notes Start important meeting');
        expect(result.folderName, 'My Work Notes');
        expect(result.noteContent, 'important meeting');
      });

      test('case-insensitive folder keyword', () {
        final result =
            VoiceCommandParser.parse('folder recipes Start pasta sauce');
        expect(result.folderName, 'recipes');
        expect(result.noteContent, 'pasta sauce');
      });
    });

    group('Project keyword', () {
      test('extracts project name before Start', () {
        final result = VoiceCommandParser.parse(
            'Project Thesis Start chapter one notes');
        expect(result.projectName, 'Thesis');
        expect(result.noteContent, 'chapter one notes');
      });
    });

    group('Tag keyword', () {
      test('extracts single tag', () {
        final result =
            VoiceCommandParser.parse('Tag urgent Start fix the bug');
        expect(result.tagNames, ['urgent']);
        expect(result.noteContent, 'fix the bug');
      });

      test('extracts multiple tags', () {
        final result = VoiceCommandParser.parse(
            'Tag budget Tag urgent Start need to pay rent');
        expect(result.tagNames, containsAll(['budget', 'urgent']));
        expect(result.noteContent, 'need to pay rent');
      });

      test('tags are lowercase normalized', () {
        final result =
            VoiceCommandParser.parse('Tag IMPORTANT Start do the thing');
        expect(result.tagNames, ['important']);
      });
    });

    group('Combined keywords', () {
      test('folder + tag + start', () {
        final result = VoiceCommandParser.parse(
            'Folder Kitchen Tag grocery Start buy eggs and milk');
        expect(result.folderName, 'Kitchen');
        expect(result.tagNames, ['grocery']);
        expect(result.noteContent, 'buy eggs and milk');
      });

      test('folder + project + start', () {
        final result = VoiceCommandParser.parse(
            'Folder Work Project MVP Start design the login page');
        expect(result.folderName, 'Work');
        expect(result.projectName, 'MVP');
        expect(result.noteContent, 'design the login page');
      });

      test('folder + multiple tags + start', () {
        final result = VoiceCommandParser.parse(
            'Folder Home Tag budget Tag urgent Tag monthly Start pay electricity bill');
        expect(result.folderName, 'Home');
        expect(result.tagNames, containsAll(['budget', 'urgent', 'monthly']));
        expect(result.noteContent, 'pay electricity bill');
      });
    });

    group('Task keywords', () {
      test('todo keyword as delimiter', () {
        final result = VoiceCommandParser.parse('Todo buy groceries');
        expect(result.hasCommand, true);
        expect(result.taskType, 'todo');
        expect(result.taskDescription, 'buy groceries');
        expect(result.noteContent, 'buy groceries');
      });

      test('action keyword', () {
        final result = VoiceCommandParser.parse('Action call the plumber');
        expect(result.taskType, 'action');
        expect(result.noteContent, 'call the plumber');
      });

      test('reminder keyword', () {
        final result = VoiceCommandParser.parse('Reminder dentist appointment');
        expect(result.taskType, 'reminder');
        expect(result.noteContent, 'dentist appointment');
      });

      test('to do (two words) normalized to todo', () {
        final result = VoiceCommandParser.parse('to do fix the fence');
        expect(result.taskType, 'todo');
        expect(result.noteContent, 'fix the fence');
      });

      test('to-do (hyphenated) normalized to todo', () {
        final result = VoiceCommandParser.parse('to-do wash the car');
        expect(result.taskType, 'todo');
        expect(result.noteContent, 'wash the car');
      });

      test('folder + task keyword + start', () {
        final result = VoiceCommandParser.parse(
            'Folder Kitchen Todo Start buy eggs');
        expect(result.folderName, 'Kitchen');
        expect(result.taskType, 'todo');
        expect(result.noteContent, 'buy eggs');
      });

      test('task description truncated to 30 chars', () {
        final result = VoiceCommandParser.parse(
            'Todo this is a very long task description that should be truncated');
        expect(result.taskDescription!.length, 30);
      });
    });

    group('Whisper punctuation handling', () {
      test('strips trailing period from keyword match', () {
        final result =
            VoiceCommandParser.parse('Folder. Kitchen Start buy milk');
        // "Folder." with period should still match after stripping punctuation
        expect(result.folderName, 'Kitchen');
      });

      test('strips trailing comma from name words', () {
        final result = VoiceCommandParser.parse(
            'Folder Kitchen, Start buy groceries');
        expect(result.folderName, 'Kitchen');
      });
    });
  });
}
