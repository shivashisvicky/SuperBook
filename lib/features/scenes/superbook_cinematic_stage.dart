import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/experience/ai_scene_plan.dart';

class SuperBookCinematicStage extends StatefulWidget {
  const SuperBookCinematicStage({
    super.key,
    required this.imageBase64,
    required this.plan,
  });

  final String imageBase64;
  final AiScenePlan plan;

  @override
  State<SuperBookCinematicStage> createState() => _SuperBookCinematicStageState();
}

class _SuperBookCinematicStageState extends State<SuperBookCinematicStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bytes = base64Decode(widget.imageBase64);
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final eased = Curves.easeInOutCubic.transform(_controller.value);
          final movement = _movement(widget.plan.camera.movement);
          final breathe = math.sin(eased * math.pi) * 0.006;
          final scale =
              1.045 + movement.zoom * math.sin(eased * math.pi) + breathe;
          final dx = movement.x * (eased - 0.5);
          final dy = movement.y * (eased - 0.5);

          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: const Color(0xFF080A0E),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(dx, dy)
                    ..scale(scale, scale),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _CinematicAtmospherePainter(
                    progress: eased,
                    intensity: _atmosphereIntensity(widget.plan),
                  ),
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.10),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.38),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  ({double x, double y, double zoom}) _movement(String value) {
    final text = value.toLowerCase();
    if (text.contains('pan left')) return (x: -22, y: 3, zoom: 0.010);
    if (text.contains('pan right')) return (x: 22, y: 3, zoom: 0.010);
    if (text.contains('tilt')) return (x: 5, y: -12, zoom: 0.008);
    if (text.contains('pull')) return (x: 8, y: 3, zoom: 0.006);
    return (x: -8, y: -3, zoom: 0.012);
  }

  double _atmosphereIntensity(AiScenePlan plan) {
    final text = '${plan.lighting} ${plan.motion}'.toLowerCase();
    if (text.contains('rain') || text.contains('storm')) return 0.85;
    if (text.contains('fire') || text.contains('candle')) return 0.65;
    return 0.35;
  }
}

class _CinematicAtmospherePainter extends CustomPainter {
  const _CinematicAtmospherePainter({
    required this.progress,
    required this.intensity,
  });

  final double progress;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = math.sin(progress * math.pi);
    final glow = Paint()
      ..shader = RadialGradient(
        center: Alignment(-0.38 + progress * 0.35, -0.34),
        radius: 0.72,
        colors: [
          Colors.white.withValues(alpha: 0.055 * intensity * pulse),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);

    if (intensity < 0.7) return;

    final particlePaint =
        Paint()..color = Colors.white.withValues(alpha: 0.055 * intensity);
    for (var i = 0; i < 18; i++) {
      final seed = (i * 37) % 101;
      final x = ((seed / 100) + progress * 0.08) % 1.0;
      final y = ((i * 0.173 + progress * 0.42) % 1.0);
      final radius = 0.7 + (i % 3) * 0.45;
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        radius,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CinematicAtmospherePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity;
}
