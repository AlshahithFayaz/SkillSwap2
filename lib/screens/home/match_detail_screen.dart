import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/matching_engine.dart';
import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/score_ring.dart';
import '../../widgets/skill_chip.dart';

class MatchDetailScreen extends StatelessWidget {
  final UserModel candidate;
  final MatchCalculationResult matchResult;

  const MatchDetailScreen({
    super.key,
    required this.candidate,
    required this.matchResult,
  });

  String get initials {
    final parts = candidate.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return candidate.name.isNotEmpty ? candidate.name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final requestProvider = Provider.of<RequestProvider>(context);
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final currentUser = authProvider.currentUser;

    final isSent = currentUser != null &&
        requestProvider.isRequestSent(currentUser.id, candidate.id);
    final isConnected = currentUser != null &&
        requestProvider.isConnected(currentUser.id, candidate.id);

    final reviews = reviewProvider.getReviewsForUser(candidate.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                            child: Text(
                              initials,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.primary,
                                fontSize: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(candidate.name, style: AppTextStyles.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            '${candidate.department} • ${candidate.year} Year',
                            style: AppTextStyles.bodyMediumSecondary,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star_rounded, size: 20, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 4),
                              Text(
                                candidate.ratingAvg.toStringAsFixed(1),
                                style: AppTextStyles.heading.copyWith(fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${candidate.ratingCount} reviews)',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Compatibility Breakdown Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          ScoreRing(score: matchResult.score, size: 64, strokeWidth: 5.5),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Compatibility Breakdown', style: AppTextStyles.subheading),
                                const SizedBox(height: 4),
                                Text(
                                  matchResult.isMutual
                                      ? 'Mutual exchange! Both of you have skills the other wants.'
                                      : 'One-directional swap opportunity.',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Skill Overlaps
                    if (matchResult.teachesYou.isNotEmpty) ...[
                      _buildSkillGroup(
                        title: 'They Teach You (${matchResult.teachesYou.length})',
                        skills: matchResult.teachesYou,
                        type: SkillChipType.teach,
                        icon: Icons.school_outlined,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (matchResult.wantsFromYou.isNotEmpty) ...[
                      _buildSkillGroup(
                        title: 'They Want From You (${matchResult.wantsFromYou.length})',
                        skills: matchResult.wantsFromYou,
                        type: SkillChipType.learn,
                        icon: Icons.lightbulb_outline,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // All skills they teach
                    _buildSkillGroup(
                      title: 'All Skills They Teach',
                      skills: candidate.teachSkills,
                      type: SkillChipType.teach,
                      icon: Icons.check_circle_outline,
                    ),
                    const SizedBox(height: 16),

                    // All skills they learn
                    _buildSkillGroup(
                      title: 'All Skills They Want to Learn',
                      skills: candidate.learnSkills,
                      type: SkillChipType.learn,
                      icon: Icons.search,
                    ),
                    const SizedBox(height: 24),

                    // Reviews List
                    Text('Student Reviews', style: AppTextStyles.subheading),
                    const SizedBox(height: 10),
                    if (reviews.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'No written reviews yet for this student.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                        ),
                      )
                    else
                      ...reviews.map((r) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ...List.generate(
                                      5,
                                      (idx) => Icon(
                                        idx < r.stars ? Icons.star_rounded : Icons.star_border_rounded,
                                        size: 16,
                                        color: const Color(0xFFF59E0B),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      r.reviewerName ?? 'Anonymous Peer',
                                      style: AppTextStyles.captionBold,
                                    ),
                                  ],
                                ),
                                if (r.comment.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(r.comment, style: AppTextStyles.body),
                                ],
                              ],
                            ),
                          )),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: AppColors.border)),
              ),
              child: CustomButton(
                text: isConnected
                    ? 'Connected Partner'
                    : isSent
                        ? 'Request Sent'
                        : 'Connect & Swap',
                icon: isConnected
                    ? Icons.handshake
                    : isSent
                        ? Icons.check
                        : Icons.swap_horiz_rounded,
                isDisabled: isSent || isConnected,
                variant: isConnected || isSent ? ButtonVariant.secondary : ButtonVariant.primary,
                onPressed: () {
                  if (currentUser != null) {
                    requestProvider.sendRequest(
                      fromUser: currentUser,
                      toUser: candidate,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Swap request sent to ${candidate.name}!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillGroup({
    required String title,
    required List<String> skills,
    required SkillChipType type,
    required IconData icon,
  }) {
    final color = type == SkillChipType.teach ? AppColors.teach : AppColors.learn;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.subheading.copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: skills.map((s) => SkillChip(label: s, type: type)).toList(),
          ),
        ],
      ),
    );
  }
}
