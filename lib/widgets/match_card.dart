import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/matching_engine.dart';
import '../data/models/user_model.dart';
import 'score_ring.dart';
import 'skill_chip.dart';
import 'custom_button.dart';

class MatchCard extends StatelessWidget {
  final UserModel candidate;
  final MatchCalculationResult matchResult;
  final bool isRequestSent;
  final VoidCallback onConnect;
  final VoidCallback onTap;

  const MatchCard({
    super.key,
    required this.candidate,
    required this.matchResult,
    required this.isRequestSent,
    required this.onConnect,
    required this.onTap,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Avatar, Info, and Compatibility Score Ring
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with initials fallback
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        initials,
                        style: AppTextStyles.heading.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name, Department & Rating
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            candidate.name,
                            style: AppTextStyles.heading,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${candidate.department} • ${candidate.year} Year',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Rating star
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 3),
                              Text(
                                candidate.ratingAvg.toStringAsFixed(1),
                                style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${candidate.ratingCount})',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Circular Match Score Ring
                    ScoreRing(score: matchResult.score),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Teaches you chips (Green)
                if (matchResult.teachesYou.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.school_outlined, size: 14, color: AppColors.teach),
                      const SizedBox(width: 6),
                      Text(
                        'Teaches you:',
                        style: AppTextStyles.captionBold.copyWith(color: AppColors.teach),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: matchResult.teachesYou.map((skill) {
                      return SkillChip(
                        label: skill,
                        type: SkillChipType.teach,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Wants from you chips (Amber)
                if (matchResult.wantsFromYou.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.learn),
                      const SizedBox(width: 6),
                      Text(
                        'Wants from you:',
                        style: AppTextStyles.captionBold.copyWith(color: AppColors.learn),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: matchResult.wantsFromYou.map((skill) {
                      return SkillChip(
                        label: skill,
                        type: SkillChipType.learn,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Connect & Swap Button
                CustomButton(
                  text: isRequestSent ? 'Request Sent' : 'Connect & Swap',
                  icon: isRequestSent ? Icons.check : Icons.swap_horiz_rounded,
                  onPressed: isRequestSent ? null : onConnect,
                  variant: isRequestSent ? ButtonVariant.secondary : ButtonVariant.primary,
                  isDisabled: isRequestSent,
                  height: 44,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
