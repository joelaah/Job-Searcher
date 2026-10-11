import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_state.dart';
import '../theme/app_colors.dart';
import 'learning_insights_modal.dart';
import 'supabase_config_dialog.dart';

class NavHeader extends StatelessWidget {
  const NavHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        final isDesktop = MediaQuery.of(context).size.width >= 900;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 16,
            vertical: 14,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.surfaceBorder, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Logo & Title
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(80),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.work_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'JOB',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      AppColors.primaryGradient
                                          .createShader(bounds),
                                  child: const Text(
                                    'SeArCh',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (isDesktop) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(40),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.primary.withAlpha(100),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'RAG + pgvector',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isDesktop)
                            const Text(
                              'AI-Powered Semantic Resume-to-Job Matching',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Desktop Action Badges
              if (isDesktop) ...[
                const SizedBox(width: 16),

                // AI Learning Loop Pill
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
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.secondary.withAlpha(80),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.psychology,
                            size: 16, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          'AI Loop: ${(state.userProfile.vectorShiftMagnitude * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Supabase Connection Pill
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => BlocProvider.value(
                        value: context.read<JobBloc>(),
                        child: const SupabaseConfigDialog(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: state.isSupabaseConnected
                          ? AppColors.matchHigh.withAlpha(25)
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: state.isSupabaseConnected
                            ? AppColors.matchHigh.withAlpha(120)
                            : AppColors.surfaceBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.storage,
                            size: 14,
                            color: state.isSupabaseConnected
                                ? AppColors.matchHigh
                                : AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          state.isSupabaseConnected
                              ? 'Supabase ✓'
                              : 'Connect DB',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: state.isSupabaseConnected
                                ? AppColors.matchHigh
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 8),

                // Mobile AI Loop Action Icon
                IconButton(
                  icon: const Icon(Icons.psychology, size: 20, color: AppColors.secondary),
                  tooltip: 'AI Loop: ${(state.userProfile.vectorShiftMagnitude * 100).toInt()}%',
                  padding: const EdgeInsets.all(6),
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
                const SizedBox(width: 4),

                // Mobile Supabase Action Icon
                IconButton(
                  icon: Icon(
                    Icons.storage,
                    size: 20,
                    color: state.isSupabaseConnected ? AppColors.matchHigh : AppColors.textMuted,
                  ),
                  tooltip: state.isSupabaseConnected ? 'Supabase Connected' : 'Connect DB',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => BlocProvider.value(
                        value: context.read<JobBloc>(),
                        child: const SupabaseConfigDialog(),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
