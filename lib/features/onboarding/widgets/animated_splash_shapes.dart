import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

class AnimatedSplashShapes extends StatefulWidget {
  const AnimatedSplashShapes({super.key});

  @override
  State<AnimatedSplashShapes> createState() => _AnimatedSplashShapesState();
}

class _AnimatedSplashShapesState extends State<AnimatedSplashShapes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _SplashShapesPainter(_controller.value),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _SplashShapesPainter extends CustomPainter {
  const _SplashShapesPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final darkStroke = Paint()
      ..color = AppColors.primaryContainer.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final emeraldStroke = Paint()
      ..color = AppColors.emerald.withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final softFill = Paint()
      ..color = AppColors.emerald.withValues(alpha: .055)
      ..style = PaintingStyle.fill;

    _drawDiamond(
      canvas,
      center: Offset(size.width * .27, size.height * .34),
      side: 42 + math.sin(t * math.pi * 2) * 5,
      rotation: t * math.pi * 2,
      paint: emeraldStroke,
    );
    _drawDiamond(
      canvas,
      center: Offset(size.width * .72, size.height * .42),
      side: 34 + math.cos(t * math.pi * 2) * 4,
      rotation: -t * math.pi * 2,
      paint: darkStroke,
    );
    _drawRoundedBar(
      canvas,
      center: Offset(
        size.width * (.18 + math.sin(t * math.pi * 2) * .012),
        size.height * .63,
      ),
      width: 112,
      height: 12,
      rotation: -.16,
      paint: softFill,
    );
    _drawRoundedBar(
      canvas,
      center: Offset(
        size.width * (.82 + math.cos(t * math.pi * 2) * .012),
        size.height * .27,
      ),
      width: 86,
      height: 10,
      rotation: .22,
      paint: softFill,
    );
    _drawCornerGlyph(
      canvas,
      origin: Offset(size.width * .34, size.height * .22),
      size: 38,
      phase: t,
      paint: emeraldStroke,
    );
    _drawCornerGlyph(
      canvas,
      origin: Offset(size.width * .62, size.height * .67),
      size: 32,
      phase: 1 - t,
      paint: darkStroke,
    );
  }

  void _drawDiamond(
    Canvas canvas, {
    required Offset center,
    required double side,
    required double rotation,
    required Paint paint,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final half = side / 2;
    final path = Path()
      ..moveTo(0, -half)
      ..lineTo(half, 0)
      ..lineTo(0, half)
      ..lineTo(-half, 0)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawRoundedBar(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required double rotation,
    required Paint paint,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      paint,
    );
    canvas.restore();
  }

  void _drawCornerGlyph(
    Canvas canvas, {
    required Offset origin,
    required double size,
    required double phase,
    required Paint paint,
  }) {
    final drift = math.sin(phase * math.pi * 2) * 5;
    final x = origin.dx + drift;
    final y = origin.dy - drift;
    final short = size * .38;

    canvas.drawLine(Offset(x, y), Offset(x + short, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + short), paint);
    canvas.drawLine(
      Offset(x + size, y + size),
      Offset(x + size - short, y + size),
      paint,
    );
    canvas.drawLine(
      Offset(x + size, y + size),
      Offset(x + size, y + size - short),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SplashShapesPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
