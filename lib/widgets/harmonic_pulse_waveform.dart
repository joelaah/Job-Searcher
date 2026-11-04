import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Real-Time Harmonic Pulse Display rendering the exact 192x64 SVG telemetry waveform
/// with animated breathing pulse and a glowing indicator node at (106, 56).
class HarmonicPulseWaveform extends StatefulWidget {
  final double width;
  final double height;
  final Color primaryGlow;
  final Color secondaryGlow;

  const HarmonicPulseWaveform({
    super.key,
    this.width = 192,
    this.height = 64,
    this.primaryGlow = AppColors.primary,
    this.secondaryGlow = AppColors.secondary,
  });

  @override
  State<HarmonicPulseWaveform> createState() => _HarmonicPulseWaveformState();
}

class _HarmonicPulseWaveformState extends State<HarmonicPulseWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _HarmonicPulsePainter(
            pulseValue: _animController.value,
            primaryColor: widget.primaryGlow,
            secondaryColor: widget.secondaryGlow,
          ),
        );
      },
    );
  }
}

class _HarmonicPulsePainter extends CustomPainter {
  final double pulseValue;
  final Color primaryColor;
  final Color secondaryColor;

  _HarmonicPulsePainter({
    required this.pulseValue,
    required this.primaryColor,
    required this.secondaryColor,
  });

  static const List<Offset> _rawSvgPoints = [
    Offset(0, 32),
    Offset(20, 32),
    Offset(32, 16),
    Offset(40, 48),
    Offset(48, 22),
    Offset(56, 40),
    Offset(64, 32),
    Offset(90, 32),
    Offset(98, 8),
    Offset(106, 56),
    Offset(114, 24),
    Offset(122, 38),
    Offset(130, 32),
    Offset(192, 32),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 192.0;
    final sy = size.height / 64.0;

    // Subtle breathing factor for peak heights
    final breath = math.sin(pulseValue * math.pi) * 0.08;

    final path = Path();
    for (int i = 0; i < _rawSvgPoints.length; i++) {
      final raw = _rawSvgPoints[i];
      // Modulate y slightly based on deviation from baseline 32 to simulate live pulse breathing
      final dyFromBaseline = raw.dy - 32.0;
      final animatedDy = 32.0 + dyFromBaseline * (1.0 + breath);
      final pt = Offset(raw.dx * sx, animatedDy * sy);

      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }

    // 1. Shadow / Glow Pass for the line
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * ((sx + sy) / 2)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = secondaryColor.withValues(alpha: (0.45 + (0.25 * pulseValue)).clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    canvas.drawPath(path, glowPaint);

    // 2. Linear Gradient Stroke Pass
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        primaryColor.withValues(alpha: 0.3),
        secondaryColor.withValues(alpha: 0.95),
        primaryColor.withValues(alpha: 0.4),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * ((sx + sy) / 2)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, linePaint);

    // 3. Pulsing Node at (106, 56)
    final nodeBaseDy = 32.0 + (56.0 - 32.0) * (1.0 + breath);
    final nodePos = Offset(106.0 * sx, nodeBaseDy * sy);

    final baseRadius = 3.5 * ((sx + sy) / 2);
    final currentRadius = baseRadius + (1.2 * pulseValue);

    // Halo outer glow
    final haloPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = secondaryColor.withValues(alpha: (0.35 * (1.0 - pulseValue * 0.3)).clamp(0.0, 1.0))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.0 + 4.0 * pulseValue);

    canvas.drawCircle(nodePos, currentRadius + 3.0, haloPaint);

    // Node inner core
    final corePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = secondaryColor;

    canvas.drawCircle(nodePos, currentRadius, corePaint);

    // Crisp white-hot center spark
    final sparkPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: (0.7 + 0.3 * pulseValue).clamp(0.0, 1.0));

    canvas.drawCircle(nodePos, currentRadius * 0.45, sparkPaint);
  }

  @override
  bool shouldRepaint(covariant _HarmonicPulsePainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
