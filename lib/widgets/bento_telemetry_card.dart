import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_state.dart';
import '../theme/app_colors.dart';
import 'learning_insights_modal.dart';

class BentoTelemetryCard extends StatelessWidget {
  const BentoTelemetryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        final profile = state.userProfile;
        final percentage = (profile.vectorShiftMagnitude * 100).toInt();

        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.bentoCardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.bentoBorder, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x20000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.secondary.withAlpha(80)),
                        ),
                        child: const Icon(Icons.auto_awesome, size: 16, color: AppColors.secondary),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'AI Learning Loop',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 16, color: AppColors.textMuted),
                    tooltip: 'View Continuous Learning Insights',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => BlocProvider.value(
                          value: context.read<JobBloc>(),
                          child: const LearningInsightsModal(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Gauge & Stats Row
              Row(
                children: [
                  // Circular Progress Indicator
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: profile.vectorShiftMagnitude,
                          strokeWidth: 7,
                          backgroundColor: AppColors.surfaceElevated,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$percentage%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Shift',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Mini Stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dynamic Vector Shift',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Steers vector distance on every save, apply, or dismiss action.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStatBadge(Icons.bookmark_added_outlined, '${state.totalSavedCount}', 'Saved', AppColors.cyanAccent),
                            const SizedBox(width: 8),
                            _buildStatBadge(Icons.send_outlined, '${state.totalAppliedCount}', 'Applied', AppColors.matchHigh),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Learning CTA bar
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => BlocProvider.value(
                      value: context.read<JobBloc>(),
                      child: const LearningInsightsModal(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.insights, size: 14, color: AppColors.secondary),
                      SizedBox(width: 6),
                      Text(
                        'Explore Learning Insights',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBadge(IconData icon, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
