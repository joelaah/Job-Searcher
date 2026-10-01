import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../bloc/job_state.dart';
import '../models/job_model.dart';
import '../models/local_credential.dart';
import '../theme/app_colors.dart';
import 'job_detail_dialog.dart';

class BentoHeroJobCard extends StatefulWidget {
  final JobModel job;

  const BentoHeroJobCard({super.key, required this.job});

  @override
  State<BentoHeroJobCard> createState() => _BentoHeroJobCardState();
}

class _BentoHeroJobCardState extends State<BentoHeroJobCard> {
  bool _isHovered = false;

  void _openDetailDialog() {
    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<JobBloc>(),
        child: JobDetailDialog(job: widget.job),
      ),
    );
  }

  Future<void> _applyJob(JobModel job) async {
    final bloc = context.read<JobBloc>();
    bloc.add(MarkJobApplied(job.id));

    // Zero-knowledge credential assist
    final creds = bloc.state.localCredentials;
    if (creds.isNotEmpty) {
      final urlLower = job.applicationUrl.toLowerCase();
      LocalCredential? match;
      for (final c in creds) {
        if (urlLower.contains(c.platform.toLowerCase())) {
          match = c;
          break;
        }
      }
      match ??= creds.first;

      await Clipboard.setData(
        ClipboardData(
          text: 'User: ${match.usernameOrEmail}\nPass: ${match.password}\nResume: ${match.resumePath}',
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔒 Vault: Copied login credentials for ${match.platform} to clipboard!'),
            backgroundColor: AppColors.cyanAccent,
          ),
        );
      }
    }

    final uri = Uri.parse(job.applicationUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    }
  }

  void _autoApplyJob(JobModel job) {
    final bloc = context.read<JobBloc>();
    bloc.add(AutoApplyJob(
      jobId: job.id,
      jobUrl: job.applicationUrl,
      jobTitle: job.title,
      jobCompany: job.company,
      jobDescription: job.fullDescription,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚀 Auto-Apply engine launched! Filling application form...'),
        backgroundColor: AppColors.cyanAccent,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final bloc = context.read<JobBloc>();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF09212E), Color(0xFF06141F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered ? AppColors.secondary : AppColors.secondary.withAlpha(150),
            width: _isHovered ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? AppColors.bentoGlowEmerald : AppColors.secondary.withAlpha(30),
              blurRadius: _isHovered ? 28 : 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Badge & Match Pill Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF065F46), Color(0xFF047857)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withAlpha(80),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium, size: 15, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        '#1 TOP SEMANTIC MATCH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary, width: 1.3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withAlpha(40),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, size: 16, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        '${job.matchScore}% Match',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Company & Job Title Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(70),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    job.company.isNotEmpty ? job.company[0] : 'J',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            job.company,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cyanAccent,
                            ),
                          ),
                          const Icon(Icons.verified, size: 14, color: AppColors.cyanAccent),
                          const Text('•', style: TextStyle(color: AppColors.textMuted)),
                          const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textMuted),
                          Text(
                            job.location,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          if (job.isRemote)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(35),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.primary.withAlpha(90)),
                              ),
                              child: const Text(
                                'Remote',
                                style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Salary Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Text(
                    job.formattedSalary,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // AI "Why This Fits" Highlights
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withAlpha(180),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder.withAlpha(120)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 15, color: AppColors.secondary),
                      SizedBox(width: 8),
                      Text(
                        'AI Semantic Match Analysis',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...job.whyItFits.take(2).map((reason) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.secondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Tech Stack & Action Buttons Row
            Row(
              children: [
                // Tags
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: job.tags.take(5).map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(width: 14),

                // Save Button
                IconButton(
                  icon: Icon(
                    job.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: job.isSaved ? AppColors.secondary : AppColors.textMuted,
                  ),
                  tooltip: job.isSaved ? 'Saved' : 'Save Job',
                  onPressed: () => bloc.add(ToggleSaveJob(job.id)),
                ),

                // View Details Button
                OutlinedButton.icon(
                  icon: const Icon(Icons.read_more, size: 16),
                  label: const Text('AI Analysis'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: _openDetailDialog,
                ),

                const SizedBox(width: 10),

                // Apply Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.bolt, size: 16),
                  label: Text(job.isApplied ? 'Applied ✓' : 'Apply Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: job.isApplied ? AppColors.surfaceElevated : AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () => _applyJob(job),
                ),

                const SizedBox(width: 8),

                // 🚀 Auto Apply Button
                BlocBuilder<JobBloc, JobState>(
                  buildWhen: (prev, curr) =>
                      prev.autoApplyStatuses[job.id]?.status !=
                      curr.autoApplyStatuses[job.id]?.status,
                  builder: (context, state) {
                    final applyStatus = state.autoApplyStatuses[job.id];
                    final isRunning = applyStatus?.isRunning ?? false;
                    final isSuccess = applyStatus?.isSuccess ?? false;

                    return ElevatedButton.icon(
                      onPressed: isRunning || isSuccess || job.isApplied
                          ? null
                          : () => _autoApplyJob(job),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSuccess
                            ? AppColors.matchHigh
                            : isRunning
                                ? AppColors.surfaceElevated
                                : AppColors.cyanAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        disabledBackgroundColor: isSuccess
                            ? AppColors.matchHigh.withAlpha(180)
                            : AppColors.surfaceElevated,
                      ),
                      icon: isRunning
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.cyanAccent,
                              ),
                            )
                          : Icon(
                              isSuccess ? Icons.check_circle : Icons.rocket_launch,
                              size: 16,
                              color: isSuccess ? Colors.black : Colors.black87,
                            ),
                      label: Text(
                        isRunning
                            ? 'Filling...'
                            : isSuccess
                                ? 'Filled ✓'
                                : 'Auto Apply',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isSuccess ? Colors.black : Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
