import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// 5-dot LED matrix indicator for interview difficulty levels with HUD typography.
class DifficultyGauntletDots extends StatelessWidget {
  final int rating;
  final int maxDots;
  final String? label;
  final Color? activeColor;
  final Color inactiveColor;
  final double dotSize;
  final double gap;
  final bool showLabel;

  const DifficultyGauntletDots({
    super.key,
    required this.rating,
    this.maxDots = 5,
    this.label,
    this.activeColor,
    this.inactiveColor = AppColors.surfaceVariant,
    this.dotSize = 6.0,
    this.gap = 3.0,
    this.showLabel = true,
  });

  String _getDefaultLabel(int rate) {
    if (rate >= 5) return 'INTENSE';
    if (rate >= 4) return 'HARD';
    if (rate >= 3) return 'MEDIUM';
    return 'STANDARD';
  }

  Color _resolveColor(int rate) {
    if (activeColor != null) return activeColor!;
    if (rate >= 5) return AppColors.error;
    if (rate >= 4) return AppColors.secondary;
    if (rate >= 3) return AppColors.tertiary;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final clampedRating = rating.clamp(0, maxDots);
    final color = _resolveColor(clampedRating);
    final textLabel = label ?? _getDefaultLabel(clampedRating);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showLabel) ...[
          Text(
            textLabel,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxDots, (index) {
            final isActive = index < clampedRating;
            return Container(
              margin: EdgeInsets.only(right: index < maxDots - 1 ? gap : 0),
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color : inactiveColor,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}
