import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class ScoreRing extends StatelessWidget {
  final int score; // 0 to 100
  final double size;
  final double strokeWidth;

  const ScoreRing({
    super.key,
    required this.score,
    this.size = 54,
    this.strokeWidth = 4.5,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (score / 100.0).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE2E8F0)),
            ),
          ),
          // Active progress arc
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) {
                return CircularProgressIndicator(
                  value: val,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                );
              },
            ),
          ),
          // Score Label
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score%',
                style: AppTextStyles.captionBold.copyWith(
                  fontSize: size * 0.26,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                'Match',
                style: AppTextStyles.caption.copyWith(
                  fontSize: size * 0.17,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
