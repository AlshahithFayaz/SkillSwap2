import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../data/models/exchange_request_model.dart';

class StatusBadge extends StatelessWidget {
  final RequestStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;
    String label;
    IconData icon;

    switch (status) {
      case RequestStatus.accepted:
        bg = AppColors.successBg;
        fg = AppColors.success;
        border = const Color(0xFFBBF7D0);
        label = 'Accepted';
        icon = Icons.check_circle_outline;
        break;
      case RequestStatus.rejected:
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        border = const Color(0xFFFECACA);
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;
      case RequestStatus.pending:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        border = const Color(0xFFFDE68A);
        label = 'Pending';
        icon = Icons.hourglass_empty;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.captionBold.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
