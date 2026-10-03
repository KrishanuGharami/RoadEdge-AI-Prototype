import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Technology badge for Qualcomm / Edge AI credentials
class TechBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isGlowing;

  const TechBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.isGlowing = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primaryCyan;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: effectiveColor.withOpacity(isGlowing ? 0.6 : 0.35),
          width: 1.2,
        ),
        boxShadow: isGlowing
            ? [
                BoxShadow(
                  color: effectiveColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: effectiveColor),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: AppTextStyles.badgeText.copyWith(color: effectiveColor),
          ),
        ],
      ),
    );
  }
}
