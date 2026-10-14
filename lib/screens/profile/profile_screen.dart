import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/skill_chip.dart';
import '../auth/login_screen.dart';
import '../auth/skill_onboarding_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final reviews = reviewProvider.getReviewsForUser(user.id);
    final initials = user.name.trim().isNotEmpty
        ? user.name.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            tooltip: 'Log out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log out'),
                  content: const Text('Are you sure you want to log out of SkillSwap?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Log out', style: TextStyle(color: AppColors.danger)),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await authProvider.logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Info Card
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
                    Text(user.name, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 4),
                    Text(user.email, style: AppTextStyles.bodyMediumSecondary),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Roll No: ${user.rollNo}', style: AppTextStyles.captionBold),
                          const SizedBox(width: 12),
                          const Text('•', style: TextStyle(color: AppColors.textMuted)),
                          const SizedBox(width: 12),
                          Text(
                            '${user.department} (${user.year})',
                            style: AppTextStyles.captionBold,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded, size: 20, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          user.ratingAvg.toStringAsFixed(1),
                          style: AppTextStyles.heading.copyWith(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${user.ratingCount} reviews)',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Skills I Teach Card
              Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.school_outlined, size: 18, color: AppColors.teach),
                            const SizedBox(width: 8),
                            Text('Skills I Teach', style: AppTextStyles.subheading),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SkillOnboardingScreen(
                                  isEditingProfile: true,
                                  initialSection: SkillChipType.teach,
                                ),
                              ),
                            );
                          },
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    user.teachSkills.isEmpty
                        ? Text('No teaching skills added yet', style: AppTextStyles.caption)
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: user.teachSkills
                                .map((s) => SkillChip(label: s, type: SkillChipType.teach))
                                .toList(),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Skills I Want to Learn Card
              Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.learn),
                            const SizedBox(width: 8),
                            Text('Skills I Want to Learn', style: AppTextStyles.subheading),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SkillOnboardingScreen(
                                  isEditingProfile: true,
                                  initialSection: SkillChipType.learn,
                                ),
                              ),
                            );
                          },
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    user.learnSkills.isEmpty
                        ? Text('No learning skills added yet', style: AppTextStyles.caption)
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: user.learnSkills
                                .map((s) => SkillChip(label: s, type: SkillChipType.learn))
                                .toList(),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Received Reviews Section
              Text('Reviews Received', style: AppTextStyles.subheading),
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
                    'No reviews yet. Complete skill swap sessions to earn ratings from peers!',
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
              const SizedBox(height: 24),

              // Edit Skills CTA
              CustomButton(
                text: 'Update Skill Inventory',
                variant: ButtonVariant.secondary,
                icon: Icons.edit_note_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SkillOnboardingScreen(isEditingProfile: true),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
