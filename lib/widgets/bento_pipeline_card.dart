import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_state.dart';
import '../theme/app_colors.dart';
import 'supabase_config_dialog.dart';
import 'custom_scraper_dialog.dart';
import 'zero_knowledge_vault_dialog.dart';


class BentoPipelineCard extends StatelessWidget {
  const BentoPipelineCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        final isConnected = state.isSupabaseConnected;

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
                          color: AppColors.cyanAccent.withAlpha(35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cyanAccent.withAlpha(80)),
                        ),
                        child: const Icon(Icons.cloud_sync_outlined, size: 16, color: AppColors.cyanAccent),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Cloud & Pipeline',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isConnected ? AppColors.matchHigh : AppColors.matchMedium,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isConnected ? AppColors.matchHigh : AppColors.matchMedium).withAlpha(150),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Pipeline Metrics
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '199+',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.matchHigh.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.matchHigh.withAlpha(80)),
                        ),
                        child: const Text(
                          'Live API Jobs',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.matchHigh,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Greenhouse • RemoteOK • Vercel • Figma',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Two Core Quick Action Buttons: Scrape Custom URL & Zero-Knowledge Vault
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => BlocProvider.value(
                            value: context.read<JobBloc>(),
                            child: const CustomScraperDialog(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cyanAccent.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cyanAccent.withAlpha(80)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.travel_explore, size: 13, color: AppColors.cyanAccent),
                            SizedBox(width: 5),
                            Text(
                              'Scrape URL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cyanAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => BlocProvider.value(
                            value: context.read<JobBloc>(),
                            child: const ZeroKnowledgeVaultDialog(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.matchHigh.withAlpha(22),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.matchHigh.withAlpha(75)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, size: 13, color: AppColors.matchHigh),
                            SizedBox(width: 5),
                            Text(
                              'CSV Vault',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.matchHigh,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Action button to launch DB Config
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
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isConnected ? Icons.check_circle_outline : Icons.storage_outlined,
                        size: 13,
                        color: isConnected ? AppColors.matchHigh : AppColors.cyanAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isConnected ? 'Supabase Connected' : 'Connect Supabase DB',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isConnected ? AppColors.matchHigh : AppColors.textPrimary,
                        ),
                      ),
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
}
