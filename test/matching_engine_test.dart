import 'package:flutter_test/flutter_test.dart';
import 'package:skill_swap_flutter/core/utils/matching_engine.dart';

void main() {
  group('MatchingEngine Tests (PRD Section 5)', () {
    test('Calculates perfect mutual match correctly', () {
      final result = MatchingEngine.calculateMatch(
        myTeachSkills: ['Python', 'SQL'],
        myLearnSkills: ['Figma', 'UI/UX'],
        theirTeachSkills: ['Figma', 'UI/UX'],
        theirLearnSkills: ['Python', 'SQL'],
      );

      expect(result.score, 100);
      expect(result.isMutual, isTrue);
      expect(result.teachesYou.length, 2);
      expect(result.wantsFromYou.length, 2);
    });

    test('Case-insensitivity and whitespace trimming work', () {
      final result = MatchingEngine.calculateMatch(
        myTeachSkills: ['  python '],
        myLearnSkills: ['FIGMA'],
        theirTeachSkills: ['figma '],
        theirLearnSkills: ['PYTHON'],
      );

      expect(result.score, 100);
      expect(result.isMutual, isTrue);
    });

    test('Zero overlap returns score 0', () {
      final result = MatchingEngine.calculateMatch(
        myTeachSkills: ['Java'],
        myLearnSkills: ['C++'],
        theirTeachSkills: ['Python'],
        theirLearnSkills: ['Rust'],
      );

      expect(result.score, 0);
      expect(result.isMutual, isFalse);
    });
  });
}
