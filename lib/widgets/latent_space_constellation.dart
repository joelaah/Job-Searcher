import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/job_bloc.dart';
import '../models/job_model.dart';
import '../theme/app_colors.dart';
import 'job_detail_dialog.dart';

class LatentSpaceConstellation extends StatefulWidget {
  final List<JobModel> jobs;
  final double vectorShiftMagnitude;

  const LatentSpaceConstellation({
    super.key,
    required this.jobs,
    required this.vectorShiftMagnitude,
  });

  @override
  State<LatentSpaceConstellation> createState() => _LatentSpaceConstellationState();
}

class _LatentSpaceConstellationState extends State<LatentSpaceConstellation> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  JobModel? _hoveredJob;
  Offset? _hoverPos;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _openJobDetail(JobModel job) {
    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<JobBloc>(),
        child: JobDetailDialog(job: job),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobs = widget.jobs.take(8).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        double? tooltipLeft;
        double? tooltipRight;
        double? tooltipTop;

        if (_hoveredJob != null && _hoverPos != null) {
          final hx = _hoverPos!.dx;
          final hy = _hoverPos!.dy;

          // Flip to left if node is on the right hemisphere
          if (hx > width * 0.45) {
            tooltipRight = (width - hx + 12).clamp(8.0, width - 20.0);
          } else {
            tooltipLeft = (hx + 12).clamp(8.0, width - 20.0);
          }

          tooltipTop = (hy - 50).clamp(8.0, height - 70.0);
        }

        return MouseRegion(
          onHover: (event) {
            final localPos = event.localPosition;
            final center = Offset(width / 2, height / 2);
            final maxRadius = math.min(width, height) * 0.44;

            JobModel? foundJob;
            Offset? foundPos;
            for (int i = 0; i < jobs.length; i++) {
              final job = jobs[i];
              final score = job.matchScore.clamp(50, 100);
              final distanceNorm = 1.0 - ((score - 50) / 50.0);
              final r = 32.0 + distanceNorm * (maxRadius - 32.0);
              final baseAngle = (i * (2 * math.pi / jobs.length)) - (math.pi / 2);
              final angle = baseAngle + (widget.vectorShiftMagnitude * 0.3);
              final nodePos = Offset(
                center.dx + r * math.cos(angle),
                center.dy + r * math.sin(angle),
              );

              if ((localPos - nodePos).distance < 24) {
                foundJob = job;
                foundPos = nodePos;
                break;
              }
            }

            if (foundJob != _hoveredJob) {
              setState(() {
                _hoveredJob = foundJob;
                _hoverPos = foundPos ?? localPos;
              });
            }
          },
          onExit: (_) {
            if (_hoveredJob != null) {
              setState(() {
                _hoveredJob = null;
                _hoverPos = null;
              });
            }
          },
          child: GestureDetector(
            onTapUp: (details) {
              if (_hoveredJob != null) {
                _openJobDetail(_hoveredJob!);
              }
            },
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: _ConstellationPainter(
                        jobs: jobs,
                        animProgress: _animController.value,
                        vectorShift: widget.vectorShiftMagnitude,
                        hoveredJobId: _hoveredJob?.id,
                      ),
                    );
                  },
                ),

                // Smart Floating Tooltip (Flips away from edges & wraps cleanly)
                if (_hoveredJob != null && _hoverPos != null)
                  Positioned(
                    left: tooltipLeft,
                    right: tooltipRight,
                    top: tooltipTop,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: math.min(240.0, width * 0.65),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF040E16).withAlpha(245),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.secondary, width: 1.3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withAlpha(60),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                          const BoxShadow(
                            color: Color(0x90000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _hoveredJob!.company,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.cyanAccent,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withAlpha(35),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.secondary.withAlpha(90)),
                                ),
                                child: Text(
                                  '${_hoveredJob!.matchScore}%',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _hoveredJob!.title,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app_outlined, size: 10, color: AppColors.textMuted),
                              SizedBox(width: 3),
                              Text(
                                'Click to inspect fit & pitch',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  color: AppColors.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Mini Inspector Banner at bottom for 100% full unclipped visibility
                if (_hoveredJob != null)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: const Color(0xEE030A0F),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withAlpha(90)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.matchHigh,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: AppColors.matchHigh, blurRadius: 4)],
                              ),
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                '${_hoveredJob!.company} • ${_hoveredJob!.title}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_hoveredJob!.matchScore}%',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
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
          ),
        );
      },
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  final List<JobModel> jobs;
  final double animProgress;
  final double vectorShift;
  final String? hoveredJobId;

  _ConstellationPainter({
    required this.jobs,
    required this.animProgress,
    required this.vectorShift,
    this.hoveredJobId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.44;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.surfaceBorder.withAlpha(70)
      ..strokeWidth = 1.0;

    // Draw orbital rings
    final rings = [0.35, 0.65, 0.95];
    for (var factor in rings) {
      canvas.drawCircle(center, maxRadius * factor, ringPaint);
    }

    // Crosshairs
    final crossHairPaint = Paint()
      ..color = AppColors.surfaceBorder.withAlpha(40)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(center.dx - maxRadius, center.dy), Offset(center.dx + maxRadius, center.dy), crossHairPaint);
    canvas.drawLine(Offset(center.dx, center.dy - maxRadius), Offset(center.dx, center.dy + maxRadius), crossHairPaint);

    // Center Node: Candidate Resume Vector
    final centerGlow = Paint()
      ..color = AppColors.secondary.withAlpha(45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, 18 + math.sin(animProgress * math.pi * 2) * 2, centerGlow);

    final centerPaint = Paint()..color = AppColors.secondary;
    canvas.drawCircle(center, 10, centerPaint);

    final innerCenterPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 4, innerCenterPaint);

    // Plot Job Celestial Nodes
    for (int i = 0; i < jobs.length; i++) {
      final job = jobs[i];
      final isHovered = job.id == hoveredJobId;
      final score = job.matchScore.clamp(50, 100);
      final distanceNorm = 1.0 - ((score - 50) / 50.0);
      final r = 32.0 + distanceNorm * (maxRadius - 32.0);
      final baseAngle = (i * (2 * math.pi / jobs.length)) - (math.pi / 2);
      final angle = baseAngle + (vectorShift * 0.3) + math.sin(animProgress * math.pi * 2 + i) * 0.04;

      final nodePos = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );

      final isHighFit = score >= 90;
      final nodeColor = isHighFit ? AppColors.secondary : (score >= 75 ? AppColors.cyanAccent : AppColors.primary);

      // Connect top 3 closest jobs to center with laser synapse line
      if (i < 3) {
        final linePaint = Paint()
          ..color = nodeColor.withAlpha(isHovered ? 160 : 70)
          ..strokeWidth = isHovered ? 1.8 : 1.0;
        canvas.drawLine(center, nodePos, linePaint);

        // Animated traveling photon on line
        final photonT = (animProgress * 1.5 + (i * 0.33)) % 1.0;
        final photonPos = Offset.lerp(center, nodePos, photonT)!;
        final photonPaint = Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(photonPos, 2.5, photonPaint);
      }

      // Outer glow of star node
      if (isHovered || isHighFit) {
        final nodeGlow = Paint()
          ..color = nodeColor.withAlpha(isHovered ? 90 : 50)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, isHovered ? 12 : 6);
        canvas.drawCircle(nodePos, isHovered ? 16 : 10, nodeGlow);
      }

      // Core star node
      final starPaint = Paint()..color = isHovered ? Colors.white : nodeColor;
      canvas.drawCircle(nodePos, isHovered ? 8 : (isHighFit ? 6.5 : 5.0), starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) {
    return true;
  }
}
