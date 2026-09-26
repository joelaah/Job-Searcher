import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../bloc/job_state.dart';
import '../models/job_model.dart';
import '../theme/app_colors.dart';

class JobDetailDialog extends StatefulWidget {
  final JobModel job;

  const JobDetailDialog({super.key, required this.job});

  @override
  State<JobDetailDialog> createState() => _JobDetailDialogState();
}

class _JobDetailDialogState extends State<JobDetailDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppColors.matchHigh;
    if (score >= 75) return AppColors.matchMedium;
    return AppColors.matchLow;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(Icons.check, color: AppColors.matchHigh, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text('$label copied!',
                  style: const TextStyle(color: AppColors.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        // Get latest version of the job from Bloc state
        final job = state.allJobs.firstWhere(
          (j) => j.id == widget.job.id,
          orElse: () => widget.job,
        );
        final scoreColor = _getScoreColor(job.matchScore);

        return Dialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.surfaceBorder),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 800,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          job.company.substring(0, 1),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  job.company,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Text('•',
                                    style: TextStyle(
                                        color: AppColors.textMuted)),
                                Text(
                                  job.location,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (job.isRemote)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.cyanAccent.withAlpha(30),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Remote',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.cyanAccent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: scoreColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: scoreColor.withAlpha(100)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome,
                                    size: 14, color: scoreColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${job.matchScore}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: scoreColor,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Semantic Fit',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: scoreColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textMuted, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2.5,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(text: 'RAG Analysis'),
                    Tab(text: 'AI Pitch'),
                    Tab(text: 'Description'),
                  ],
                ),

                // Tab Content
                Flexible(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: RAG Analysis
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: AppColors.matchHigh, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Why Your Resume Matches',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...job.whyItFits.map((point) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ',
                                          style: TextStyle(
                                              color: AppColors.matchHigh,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14)),
                                      Expanded(
                                        child: Text(
                                          point,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            height: 1.4,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 16),
                            const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: AppColors.matchMedium, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Potential Gaps',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...job.skillGaps.map((point) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ',
                                          style: TextStyle(
                                              color: AppColors.matchMedium,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14)),
                                      Expanded(
                                        child: Text(
                                          point,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            height: 1.4,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 16),
                            const Text('Required Technologies',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                )),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: job.tags
                                  .map((tag) => Chip(
                                        label: Text(tag,
                                            style:
                                                const TextStyle(fontSize: 11)),
                                        backgroundColor:
                                            AppColors.surfaceElevated,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),

                      // Tab 2: AI Pitch
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text('Tailored Elevator Pitch',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      )),
                                ),
                                TextButton.icon(
                                  onPressed: () => _copyToClipboard(
                                      job.tailoredPitch, 'Pitch'),
                                  icon: const Icon(Icons.copy, size: 14),
                                  label: const Text('Copy',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.primary.withAlpha(50)),
                              ),
                              child: SelectableText(
                                job.tailoredPitch,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text('Recruiter Email Template',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      )),
                                ),
                                TextButton.icon(
                                  onPressed: () => _copyToClipboard(
                                      job.recruiterMessage, 'Email'),
                                  icon: const Icon(Icons.copy, size: 14),
                                  label: const Text('Copy',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.surfaceBorder),
                              ),
                              child: SelectableText(
                                job.recruiterMessage,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  height: 1.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tab 3: Full Description
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          job.fullDescription,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.surfaceBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context
                            .read<JobBloc>()
                            .add(ToggleSaveJob(job.id)),
                        icon: Icon(
                          job.isSaved
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: 16,
                          color: job.isSaved
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        label: Text(
                          job.isSaved ? 'Saved' : 'Save',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          context
                              .read<JobBloc>()
                              .add(DismissJob(job.id));
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close,
                            color: AppColors.textMuted, size: 16),
                        label: const Text('Pass',
                            style: TextStyle(fontSize: 12)),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          context
                              .read<JobBloc>()
                              .add(MarkJobApplied(job.id));
                          _launchUrl(job.applicationUrl);
                        },
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: Text(
                          job.isApplied ? 'Applied ✓' : 'Apply',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: job.isApplied
                              ? AppColors.matchHigh
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
