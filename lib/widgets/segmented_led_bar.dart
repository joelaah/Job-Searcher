import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Discrete LED indicator bar mimicking tactical HUD biometrics.
/// Features discrete segmented cells, 8px height, 4px gaps, 2px radius, and active neon glows.
class SegmentedLedBar extends StatelessWidget {
  final int totalSegments;
  final int? filledSegments;
  final double? percentage;
  final Color activeColor;
  final Color inactiveColor;
  final double height;
  final double gap;
  final double borderRadius;
  final bool hasGlow;

  const SegmentedLedBar({
    super.key,
    this.totalSegments = 10,
    this.filledSegments,
    this.percentage,
    this.activeColor = AppColors.secondary,
    this.inactiveColor = AppColors.surfaceContainerHighest,
    this.height = 8.0,
    this.gap = 4.0,
    this.borderRadius = 2.0,
    this.hasGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    int activeCount = 0;
    double partialOpacity = 0.0;

    if (filledSegments != null) {
      activeCount = filledSegments!.clamp(0, totalSegments);
    } else if (percentage != null) {
      final normalized = percentage!.clamp(0.0, 100.0);
      final raw = (normalized / (100.0 / totalSegments));
      activeCount = raw.floor().clamp(0, totalSegments);
      final remainder = raw - activeCount;
      if (remainder > 0.25 && activeCount < totalSegments) {
        partialOpacity = remainder.clamp(0.3, 0.7);
      }
    } else {
      activeCount = totalSegments;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0;

        return SizedBox(
          width: constraints.maxWidth.isFinite ? null : availableWidth,
          height: height,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: List.generate(totalSegments, (index) {
              final isFullActive = index < activeCount;
              final isPartial = !isFullActive && index == activeCount && partialOpacity > 0;

              Color cellColor;
              List<BoxShadow>? shadows;

              if (isFullActive) {
                cellColor = activeColor;
                if (hasGlow) {
                  shadows = [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.6),
                      blurRadius: 6,
                      spreadRadius: 0.5,
                    ),
                  ];
                }
              } else if (isPartial) {
                cellColor = activeColor.withValues(alpha: partialOpacity);
                shadows = null;
              } else {
                cellColor = inactiveColor;
                shadows = null;
              }

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < totalSegments - 1 ? gap : 0,
                  ),
                  height: height,
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: shadows,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
