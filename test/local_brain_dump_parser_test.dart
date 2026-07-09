import 'package:flutter_test/flutter_test.dart';
import 'package:flowos/features/ai/services/local_brain_dump_parser.dart';

void main() {
  group('LocalBrainDumpParser', () {
    test('splits raw text correctly by newlines and bullets', () {
      const dump = 'Need to write code for feature 45m\n• Call dentist; buy groceries';
      final tasks = LocalBrainDumpParser.parse(rawText: dump, currentEnergy: 3);

      expect(tasks.length, 3);
      expect(tasks[0].title, 'Need to write code for feature 45m');
      expect(tasks[1].title, 'Call dentist');
      expect(tasks[2].title, 'buy groceries');
    });

    test('truncates long titles to 60 characters', () {
      final longTitle = 'a' * 100;
      final tasks = LocalBrainDumpParser.parse(rawText: longTitle, currentEnergy: 3);

      expect(tasks.length, 1);
      expect(tasks.first.title.length, 60);
      expect(tasks.first.title.endsWith('...'), true);
    });

    test('applies energy level heuristics correctly', () {
      const dump = 'write code for hours\nsend email to boss\nrandom other task';
      final tasks = LocalBrainDumpParser.parse(rawText: dump, currentEnergy: 3);

      final codeTask = tasks.firstWhere((t) => t.title.contains('write code'));
      final emailTask = tasks.firstWhere((t) => t.title.contains('send email'));
      final randomTask = tasks.firstWhere((t) => t.title.contains('random other'));

      expect(codeTask.energyLevel, 'deep');
      expect(emailTask.energyLevel, 'light');
      expect(randomTask.energyLevel, 'medium');
    });

    test('parses estimated minutes correctly', () {
      const dump = 'Do research 45m\nWrite code 120m\nNo minutes specified';
      final tasks = LocalBrainDumpParser.parse(rawText: dump, currentEnergy: 3);

      final research = tasks.firstWhere((t) => t.title.contains('research'));
      final code = tasks.firstWhere((t) => t.title.contains('code'));
      final plain = tasks.firstWhere((t) => t.title.contains('plain') || t.title.contains('minutes'));

      expect(research.estimatedMinutes, 45);
      expect(code.estimatedMinutes, 120);
      expect(plain.estimatedMinutes, 25); // fallback default
    });

    test('sorts tasks based on high energy (deep first)', () {
      const dump = 'email boss\nresearch code';
      // Energy = 5 (High) -> Deep task first
      final tasks = LocalBrainDumpParser.parse(rawText: dump, currentEnergy: 5);

      expect(tasks.first.energyLevel, 'deep');
      expect(tasks.last.energyLevel, 'light');
    });

    test('sorts tasks based on low energy (light first)', () {
      const dump = 'research code\nemail boss';
      // Energy = 1 (Low) -> Light task first
      final tasks = LocalBrainDumpParser.parse(rawText: dump, currentEnergy: 1);

      expect(tasks.first.energyLevel, 'light');
      expect(tasks.last.energyLevel, 'deep');
    });
  });
}
