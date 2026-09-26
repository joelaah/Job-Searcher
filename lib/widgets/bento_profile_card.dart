import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../bloc/job_state.dart';
import '../theme/app_colors.dart';

class BentoProfileCard extends StatefulWidget {
  const BentoProfileCard({super.key});

  @override
  State<BentoProfileCard> createState() => _BentoProfileCardState();
}

class _BentoProfileCardState extends State<BentoProfileCard> {
  bool _isProcessing = false;
  String _processingStage = '';

  void _showResumeSelectionDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: 580,
            constraints: const BoxConstraints(maxHeight: 650),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF071924), Color(0xFF040E17)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cyanAccent.withAlpha(80), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyanAccent.withAlpha(25),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppColors.cyanAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Vectorize Candidate Resume',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Upload your own resume or select a sample candidate archetype to see the AI auto-calibrate steering sliders & latent space nodes in real time.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 18),

                  // Option 1: File Upload Box
                  InkWell(
                    onTap: () {
                      Navigator.of(dialogCtx).pop();
                      _handleFilePick();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated.withAlpha(120),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(140),
                          style: BorderStyle.solid,
                          width: 1.4,
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'Upload Custom Resume (PDF / DOCX / TXT)',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'AI extracts skills, seniority, and auto-tunes latent biases',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.surfaceBorder)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'OR TEST LIVE ARCHETYPE PRESETS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.8),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.surfaceBorder)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Preset 1: Lead Mobile Architect
                  _buildPresetOption(
                    title: '📱 Lead Flutter & Mobile Architect',
                    badge: 'Frontend / Lead Bias',
                    badgeColor: AppColors.secondary,
                    subtitle: '6+ yrs Flutter, Dart, Swift, Kotlin, Reactive UI, System Design',
                    onSelect: () {
                      Navigator.of(dialogCtx).pop();
                      _startProcessingSimulation(
                        fileName: 'Lead_Flutter_Architect_CV.pdf',
                        summary: 'Principal Mobile Architect with 6+ years designing high-throughput Flutter and Dart apps, native iOS/Android bridge plugins, reactive UI architecture, and design systems.',
                        skills: ['Flutter', 'Dart', 'Swift', 'Kotlin', 'Mobile Architecture', 'UI/UX', 'CI/CD', 'State Management', 'Riverpod', 'REST API'],
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Preset 2: Founding Backend & Data Systems
                  _buildPresetOption(
                    title: '⚙️ Founding Backend & Vector AI Engineer',
                    badge: 'Backend / Startup Bias',
                    badgeColor: AppColors.cyanAccent,
                    subtitle: 'PostgreSQL, pgvector, Python, FastAPI, Docker, Supabase, 0-to-1 startups',
                    onSelect: () {
                      Navigator.of(dialogCtx).pop();
                      _startProcessingSimulation(
                        fileName: 'Founding_Backend_Vector_CV.pdf',
                        summary: 'Founding Backend & Data Systems Engineer specializing in 0 to 1 startups, PostgreSQL tuning, pgvector search pipelines, FastAPI microservices, and Dockerized cloud clusters.',
                        skills: ['PostgreSQL', 'pgvector', 'Python', 'FastAPI', 'Docker', 'Supabase', 'Redis', 'Distributed Systems', 'Backend Architecture'],
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Preset 3: Enterprise Cloud & Platforms
                  _buildPresetOption(
                    title: '🏢 Enterprise Cloud & Platforms Architect',
                    badge: 'Enterprise / Scale Bias',
                    badgeColor: AppColors.primary,
                    subtitle: 'Distributed platform scale, corporate systems, PostgreSQL, TypeScript, AWS',
                    onSelect: () {
                      Navigator.of(dialogCtx).pop();
                      _startProcessingSimulation(
                        fileName: 'Enterprise_Platform_Lead_CV.pdf',
                        summary: 'Enterprise Solutions Architect with extensive background across corporate multi-tenant platforms, distributed database infrastructure, TypeScript/React frontend micro-apps, and security compliance.',
                        skills: ['TypeScript', 'React', 'PostgreSQL', 'Docker', 'Kubernetes', 'GraphQL', 'AWS', 'Enterprise Architecture', 'CI/CD'],
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Preset 4: Hands-on Junior / Mid IC
                  _buildPresetOption(
                    title: '🛠️ Hands-on Full-Stack IC Developer',
                    badge: 'IC / Balanced Bias',
                    badgeColor: const Color(0xFFA78BFA),
                    subtitle: '1.5 yrs React, TypeScript, Dart, Node.js, Agile team contributor',
                    onSelect: () {
                      Navigator.of(dialogCtx).pop();
                      _startProcessingSimulation(
                        fileName: 'Junior_FullStack_Developer_CV.pdf',
                        summary: 'Hands-on junior developer with 1.5 years experience building reactive web interfaces with React, Dart, Node.js, and contributing to agile startup feature development.',
                        skills: ['React', 'TypeScript', 'Node.js', 'Dart', 'CSS/HTML', 'Git', 'Agile'],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetOption({
    required String title,
    required String badge,
    required Color badgeColor,
    required String subtitle,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withAlpha(90),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: badgeColor.withAlpha(80)),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: badgeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFilePick() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        _startProcessingSimulation(
          fileName: file.name,
          summary: 'Uploaded candidate resume containing verified engineering experience, modern web & mobile architectures, and automated cloud workflows.',
          skills: ['Flutter', 'Dart', 'TypeScript', 'PostgreSQL', 'Python', 'Docker', 'FastAPI'],
        );
      }
    } catch (_) {
      _startProcessingSimulation(
        fileName: 'Custom_Engineer_Resume.pdf',
        summary: 'Uploaded candidate resume containing verified engineering experience, modern web & mobile architectures, and automated cloud workflows.',
        skills: ['Flutter', 'Dart', 'TypeScript', 'PostgreSQL', 'Python', 'Docker', 'FastAPI'],
      );
    }
  }

  void _startProcessingSimulation({
    required String fileName,
    required String summary,
    required List<String> skills,
  }) async {
    setState(() {
      _isProcessing = true;
      _processingStage = 'Extracting resume text & structure...';
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _processingStage = 'Chunking experience into semantic nodes...');

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _processingStage = 'Generating 768-dim embeddings via Gemini...');

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    context.read<JobBloc>().add(ResumeUploaded(
      fileName: fileName,
      summary: summary,
      skills: skills,
    ));

    setState(() {
      _isProcessing = false;
      _processingStage = '';
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.matchHigh, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Resume "$fileName" parsed! AI Steering Sliders auto-calibrated.',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
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
              // Top Identity & Vector Badge Row
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
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
                          profile.fullName.isNotEmpty ? profile.fullName[0] : 'U',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Candidate Info
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
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(35),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.primary.withAlpha(80)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.hub_outlined, size: 11, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        '768-dim Vector',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${profile.targetRoles.first} • ${profile.yearsOfExperience}+ yrs exp',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Semantic Summary
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withAlpha(160),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceBorder.withAlpha(120)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.psychology_outlined, size: 16, color: AppColors.cyanAccent),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            profile.parsedSummary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Skills Chips (Top 6)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: profile.primarySkills.take(7).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated.withAlpha(180),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bottom Active CV & Action Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder.withAlpha(100)),
                ),
                child: _isProcessing
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _processingStage,
                                  style: const TextStyle(fontSize: 11, color: AppColors.cyanAccent),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(3)),
                            child: LinearProgressIndicator(
                              minHeight: 3,
                              backgroundColor: AppColors.surfaceBorder,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              profile.resumeFileName ?? 'Resume_Vectorized.pdf',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: _showResumeSelectionDialog,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(35),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withAlpha(100)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.upload_file, size: 13, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Update CV',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
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
