import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../bloc/job_state.dart';
import '../theme/app_colors.dart';

class ResumeUploadCard extends StatefulWidget {
  const ResumeUploadCard({super.key});

  @override
  State<ResumeUploadCard> createState() => _ResumeUploadCardState();
}

class _ResumeUploadCardState extends State<ResumeUploadCard> {
  bool _isProcessing = false;
  String _processingStage = '';

  Future<void> _handleFilePick() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        _startProcessingSimulation(file.name);
      }
    } catch (_) {
      _startProcessingSimulation('Senior_Product_Engineer_CV.pdf');
    }
  }

  void _startProcessingSimulation(String fileName) async {
    setState(() {
      _isProcessing = true;
      _processingStage = 'Extracting resume text & structure...';
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _processingStage = 'Chunking experience into semantic nodes...');

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _processingStage = 'Generating 768-dim vectors via embedding model...');

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    context.read<JobBloc>().add(ResumeUploaded(
      fileName: fileName,
      summary:
          'Senior Product & Systems Engineer with proven experience leading distributed web platforms, Flutter cross-platform architectures, vector indexing in PostgreSQL, and automated cloud workflows.',
      skills: [
        'Flutter', 'Dart', 'TypeScript', 'React', 'PostgreSQL',
        'pgvector', 'Python', 'FastAPI', 'Docker', 'GraphQL', 'Supabase',
      ],
    ));

    setState(() {
      _isProcessing = false;
      _processingStage = '';
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.matchHigh, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Resume "$fileName" parsed and vectorized!',
                style: const TextStyle(color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        final profile = state.userProfile;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withAlpha(90)),
                    ),
                    child: const Icon(Icons.description_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                profile.fullName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.matchHigh.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.matchHigh.withAlpha(100),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt,
                                      size: 10, color: AppColors.matchHigh),
                                  SizedBox(width: 3),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.matchHigh,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.resumeFileName ?? 'No resume uploaded',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Upload Button (full width to avoid row overflow)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _handleFilePick,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        )
                      : const Icon(Icons.sync, size: 16),
                  label: Text(
                    _isProcessing ? 'Vectorizing...' : 'Upload New Resume',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),

              if (_isProcessing) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _processingStage,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.cyanAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),
              const Divider(color: AppColors.surfaceBorder, height: 1),
              const SizedBox(height: 12),

              // Parsed Summary
              Text(
                profile.parsedSummary,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 12),

              // Skills Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: profile.primarySkills.map((skill) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
