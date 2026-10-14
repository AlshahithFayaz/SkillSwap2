import 'package:flutter_test/flutter_test.dart';
import 'package:skill_swap_flutter/core/utils/matching_engine.dart';

void main() {
  test('Smoke test verifying core matching engine', () {
    final result = MatchingEngine.calculateMatch(
      myTeachSkills: ['Python'],
      myLearnSkills: ['Figma'],
      theirTeachSkills: ['Figma'],
      theirLearnSkills: ['Python'],
    );
    expect(result.score, 100);
  });
}
