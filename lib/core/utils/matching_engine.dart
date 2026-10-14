import 'dart:math';

class MatchCalculationResult {
  final int score; // 0 to 100
  final List<String> teachesYou; // their.teach ∩ my.learn (skills they can teach me)
  final List<String> wantsFromYou; // their.learn ∩ my.teach (skills they want from me)
  final bool isMutual; // both teachMatch > 0 and learnMatch > 0

  const MatchCalculationResult({
    required this.score,
    required this.teachesYou,
    required this.wantsFromYou,
    required this.isMutual,
  });
}

class MatchingEngine {
  /// Normalizes a skill string for comparison (trimmed and lowercase).
  static String normalizeSkill(String skill) {
    return skill.trim().toLowerCase();
  }

  /// Calculates the compatibility between the current user and a candidate peer.
  ///
  /// teachMatch = |their.teach ∩ my.learn| / max(|my.learn|, 1)
  /// learnMatch = |their.learn ∩ my.teach| / max(|their.learn|, 1)
  /// score = round( (0.5 * teachMatch + 0.5 * learnMatch) * 100 )
  static MatchCalculationResult calculateMatch({
    required List<String> myTeachSkills,
    required List<String> myLearnSkills,
    required List<String> theirTeachSkills,
    required List<String> theirLearnSkills,
  }) {
    final myTeachNormalized = myTeachSkills.map(normalizeSkill).toSet();
    final myLearnNormalized = myLearnSkills.map(normalizeSkill).toSet();

    // Map normalized back to original presentation casing
    final theirTeachMap = {
      for (final s in theirTeachSkills) normalizeSkill(s): s
    };
    final theirLearnMap = {
      for (final s in theirLearnSkills) normalizeSkill(s): s
    };

    // their.teach ∩ my.learn (what they can teach me)
    final teachesYouNormalized = theirTeachMap.keys.toSet().intersection(myLearnNormalized);
    final teachesYou = teachesYouNormalized.map((k) => theirTeachMap[k]!).toList();

    // their.learn ∩ my.teach (what they want from me)
    final wantsFromYouNormalized = theirLearnMap.keys.toSet().intersection(myTeachNormalized);
    final wantsFromYou = wantsFromYouNormalized.map((k) => theirLearnMap[k]!).toList();

    final teachMatch = teachesYou.length / max(myLearnSkills.length, 1);
    final learnMatch = wantsFromYou.length / max(theirLearnSkills.length, 1);

    final rawScore = ((0.5 * teachMatch + 0.5 * learnMatch) * 100).round();
    final score = rawScore.clamp(0, 100);

    final isMutual = teachesYou.isNotEmpty && wantsFromYou.isNotEmpty;

    return MatchCalculationResult(
      score: score,
      teachesYou: teachesYou,
      wantsFromYou: wantsFromYou,
      isMutual: isMutual,
    );
  }
}
