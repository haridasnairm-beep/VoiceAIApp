import 'package:flutter_test/flutter_test.dart';
import 'package:voicenotes_ai/utils/profanity_filter.dart';

void main() {
  final filter = ProfanityFilter.instance;

  group('ProfanityFilter', () {
    group('basic filtering', () {
      test('replaces profane word with asterisks', () {
        expect(filter.filter('that is bullshit'), 'that is ********');
      });

      test('replaces multiple profane words', () {
        final result = filter.filter('what the hell is this crap');
        expect(result.contains('hell'), false);
        expect(result.contains('crap'), false);
        expect(result.contains('****'), true);
      });

      test('preserves non-profane words', () {
        expect(filter.filter('hello world'), 'hello world');
      });

      test('returns empty string for empty input', () {
        expect(filter.filter(''), '');
      });
    });

    group('whole-word matching', () {
      test('does not filter "class" (contains "ass")', () {
        expect(filter.filter('I went to class today'), 'I went to class today');
      });

      test('does not filter "assess" (contains "ass")', () {
        expect(filter.filter('please assess the situation'),
            'please assess the situation');
      });

      test('does not filter "shell" (contains "hell")', () {
        expect(filter.filter('the shell is broken'), 'the shell is broken');
      });

      test('does not filter "scrap" (contains "crap")', () {
        expect(filter.filter('scrap the old plan'), 'scrap the old plan');
      });
    });

    group('case insensitivity', () {
      test('filters uppercase profanity', () {
        final result = filter.filter('that is DAMN annoying');
        expect(result.contains('DAMN'), false);
        expect(result.contains('****'), true);
      });

      test('filters mixed case profanity', () {
        final result = filter.filter('what the Hell');
        expect(result.contains('Hell'), false);
      });
    });

    group('asterisk length', () {
      test('asterisk count matches word length', () {
        // "damn" = 4 chars → "****"
        expect(filter.filter('damn'), '****');
      });

      test('longer word gets more asterisks', () {
        // "bullshit" = 8 chars → "********"
        expect(filter.filter('bullshit'), '********');
      });
    });

    group('enabled flag', () {
      test('returns original text when disabled', () {
        expect(
            filter.filter('what the hell', enabled: false), 'what the hell');
      });

      test('filters when enabled (default)', () {
        final result = filter.filter('what the hell');
        expect(result.contains('hell'), false);
      });
    });
  });
}
