import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum BadgeType {
  breakfast,
  lunch,
  dinner,
  success,
  warning,
  danger,
  info,
  published,
  draft,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case BadgeType.breakfast:
        bg = AppColors.breakfast.withOpacity(0.15);
        fg = const Color(0xFFB45309);
        break;
      case BadgeType.lunch:
        bg = AppColors.lunch.withOpacity(0.15);
        fg = const Color(0xFF047857);
        break;
      case BadgeType.dinner:
        bg = AppColors.dinner.withOpacity(0.15);
        fg = const Color(0xFF4338CA);
        break;
      case BadgeType.success:
      case BadgeType.published:
        bg = AppColors.successSubtle;
        fg = const Color(0xFF065F46);
        break;
      case BadgeType.warning:
      case BadgeType.draft:
        bg = AppColors.warningSubtle;
        fg = const Color(0xFF92400E);
        break;
      case BadgeType.danger:
        bg = AppColors.dangerSubtle;
        fg = const Color(0xFF991B1B);
        break;
      case BadgeType.info:
        bg = AppColors.infoSubtle;
        fg = const Color(0xFF1E40AF);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
