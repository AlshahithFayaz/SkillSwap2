import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

enum SkillChipType { teach, learn }

class SkillChip extends StatelessWidget {
  final String label;
  final SkillChipType type;
  final bool isRemovable;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  final bool isSelected;

  const SkillChip({
    super.key,
    required this.label,
    required this.type,
    this.isRemovable = false,
    this.onRemove,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTeach = type == SkillChipType.teach;
    final textColor = isTeach ? AppColors.teach : AppColors.learn;
    final bgColor = isTeach ? AppColors.teachBg : AppColors.learnBg;
    final borderColor = isTeach ? AppColors.teachBorder : AppColors.learnBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: isRemovable ? 6 : 7,
          ),
          decoration: BoxDecoration(
            color: isSelected ? textColor : bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? textColor : borderColor,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Small indicator dot for high contrast clarity
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white : textColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.captionBold.copyWith(
                  color: isSelected ? Colors.white : textColor,
                ),
              ),
              if (isRemovable) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onRemove,
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: isSelected ? Colors.white : textColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
