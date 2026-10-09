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

class BentoJobCard extends StatefulWidget {
  final JobModel job;

  const BentoJobCard({super.key, required this.job});

  @override
  State<BentoJobCard> createState() => _BentoJobCardState();
}

class _BentoJobCardState extends State<BentoJobCard> {
  bool _isHovered = false;

  Color _getScoreColor(int score) {
    if (score >= 90) return AppColors.matchHigh;
    if (score >= 75) return AppColors.matchMedium;
    return AppColors.matchLow;
  }

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
          text: 'User: ${match.usernameOrEmail}\nResume: ${match.resumePath}',
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔒 Vault: Copied user identity for ${match.platform} (password kept safe in vault)'),
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
    final scoreColor = _getScoreColor(job.matchScore);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -5 : 0, 0),
        decoration: BoxDecoration(
          gradient: AppColors.bentoCardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? (job.matchScore >= 90 ? AppColors.secondary : AppColors.primary)
                : AppColors.bentoBorder,
            width: _isHovered ? 1.6 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? (job.matchScore >= 90
                      ? AppColors.secondary.withAlpha(50)
                      : AppColors.primary.withAlpha(50))
                  : const Color(0x18000000),
              blurRadius: _isHovered ? 26 : 12,
              offset: Offset(0, _isHovered ? 8 : 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Company Avatar + Info + Match Score Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with subtle glow ring
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(50),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    job.company.isNotEmpty ? job.company[0] : 'J',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title & Company
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              job.company,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cyanAccent,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 13, color: AppColors.cyanAccent),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Match Score Badge with Glow
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: scoreColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scoreColor.withAlpha(120), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: scoreColor.withAlpha(35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 14, color: scoreColor),
                      const SizedBox(width: 3),
                      Text(
                        '${job.matchScore}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Location, Remote & Salary Meta Row
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        job.location,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                if (job.isRemote)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppColors.primary.withAlpha(80)),
                    ),
                    child: const Text(
                      'Remote',
                      style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Text(
                    job.formattedSalary,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Semantic Reason Snippet
            if (job.whyItFits.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha(160),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surfaceBorder.withAlpha(110)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.check_circle_rounded, size: 14, color: AppColors.secondary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job.whyItFits.first,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

            const SizedBox(height: 14),

            // Tech Stack Tags with Smart Highlight
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: job.tags.take(5).map((t) {
                final isCoreMatch = ['Flutter', 'Dart', 'PostgreSQL', 'pgvector', 'Supabase', 'Python']
                    .any((skill) => t.toLowerCase().contains(skill.toLowerCase()));

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCoreMatch
                        ? AppColors.secondary.withAlpha(20)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCoreMatch
                          ? AppColors.secondary.withAlpha(80)
                          : AppColors.surfaceBorder.withAlpha(120),
                    ),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCoreMatch ? FontWeight.w700 : FontWeight.w500,
                      color: isCoreMatch ? AppColors.secondary : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // Action Strip
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;

                final bookmarkBtn = InkWell(
                  onTap: () => bloc.add(ToggleSaveJob(job.id)),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: job.isSaved ? AppColors.secondary.withAlpha(25) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: job.isSaved ? AppColors.secondary : AppColors.surfaceBorder,
                      ),
                    ),
                    child: Icon(
                      job.isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 16,
                      color: job.isSaved ? AppColors.secondary : AppColors.textMuted,
                    ),
                  ),
                );

                final detailsBtn = OutlinedButton(
                  onPressed: _openDetailDialog,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                    side: const BorderSide(color: AppColors.surfaceBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('AI Analysis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                );

                final applyBtn = ElevatedButton(
                  onPressed: () => _applyJob(job),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: job.isApplied ? AppColors.surfaceElevated : AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          job.isApplied ? Icons.check : Icons.bolt,
                          size: 14,
                          color: job.isApplied ? AppColors.matchHigh : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          job.isApplied ? 'Applied' : 'Apply',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: job.isApplied ? AppColors.matchHigh : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                final autoApplyBtn = BlocBuilder<JobBloc, JobState>(
                  buildWhen: (prev, curr) =>
                      prev.autoApplyStatuses[job.id]?.status !=
                      curr.autoApplyStatuses[job.id]?.status,
                  builder: (context, state) {
                    final applyStatus = state.autoApplyStatuses[job.id];
                    final isRunning = applyStatus?.isRunning ?? false;
                    final isSuccess = applyStatus?.isSuccess ?? false;

                    return ElevatedButton(
                      onPressed: isRunning || isSuccess || job.isApplied
                          ? null
                          : () => _autoApplyJob(job),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSuccess
                            ? AppColors.matchHigh
                            : isRunning
                                ? AppColors.surfaceElevated
                                : AppColors.cyanAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        disabledBackgroundColor: isSuccess
                            ? AppColors.matchHigh.withAlpha(180)
                            : AppColors.surfaceElevated,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isRunning)
                              const SizedBox(
                                width: 12, height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.cyanAccent,
                                ),
                              )
                            else
                              Icon(
                                isSuccess ? Icons.check_circle : Icons.rocket_launch,
                                size: 14,
                                color: isSuccess ? Colors.black : Colors.black87,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              isRunning
                                  ? 'Filling...'
                                  : isSuccess
                                      ? 'Filled ✓'
                                      : 'Auto Apply',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isSuccess ? Colors.black : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          bookmarkBtn,
                          const SizedBox(width: 8),
                          Expanded(child: detailsBtn),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: applyBtn),
                          const SizedBox(width: 8),
                          Expanded(child: autoApplyBtn),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    bookmarkBtn,
                    const SizedBox(width: 8),
                    Expanded(child: detailsBtn),
                    const SizedBox(width: 8),
                    applyBtn,
                    const SizedBox(width: 6),
                    autoApplyBtn,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
