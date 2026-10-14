import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

enum ButtonVariant { primary, secondary, ghost, destructive }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.height = 48.0, // Strict 48dp minimum touch target
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDisabled = isDisabled || isLoading || onPressed == null;

    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case ButtonVariant.primary:
        bg = effectiveDisabled ? AppColors.border : AppColors.primary;
        fg = effectiveDisabled ? AppColors.textMuted : Colors.white;
        border = null;
        break;
      case ButtonVariant.secondary:
        bg = Colors.white;
        fg = effectiveDisabled ? AppColors.textMuted : AppColors.primary;
        border = BorderSide(
          color: effectiveDisabled ? AppColors.border : AppColors.primary,
          width: 1.5,
        );
        break;
      case ButtonVariant.destructive:
        bg = effectiveDisabled ? AppColors.border : AppColors.danger;
        fg = Colors.white;
        border = null;
        break;
      case ButtonVariant.ghost:
        bg = Colors.transparent;
        fg = effectiveDisabled ? AppColors.textMuted : AppColors.primary;
        border = null;
        break;
    }

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          onTap: effectiveDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: border != null ? Border.fromBorderSide(border) : null,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(fg),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: fg),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: AppTextStyles.button.copyWith(color: fg),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
