import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_state.dart';
import '../theme/app_colors.dart';

class BentoMarketInsightsCard extends StatelessWidget {
  const BentoMarketInsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        final jobs = state.filteredJobs;
        
        // Extract top recurring tags/skills across matching jobs
        final tagCounts = <String, int>{};
        for (var job in jobs) {
          for (var tag in job.tags) {
            tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
          }
        }
        final sortedSkills = tagCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topSkills = sortedSkills.take(6).map((e) => e.key).toList();

        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.bentoCardGradient,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.bentoBorder, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.cyanAccent.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cyanAccent.withAlpha(70)),
                            ),
                            child: const Icon(Icons.radar, size: 16, color: AppColors.cyanAccent),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Market Radar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Live Signals',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // In-demand skills
                  const Text(
                    'High-Frequency Stack Requirements:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (topSkills.isNotEmpty ? topSkills : ['PostgreSQL', 'Flutter', 'pgvector', 'Docker', 'Python', 'FastAPI'])
                        .map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up, size: 11, color: AppColors.matchHigh),
                            const SizedBox(width: 4),
                            Text(
                              skill,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // AI Strategy Tip Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha(160),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates_outlined, size: 15, color: AppColors.secondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Highlight pgvector & vector DB indexing on your resume to boost match scores by up to +14%.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
