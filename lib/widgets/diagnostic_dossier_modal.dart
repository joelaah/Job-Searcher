import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../bloc/job_state.dart';
import '../models/job_model.dart';
import '../theme/app_colors.dart';
import 'difficulty_gauntlet_dots.dart';
import 'harmonic_pulse_waveform.dart';
import 'segmented_led_bar.dart';

/// Cyber-Marine HUD Diagnostic Dossier Modal for Job Telemetry & Fit Analysis.
/// Faithfully translates the deep-sea submersible and tactical cybernetic cockpit paradigm.
class DiagnosticDossierModal extends StatefulWidget {
  final JobModel job;

  const DiagnosticDossierModal({super.key, required this.job});

  static Future<void> show(BuildContext context, JobModel job) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => BlocProvider.value(
        value: context.read<JobBloc>(),
        child: DiagnosticDossierModal(job: job),
      ),
    );
  }

  @override
  State<DiagnosticDossierModal> createState() => _DiagnosticDossierModalState();
}

class _DiagnosticDossierModalState extends State<DiagnosticDossierModal>
    with SingleTickerProviderStateMixin {
  // Navigation tabs: 0 = Cockpit HUD, 1 = Raw Description & Recruiter Pitch
  int _activeViewIndex = 0;

  // Shimmer animation controller for CTA button
  late AnimationController _shimmerController;

  // Diagnostic notification toast state
  String? _toastMessage;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showTelemetryToast(String message) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
    });
    _toastTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        setState(() {
          _toastMessage = null;
        });
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    }
  }

  void _copyToClipboard(String text, String telemetryLabel) {
    Clipboard.setData(ClipboardData(text: text));
    _showTelemetryToast(telemetryLabel);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        final currentJob = state.allJobs.firstWhere(
          (j) => j.id == widget.job.id,
          orElse: () => widget.job,
        );

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 820,
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.18),
                    blurRadius: 36,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    _buildModalHeader(context, currentJob),
                    Expanded(
                      child: _activeViewIndex == 0
                          ? _buildCockpitView(context, currentJob)
                          : _buildRawDescriptionView(context, currentJob),
                    ),
                    _buildTacticalActionDock(context, currentJob),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // Header Stream Bar
  // ─────────────────────────────────────────────────────────
  Widget _buildModalHeader(BuildContext context, JobModel job) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.85),
        border: const Border(
          bottom: BorderSide(color: AppColors.surfaceContainerHighest, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Center Grab Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Back / Dismiss Icon
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
                tooltip: 'Return to Radar',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              // Dossier Spec Title & Monospace Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'DIAG_SPEC // 04',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: AppColors.secondary,
                      ),
                    ),
                    Text(
                      'Diagnostic Dossier',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              // View Switcher (HUD Cockpit vs Detailed Raw Spec)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceContainerHighest),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewTab(0, 'HUD', Icons.tune_rounded),
                    _buildViewTab(1, 'RAW JD', Icons.article_outlined),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Bookmark / Save Action
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  job.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: job.isSaved ? AppColors.secondary : AppColors.onSurfaceVariant,
                ),
                tooltip: job.isSaved ? 'Job Saved' : 'Save Job',
                onPressed: () {
                  context.read<JobBloc>().add(ToggleSaveJob(job.id));
                  _showTelemetryToast(job.isSaved ? 'REMOVED FROM SAVED' : 'SAVED TO DOSSIER REPO');
                },
              ),
              // Close Icon
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewTab(int index, String label, IconData icon) {
    final isSelected = _activeViewIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeViewIndex = index),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Primary Cockpit View: High Density Telemetry Deck
  // ─────────────────────────────────────────────────────────
  Widget _buildCockpitView(BuildContext context, JobModel job) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSystemStatusHeader(job),
          const SizedBox(height: 14),
          _buildHeroPulseEngine(job),
          const SizedBox(height: 14),
          _buildMod01CoreDnaVectors(job),
          const SizedBox(height: 14),
          _buildMod02TacticalBridge(job),
          const SizedBox(height: 14),
          _buildMod03VelocityDynamics(job),
          const SizedBox(height: 14),
          _buildMod04PredictedGauntlets(job),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── System Status Stream Header ──
  Widget _buildSystemStatusHeader(JobModel job) {
    final String phiValue = (job.matchScore / 100 * 0.98).clamp(0.400, 0.999).toStringAsFixed(3);
    final String primaryTag = job.tags.isNotEmpty ? job.tags.first.toUpperCase() : 'CORE';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainerHighest),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Analysis Ping + Timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.8),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SYS.FIT-ANALYSIS // v4.8',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 11, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'CALIBRATED ${job.postedTimeAgo.toUpperCase()}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Company Subsystem Tag & Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${job.company.toUpperCase()} // $primaryTag',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.public_rounded, size: 12, color: AppColors.tertiary),
                            const SizedBox(width: 3),
                            Text(
                              'HQ: ${job.location.toUpperCase()} ${job.isRemote ? '/ REMOTE' : ''}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      job.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.insights_rounded, color: AppColors.secondary, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Live Resonance Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.9),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      job.matchScore >= 85
                          ? 'HIGH COGNITIVE RESONANCE'
                          : job.matchScore >= 70
                              ? 'OPTIMAL VECTOR HARMONY'
                              : 'MODERATE VECTOR SYNCHRONY',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$phiValue Φ',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
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

  // ── Hero Pulse Engine (SVG Waveform + 4 High-Density Telemetry Tiles) ──
  Widget _buildHeroPulseEngine(JobModel job) {
    final amplitude = job.matchScore.toDouble();
    final cosineValue = (amplitude / 100 * 0.98).clamp(0.4, 0.99).toStringAsFixed(3);
    final topRank = (100.0 - amplitude).clamp(0.8, 18.0).toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.15),
            blurRadius: 28,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.electric_bolt_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'NEURAL VECTOR SYNCHRONIZATION',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '99.4% CONF',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Central Score Gauge & Live Waveform
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final scoreWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        amplitude.toStringAsFixed(1),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.5,
                          height: 1.0,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '%',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'TOTAL FIT AMPLITUDE',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              );

              final waveformWidget = SizedBox(
                width: isNarrow ? constraints.maxWidth : 210,
                height: 60,
                child: const HarmonicPulseWaveform(width: 210, height: 60),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    scoreWidget,
                    const SizedBox(height: 12),
                    waveformWidget,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  scoreWidget,
                  waveformWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // 4-Cluster High Density Telemetry Tiles
          LayoutBuilder(
            builder: (context, constraints) {
              final isSingleColumn = constraints.maxWidth < 360;
              return GridView.count(
                crossAxisCount: isSingleColumn ? 2 : 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.8,
                children: [
                  _buildTelemetryTile(
                    label: 'Vector Cosine',
                    value: '$cosineValue RAD',
                    valueColor: AppColors.secondary,
                  ),
                  _buildTelemetryTile(
                    label: 'Query Latency',
                    value: '42ms',
                    valueColor: AppColors.primary,
                  ),
                  _buildTelemetryTile(
                    label: 'Market Rank',
                    value: 'Top $topRank% ILE',
                    valueColor: AppColors.onSurface,
                    accentColor: AppColors.secondary,
                  ),
                  _buildTelemetryTile(
                    label: 'Confidence Gap',
                    value: '±0.6%',
                    valueColor: AppColors.tertiary,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryTile({
    required String label,
    required String value,
    required Color valueColor,
    Color? accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── MOD_01 Core DNA Match Vectors ──
  Widget _buildMod01CoreDnaVectors(JobModel job) {
    // Generate 4 vectors dynamically from whyItFits or defaults
    final List<Map<String, dynamic>> vectors = [];
    final reasons = job.whyItFits;

    final defaultTitles = [
      'Go / Concurrency & Memory Primitives',
      'Consensus Algorithms (Raft / Paxos)',
      'Kubernetes, Envoy & Mesh Topologies',
      'Streaming Fabrics (Apache Kafka / Flink)',
    ];

    final defaultPcts = [98.0, 94.0, 92.0, 85.0];
    final defaultColors = [
      AppColors.secondary,
      AppColors.primary,
      AppColors.primary,
      AppColors.tertiary,
    ];

    for (int i = 0; i < 4; i++) {
      final title = (i < reasons.length && reasons[i].isNotEmpty) ? reasons[i] : defaultTitles[i];
      vectors.add({
        'title': title,
        'pct': defaultPcts[i],
        'color': defaultColors[i],
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainerHighest),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '// MOD_01',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CORE DNA MATCH VECTORS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '4 VALIDATED',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...vectors.map((vec) {
            final title = vec['title'] as String;
            final pct = vec['pct'] as double;
            final color = vec['color'] as Color;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${pct.toInt()}%',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  SegmentedLedBar(
                    totalSegments: 10,
                    percentage: pct,
                    activeColor: color,
                    inactiveColor: AppColors.surfaceContainerHighest,
                    height: 8,
                    gap: 3.5,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── MOD_02 Tactical Bridge Vectors ──
  Widget _buildMod02TacticalBridge(JobModel job) {
    final pitchSnippet = job.tailoredPitch.isNotEmpty
        ? job.tailoredPitch
        : 'Emphasize memory profiling & pprof flamegraphs in Project Argon to proactively disarm low-level C++ allocator inquiries.';

    final gapSnippet = job.skillGaps.isNotEmpty
        ? 'Bridge Vector: Address ${job.skillGaps.join(" and ")} by anchoring to your RFC architectural leadership.'
        : 'Highlight your multi-region failover RFC to match high-availability financial ledger reliability standards.';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '// MOD_02',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TACTICAL BRIDGE VECTORS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.done_all_rounded, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text(
                    'PRE-EMPTIVE',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTacticalCard(
            tag: 'VECTOR 01 // PROFILING',
            tagColor: AppColors.primary,
            metric: '+6.2% WIN RATIO',
            metricColor: AppColors.secondary,
            content: pitchSnippet,
          ),
          const SizedBox(height: 8),
          _buildTacticalCard(
            tag: 'VECTOR 02 // ARCH_ALIGNMENT',
            tagColor: AppColors.tertiary,
            metric: '5-NINES ALIGNED',
            metricColor: AppColors.secondary,
            content: gapSnippet,
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalCard({
    required String tag,
    required Color tagColor,
    required String metric,
    required Color metricColor,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: tagColor,
                  ),
                ),
              ),
              Text(
                metric,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: metricColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.45,
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── MOD_03 Velocity & Rhythm Sync ──
  Widget _buildMod03VelocityDynamics(JobModel job) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '// MOD_03',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'VELOCITY & RHYTHM SYNC',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '1.04x TEAM MEDIAN',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildVelocityCard(
                  percentage: '96%',
                  label: 'Async-First Flow',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildVelocityCard(
                  percentage: '94%',
                  label: 'Bias to Ship',
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildVelocityCard(
                  percentage: '98%',
                  label: 'RFC Discipline',
                  color: AppColors.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVelocityCard({
    required String percentage,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        children: [
          Text(
            percentage,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── MOD_04 Predicted Interview Gauntlets ──
  Widget _buildMod04PredictedGauntlets(JobModel job) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '// MOD_04',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PREDICTED INTERVIEW GAUNTLETS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                'HIGH PROBABILITY',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGauntletItem(
            title: '1. Distributed Transaction Partitioning',
            rating: 4,
            label: 'HARD',
            activeColor: AppColors.secondary,
            anchorText: 'Walk through idempotency key caching & consensus under high write loads.',
          ),
          const SizedBox(height: 8),
          _buildGauntletItem(
            title: '2. Live Coding: Low-Latency Token Bucket',
            rating: 5,
            label: 'INTENSE',
            activeColor: AppColors.error,
            anchorText: 'Redis cluster synchronization tradeoffs vs localized sliding windows.',
          ),
          const SizedBox(height: 8),
          _buildGauntletItem(
            title: '3. Split-Brain Recovery Scenarios',
            rating: 3,
            label: 'MEDIUM',
            activeColor: AppColors.tertiary,
            anchorText: 'Explicit quorum loss mitigations and state reconcile checkpoints.',
          ),
        ],
      ),
    );
  }

  Widget _buildGauntletItem({
    required String title,
    required int rating,
    required String label,
    required Color activeColor,
    required String anchorText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DifficultyGauntletDots(
                rating: rating,
                label: label,
                activeColor: activeColor,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ANCHOR: ',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: Text(
                  anchorText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Raw Description & Recruiter Pitch View (Tab 1)
  // ─────────────────────────────────────────────────────────
  Widget _buildRawDescriptionView(BuildContext context, JobModel job) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compensation & Location Pill Row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceContainerHighest),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildMetaItem(Icons.attach_money_rounded, 'Comp Band', job.formattedSalary),
                _buildMetaItem(Icons.location_on_outlined, 'Location', job.location),
                _buildMetaItem(
                  Icons.wifi_tethering_rounded,
                  'Remote',
                  job.isRemote ? 'Remote First' : 'On-Site / Hybrid',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tailored Elevator Pitch
          Text(
            'TAILORED STRATEGIC ELEVATOR PITCH',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: SelectableText(
              job.tailoredPitch,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                height: 1.5,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recruiter Message Template with Copy Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COLD DM / OUTREACH TEMPLATE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.secondary,
                ),
              ),
              TextButton.icon(
                onPressed: () => _copyToClipboard(
                  job.recruiterMessage,
                  'RECRUITER PITCH COPIED TO SYSTEM CLIPBOARD',
                ),
                icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.secondary),
                label: Text(
                  'Copy Pitch',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceContainerHighest),
            ),
            child: SelectableText(
              job.recruiterMessage,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11.5,
                height: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Full Role Specification
          Text(
            'FULL ROLE SPECIFICATION & TAXONOMY',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceContainerHighest),
            ),
            child: SelectableText(
              job.fullDescription,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                height: 1.6,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: foliageMainAxisSize(),
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  MainAxisSize foliageMainAxisSize() => MainAxisSize.min;

  // ─────────────────────────────────────────────────────────
  // Pinned Tactical Action Dock
  // ─────────────────────────────────────────────────────────
  Widget _buildTacticalActionDock(BuildContext context, JobModel job) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: AppColors.surfaceContainerHighest, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Notification Toast Element (200 OK telemetry)
          if (_toastMessage != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _toastMessage!,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '200 OK',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Primary CTA Button: Auto-Calibrate Resume to Vector with animated shimmer
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryContainer.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      _showTelemetryToast('RESUME RE-INDEXED: +4.8% TAXONOMY ALIGNMENT ACHIEVED');
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment(-1.0 + (_shimmerController.value * 2.5), -0.3),
                          end: Alignment(1.0 + (_shimmerController.value * 2.5), 0.3),
                          colors: const [
                            AppColors.primaryContainer,
                            Color(0xFF38BDF8),
                            AppColors.primaryContainer,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 18,
                            color: AppColors.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AUTO-CALIBRATE RESUME TO VECTOR',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Secondary Quick-Action Row (1-Click Cold DM, Export Dossier, Apply Direct)
          Row(
            children: [
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: AppColors.primary,
                  label: '1-Click Cold DM',
                  onPressed: () => _copyToClipboard(
                    job.recruiterMessage,
                    'RECRUITER PITCH COPIED TO SYSTEM CLIPBOARD',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.download_rounded,
                  iconColor: AppColors.tertiary,
                  label: 'Export Dossier',
                  onPressed: () {
                    final dossierDump =
                        '// DIAGNOSTIC DOSSIER EXPORT\n'
                        'ROLE: ${job.title}\n'
                        'COMPANY: ${job.company}\n'
                        'FIT AMPLITUDE: ${job.matchScore}%\n'
                        'URL: ${job.applicationUrl}\n';
                    _copyToClipboard(dossierDump, 'COMPILING ENCRYPTED DOSSIER (PDF/JSON)...');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.open_in_new_rounded,
                  iconColor: job.isApplied ? AppColors.secondary : AppColors.primary,
                  label: job.isApplied ? 'Applied ✓' : 'Direct Apply',
                  onPressed: () {
                    context.read<JobBloc>().add(MarkJobApplied(job.id));
                    _showTelemetryToast('APPLICATION INITIATED IN BROWSER');
                    _launchUrl(job.applicationUrl);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceContainerHighest),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
