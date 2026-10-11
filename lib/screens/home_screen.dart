import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../bloc/job_state.dart';
import '../models/job_model.dart';
import '../theme/app_colors.dart';
import '../widgets/nav_header.dart';
import '../widgets/bento_profile_card.dart';
import '../widgets/bento_telemetry_card.dart';
import '../widgets/bento_pipeline_card.dart';
import '../widgets/bento_filter_strip.dart';
import '../widgets/ai_learning_loop_section.dart';
import '../widgets/bento_hero_job_card.dart';
import '../widgets/bento_market_insights_card.dart';
import '../widgets/bento_job_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        final filteredJobs = state.filteredJobs;
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 1100;
        final isTablet = screenWidth >= 740 && screenWidth < 1100;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Ambient Spotlights (Raycast/Linear aesthetic)
              Positioned(
                top: -120,
                left: screenWidth * 0.15,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withAlpha(22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 450,
                right: -100,
                child: Container(
                  width: 550,
                  height: 550,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary.withAlpha(20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 200,
                left: -80,
                child: Container(
                  width: 450,
                  height: 450,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.cyanAccent.withAlpha(16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main Application Content
              Column(
                children: [
                  const NavHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 48 : (isTablet ? 24 : 16),
                        vertical: 24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1380),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          // ══════════════════════════════════════════
                          // 1. TOP BENTO DECK: Profile, Telemetry & Pipeline
                          // ══════════════════════════════════════════
                          _buildTopBentoDeck(context, state, isDesktop, isTablet),

                          const SizedBox(height: 18),

                          // ══════════════════════════════════════════
                          // 2. BENTO FILTER & SEARCH STRIP
                          // ══════════════════════════════════════════
                          const BentoFilterStrip(),

                          const SizedBox(height: 24),

                          // ══════════════════════════════════════════
                          // 3. AI LEARNING LOOP SECTION (1000x Better)
                          // ══════════════════════════════════════════
                          const AiLearningLoopSection(),

                          const SizedBox(height: 28),

                          // ══════════════════════════════════════════
                          // 4. RESULTS STATUS & SIMILARITY BADGE
                          // ══════════════════════════════════════════
                          _buildResultsHeader(filteredJobs.length, state.minMatchScore),

                          const SizedBox(height: 18),

                          // ══════════════════════════════════════════
                          // 4. BENTO JOBS SHOWCASE
                          // ══════════════════════════════════════════
                          if (filteredJobs.isEmpty)
                            _buildEmptyBentoCard(context)
                          else ...[
                            // Featured Deck: #1 Top Match + Market Radar Bento
                            _buildFeaturedBentoDeck(filteredJobs.first, isDesktop),

                            // Remaining Bento Jobs Grid
                            if (filteredJobs.length > 1) ...[
                              const SizedBox(height: 20),
                              _buildBentoJobsGrid(
                                filteredJobs.sublist(1),
                                isDesktop ? 3 : (isTablet ? 2 : 1),
                              ),
                            ],
                          ],

                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  },
);
}

  // ──────────────────── Top Bento Deck ────────────────────

  Widget _buildTopBentoDeck(BuildContext context, JobState state, bool isDesktop, bool isTablet) {
    if (isDesktop) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tile 1: AI Semantic Profile & Resume (Wide Span)
          Expanded(
            flex: 5,
            child: BentoProfileCard(),
          ),
          SizedBox(width: 18),

          // Tile 2: AI Learning Telemetry (Metric Span)
          Expanded(
            flex: 3,
            child: BentoTelemetryCard(),
          ),
          SizedBox(width: 18),

          // Tile 3: Pipeline & Cloud Status (Action Span)
          Expanded(
            flex: 3,
            child: BentoPipelineCard(),
          ),
        ],
      );
    }

    if (isTablet) {
      return const Column(
        children: [
          BentoProfileCard(),
          SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: BentoTelemetryCard()),
              SizedBox(width: 16),
              Expanded(child: BentoPipelineCard()),
            ],
          ),
        ],
      );
    }

    // Mobile layout
    return const Column(
      children: [
        BentoProfileCard(),
        SizedBox(height: 14),
        BentoTelemetryCard(),
        SizedBox(height: 14),
        BentoPipelineCard(),
      ],
    );
  }

  // ──────────────────── Featured Bento Deck ────────────────────

  Widget _buildFeaturedBentoDeck(JobModel topJob, bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Double-width Bento Hero Card
          Expanded(
            flex: 7,
            child: BentoHeroJobCard(job: topJob),
          ),
          const SizedBox(width: 18),

          // Market Radar Insights Card
          const Expanded(
            flex: 4,
            child: BentoMarketInsightsCard(),
          ),
        ],
      );
    }

    return Column(
      children: [
        BentoHeroJobCard(job: topJob),
        const SizedBox(height: 18),
        const BentoMarketInsightsCard(),
      ],
    );
  }

  // ──────────────────── Results Header ────────────────────

  Widget _buildResultsHeader(int matchCount, int minScore) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withAlpha(70)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hub_outlined, size: 13, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '$matchCount Ranked Matches',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Min Threshold: $minScore%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort, size: 13, color: AppColors.secondary),
                SizedBox(width: 5),
                Text(
                  'Cosine Similarity (pgvector)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────── Bento Jobs Grid ────────────────────

  Widget _buildBentoJobsGrid(List<JobModel> jobs, int columns) {
    if (columns == 1) {
      return Column(
        children: jobs.map((job) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: BentoJobCard(job: job),
          );
        }).toList(),
      );
    }

    if (columns == 2) {
      return Column(
        children: [
          for (int i = 0; i < jobs.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: BentoJobCard(job: jobs[i])),
                  const SizedBox(width: 18),
                  Expanded(
                    child: (i + 1 < jobs.length)
                        ? BentoJobCard(job: jobs[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    // 3 Columns Grid for Wide Displays
    return Column(
      children: [
        for (int i = 0; i < jobs.length; i += 3)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: BentoJobCard(job: jobs[i])),
                const SizedBox(width: 18),
                Expanded(
                  child: (i + 1 < jobs.length)
                      ? BentoJobCard(job: jobs[i + 1])
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: (i + 2 < jobs.length)
                      ? BentoJobCard(job: jobs[i + 2])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ──────────────────── Empty State Bento Card ────────────────────

  Widget _buildEmptyBentoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 56),
      decoration: BoxDecoration(
        gradient: AppColors.bentoCardGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.bentoBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Icon(Icons.search_off_rounded, size: 40, color: AppColors.secondary),
          ),
          const SizedBox(height: 18),
          const Text(
            'No Positions Above Current Match Threshold',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try lowering your minimum AI cosine match threshold using the slider, or clear search filters.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reset Semantic Filters'),
            onPressed: () {
              final bloc = context.read<JobBloc>();
              bloc.add(MinMatchScoreChanged(60));
              bloc.add(SearchQueryChanged(''));
              bloc.add(CategoryChanged('All'));
            },
          ),
        ],
      ),
    );
  }
}
