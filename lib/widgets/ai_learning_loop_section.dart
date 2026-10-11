import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../bloc/job_state.dart';
import '../theme/app_colors.dart';
import 'latent_space_constellation.dart';
import 'learning_insights_modal.dart';

class AiLearningLoopSection extends StatefulWidget {
  const AiLearningLoopSection({super.key});

  @override
  State<AiLearningLoopSection> createState() => _AiLearningLoopSectionState();
}

class _AiLearningLoopSectionState extends State<AiLearningLoopSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _roleInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _roleInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        final profile = state.userProfile;
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 1100;
        final isTablet = screenWidth >= 768 && screenWidth < 1100;
        final percentage = (profile.vectorShiftMagnitude * 100).toInt();

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF071924), Color(0xFF040E16)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.secondary.withAlpha(80),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withAlpha(25),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ══════════════════════════════════════════
              // Top Banner: Cyber Badge & Controls
              // ══════════════════════════════════════════
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 700;
                  final badges = Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.secondary,
                                ),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 12,
                                      color: AppColors.secondary,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'AUTONOMOUS LEARNING LOOP',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(70),
                          ),
                        ),
                        child: const Text(
                          'Latent Affinity Steering',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  );

                  final titleSection = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      badges,
                      const SizedBox(height: 10),
                      ShaderMask(
                        shaderCallback: (bounds) => AppColors
                            .emeraldBlueGradient
                            .createShader(bounds),
                        child: Text(
                          'Continuous Latent Affinity & Re-Ranking Engine',
                          style: TextStyle(
                            fontSize: isCompact ? 18 : 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Interact with positions or adjust tactical steering sliders below to dynamically re-weight semantic affinity and explore your latent constellation in real time (with optional Supabase vector sync).',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  );

                  final insightsBtn = OutlinedButton.icon(
                    icon: const Icon(
                      Icons.analytics_outlined,
                      size: 16,
                      color: AppColors.cyanAccent,
                    ),
                    label: const Text('Detailed Insights'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cyanAccent,
                      side: BorderSide(
                        color: AppColors.cyanAccent.withAlpha(120),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => BlocProvider.value(
                          value: context.read<JobBloc>(),
                          child: const LearningInsightsModal(),
                        ),
                      );
                    },
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleSection,
                        const SizedBox(height: 14),
                        insightsBtn,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: titleSection),
                      const SizedBox(width: 16),
                      insightsBtn,
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // ══════════════════════════════════════════
              // Three-Card Cyber Bento Grid
              // ══════════════════════════════════════════
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: 2D Constellation Visualizer
                    Expanded(
                      flex: 4,
                      child: _buildConstellationCard(
                        context,
                        state,
                        percentage,
                      ),
                    ),
                    const SizedBox(width: 18),
                    // Card 2: Career Alignment & Skill Gravity
                    Expanded(
                      flex: 5,
                      child: _buildCareerAlignmentCard(context, state),
                    ),
                    const SizedBox(width: 18),
                    // Card 3: Live Synapse Console & Simulator
                    Expanded(
                      flex: 3,
                      child: _buildTelemetryConsoleCard(
                        context,
                        state,
                        percentage,
                      ),
                    ),
                  ],
                )
              else if (isTablet)
                Column(
                  children: [
                    _buildConstellationCard(context, state, percentage),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildCareerAlignmentCard(context, state),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTelemetryConsoleCard(
                            context,
                            state,
                            percentage,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildConstellationCard(context, state, percentage),
                    const SizedBox(height: 14),
                    _buildCareerAlignmentCard(context, state),
                    const SizedBox(height: 14),
                    _buildTelemetryConsoleCard(context, state, percentage),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────── Card 1: Latent Space Constellation Visualizer ────────────────────

  Widget _buildConstellationCard(
    BuildContext context,
    JobState state,
    int percentage,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.radar, size: 16, color: AppColors.secondary),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Latent Space Constellation',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${state.filteredJobs.length} NODES ORBITING',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Interactive Constellation Canvas
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF030A0F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceBorder.withAlpha(120)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: LatentSpaceConstellation(
                jobs: state.filteredJobs,
                vectorShiftMagnitude: state.userProfile.vectorShiftMagnitude,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Metric Details
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder.withAlpha(100)),
            ),
            child: Column(
              children: [
                _buildMetricRow('Active Center', 'Alex Vance (768-D Vector)'),
                const Divider(height: 10, color: AppColors.surfaceBorder),
                _buildMetricRow(
                  'Drift Metric',
                  'Cosine Angular Distance (1 - u·v)',
                ),
                const Divider(height: 10, color: AppColors.surfaceBorder),
                _buildMetricRow(
                  'Latent Shift',
                  '$percentage% Personalized Gravitation',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  // ──────────────────── Card 2: Career Alignment & Skill Gravity ────────────────────

  Widget _buildCareerAlignmentCard(BuildContext context, JobState state) {
    final bloc = context.read<JobBloc>();
    final profile = state.userProfile;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.explore_outlined,
                    size: 17,
                    color: AppColors.cyanAccent,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Career Alignment & Gravity',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => bloc.add(SyncSteeringToResume()),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(90),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sync, size: 11, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Auto-Sync',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => bloc.add(ResetCareerAlignment()),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Resume Coupling Indicator Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(180),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withAlpha(60)),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.matchHigh,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.matchHigh, blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Profile: ',
                  style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                ),
                Expanded(
                  child: Text(
                    state.userProfile.resumeFileName ??
                        'Candidate Resume Profile',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 1. Target Roles (Dynamic Pills + Custom Input)
          const Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(
                '1. TARGET ROLES (TYPE ANY ROLE OR USE PILLS)',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                'Unlimited roles',
                style: TextStyle(
                  fontSize: 9.5,
                  color: AppColors.cyanAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),

          // Active Role Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: state.targetRoles.map((role) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cyanAccent.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.cyanAccent.withAlpha(100),
                    width: 1.1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        role,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    InkWell(
                      onTap: () => bloc.add(RemoveTargetRole(role)),
                      child: const Icon(
                        Icons.close,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Quick Custom Role Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withAlpha(120),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 14, color: AppColors.cyanAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _roleInputController,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText:
                          'Type any role (e.g. "DevOps Intern", "QA Automation", "React Dev")...',
                      hintStyle: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        bloc.add(AddTargetRole(val.trim()));
                        _roleInputController.clear();
                      }
                    },
                  ),
                ),
                InkWell(
                  onTap: () {
                    if (_roleInputController.text.trim().isNotEmpty) {
                      bloc.add(AddTargetRole(_roleInputController.text.trim()));
                      _roleInputController.clear();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(35),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(100),
                      ),
                    ),
                    child: const Text(
                      '+ Add Role',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 7),

          // Quick Suggestion Pills
          Wrap(
            spacing: 5,
            runSpacing: 4,
            children:
                [
                      '🎓 Software Engineer Intern',
                      '🌱 DevOps Intern',
                      '⚡ Junior Full-Stack',
                      '🧠 AI Platform Engineer',
                      '🛠️ QA Automation',
                    ]
                    .where(
                      (s) => !state.targetRoles.any(
                        (r) =>
                            r.toLowerCase() ==
                            s
                                .replaceAll(RegExp(r'[^\w\s\-]'), '')
                                .trim()
                                .toLowerCase(),
                      ),
                    )
                    .take(3)
                    .map((suggestion) {
                      final cleanName = suggestion
                          .replaceAll(RegExp(r'[^\w\s\-]'), '')
                          .trim();
                      return InkWell(
                        onTap: () => bloc.add(AddTargetRole(cleanName)),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.surfaceBorder.withAlpha(90),
                            ),
                          ),
                          child: Text(
                            '+ $suggestion',
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(),
          ),

          const SizedBox(height: 14),

          // 2. Experience Level (Universal Spectrum from Intern to Lead)
          const Text(
            '2. EXPERIENCE LEVEL (WELCOMING 0-EXP & INTERNS)',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildFilterBadge(
                label: '🎓 Intern / Co-op (0 yrs)',
                isSelected: state.selectedSeniorities.contains(
                  '🎓 Intern / Co-op',
                ),
                activeColor: const Color(0xFF38BDF8),
                onTap: () =>
                    bloc.add(ToggleSeniorityFilter('🎓 Intern / Co-op')),
              ),
              _buildFilterBadge(
                label: '🌱 Junior (0–2 yrs)',
                isSelected: state.selectedSeniorities.contains(
                  '🌱 Junior (0–2 yrs)',
                ),
                activeColor: AppColors.matchHigh,
                onTap: () =>
                    bloc.add(ToggleSeniorityFilter('🌱 Junior (0–2 yrs)')),
              ),
              _buildFilterBadge(
                label: '⚡ Mid-Level (2–5 yrs)',
                isSelected: state.selectedSeniorities.contains(
                  '⚡ Mid-Level (2–5 yrs)',
                ),
                activeColor: AppColors.cyanAccent,
                onTap: () =>
                    bloc.add(ToggleSeniorityFilter('⚡ Mid-Level (2–5 yrs)')),
              ),
              _buildFilterBadge(
                label: '🛠️ Senior (5+ yrs)',
                isSelected: state.selectedSeniorities.contains(
                  '🛠️ Senior (5+ yrs)',
                ),
                activeColor: AppColors.primary,
                onTap: () =>
                    bloc.add(ToggleSeniorityFilter('🛠️ Senior (5+ yrs)')),
              ),
              _buildFilterBadge(
                label: '👑 Lead / Staff / Architect',
                isSelected: state.selectedSeniorities.contains(
                  '👑 Lead / Staff / Architect',
                ),
                activeColor: const Color(0xFFA78BFA),
                onTap: () => bloc.add(
                  ToggleSeniorityFilter('👑 Lead / Staff / Architect'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Environment & Scale
          const Text(
            '3. ENVIRONMENT & SCALE',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildFilterBadge(
                label: '🚀 Early Startup (0→1)',
                isSelected: state.selectedCompanyStages.any(
                  (s) => s.contains('Startup'),
                ),
                activeColor: AppColors.matchHigh,
                onTap: () => bloc.add(
                  ToggleCompanyStageFilter('🚀 Early Startup (0→1)'),
                ),
              ),
              _buildFilterBadge(
                label: '⚡ Growth Scaleup',
                isSelected: state.selectedCompanyStages.any(
                  (s) => s.contains('Scaleup'),
                ),
                activeColor: AppColors.cyanAccent,
                onTap: () =>
                    bloc.add(ToggleCompanyStageFilter('⚡ Growth Scaleup')),
              ),
              _buildFilterBadge(
                label: '🏢 Enterprise Scale',
                isSelected: state.selectedCompanyStages.any(
                  (s) => s.contains('Enterprise'),
                ),
                activeColor: AppColors.primary,
                onTap: () =>
                    bloc.add(ToggleCompanyStageFilter('🏢 Enterprise Scale')),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 4. Resume Skill Gravity (Dynamically extracted from CV)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Text(
                '4. RESUME SKILL GRAVITY',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                'Tap skill to boost (+10%)',
                style: TextStyle(
                  fontSize: 9.5,
                  color: AppColors.cyanAccent.withAlpha(220),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: profile.primarySkills.take(8).map((skill) {
              final isBoosted = state.boostedSkills.contains(skill);
              return InkWell(
                onTap: () => bloc.add(ToggleSkillBoost(skill)),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4.5,
                  ),
                  decoration: BoxDecoration(
                    color: isBoosted
                        ? AppColors.matchHigh.withAlpha(28)
                        : AppColors.surfaceElevated.withAlpha(120),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isBoosted
                          ? AppColors.matchHigh
                          : AppColors.surfaceBorder,
                      width: isBoosted ? 1.2 : 1.0,
                    ),
                    boxShadow: isBoosted
                        ? [
                            BoxShadow(
                              color: AppColors.matchHigh.withAlpha(40),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isBoosted) ...[
                        const Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: AppColors.matchHigh,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        skill,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isBoosted
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isBoosted
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (isBoosted) ...[
                        const SizedBox(width: 4),
                        const Text(
                          '+10%',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.matchHigh,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // 5. Active Intent Summary Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceBorder.withAlpha(120)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.bolt,
                    size: 14,
                    color: AppColors.cyanAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.activeAlignmentSummary,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBadge({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(30) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.surfaceBorder,
            width: isSelected ? 1.2 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withAlpha(35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 11, color: activeColor),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────── Card 3: Telemetry Console & Simulator ────────────────────

  Widget _buildTelemetryConsoleCard(
    BuildContext context,
    JobState state,
    int percentage,
  ) {
    final bloc = context.read<JobBloc>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.terminal, size: 16, color: AppColors.secondary),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Live Synapse Console',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Terminal Log Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF040B10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTerminalLine(
                  '[02:14:28]',
                  'pgvector HNSW index initialized (m=16)',
                ),
                const SizedBox(height: 4),
                _buildTerminalLine(
                  '[02:14:35]',
                  'Candidate vector: 768-D norm calibrated',
                ),
                const SizedBox(height: 4),
                _buildTerminalLine(
                  '[02:14:42]',
                  'Shift magnitude at $percentage% (+${state.totalSavedCount} saved, +${state.totalAppliedCount} applied)',
                ),
                const SizedBox(height: 4),
                _buildTerminalLine(
                  '[02:14:50]',
                  'Tactile biases applied to HNSW distance function',
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Interactive Simulation Buttons
          const Text(
            'Interactive Vector Steering Sandbox:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    bloc.add(
                      SimulateVectorShift(
                        delta: 0.06,
                        insight:
                            'Manual boost: Accelerated vector affinity towards pgvector + Supabase stack (+6%)',
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.secondary.withAlpha(90),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 12, color: AppColors.secondary),
                          SizedBox(width: 4),
                          Text(
                            '+Boost Affinity',
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
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    bloc.add(ResetVectorShift());
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    alignment: Alignment.center,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Reset Drift',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
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
  }

  Widget _buildTerminalLine(String time, String message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$time ',
          style: const TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            color: AppColors.cyanAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: AppColors.textSecondary,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
