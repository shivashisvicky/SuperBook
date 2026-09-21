import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/book.dart';

class ScenePlayerScreen extends StatefulWidget {
  const ScenePlayerScreen({super.key, required this.scene, required this.beat});
  final Scene scene;
  final NarrativeBeat beat;

  @override
  State<ScenePlayerScreen> createState() => _ScenePlayerScreenState();
}

class _ScenePlayerScreenState extends State<ScenePlayerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.scene.title),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _ScenePainter(
                progress: controller.value,
                intensity: widget.beat.intensity,
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Card(
                color: const Color(0xDD101522),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EXPERIENCE', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 5),
                      Text(widget.scene.caption, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(widget.scene.atmosphere),
                      Row(
                        children: [
                          Text('Narrative beat · intensity \${widget.beat.intensity}'),
                          const Spacer(),
                          IconButton(
                            tooltip: controller.isAnimating ? 'Pause scene' : 'Play scene',
                            onPressed: () {
                              if (controller.isAnimating) {
                                controller.stop();
                              } else {
                                controller.repeat();
                              }
                              setState(() {});
                            },
                            icon: Icon(
                              controller.isAnimating
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                            ),
                          ),
                        ],
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
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({required this.progress, required this.intensity});
  final double progress;
  final int intensity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0B1020));

    final horizon = size.height * 0.62;
    final radius = math.min(size.width, size.height) * 0.38;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD98A).withValues(alpha: 0.30),
          const Color(0xFFFFD98A).withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.56, horizon * 0.78),
          radius: radius,
        ),
      );
    canvas.drawCircle(Offset(size.width * 0.56, horizon * 0.78), radius, glow);

    canvas.drawRect(
      Rect.fromLTWH(0, horizon, size.width, size.height - horizon),
      Paint()..color = const Color(0xFF11151A),
    );

    final house = Path()
      ..moveTo(size.width * 0.30, horizon)
      ..lineTo(size.width * 0.30, horizon * 0.68)
      ..lineTo(size.width * 0.56, horizon * 0.52)
      ..lineTo(size.width * 0.82, horizon * 0.68)
      ..lineTo(size.width * 0.82, horizon)
      ..close();
    canvas.drawPath(house, Paint()..color = const Color(0xFF202632));

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.57, horizon * 0.75),
        width: size.width * 0.10,
        height: size.height * 0.08,
      ),
      Paint()..color = const Color(0xFFFFD98A),
    );

    final travelerX = size.width * (0.16 + 0.13 * math.sin(progress * math.pi * 2));
    final travelerY = horizon - size.height * 0.08;
    final traveler = Paint()..color = const Color(0xFFB8C0D4);
    canvas.drawCircle(Offset(travelerX, travelerY - 14), 7, traveler);
    traveler.strokeWidth = 4;
    canvas.drawLine(
      Offset(travelerX, travelerY - 7),
      Offset(travelerX, travelerY + 18),
      traveler,
    );

    final rain = Paint()
      ..color = const Color(0xFF8EA4C4).withValues(alpha: 0.32)
      ..strokeWidth = 1.4;
    final drops = 42 + intensity * 12;
    for (var i = 0; i < drops; i++) {
      final x = (i * 71.0) % size.width;
      final y = (i * 43.0 + progress * size.height * 1.8) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x - 8, y + 20), rain);
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.48)],
        stops: const [0.55, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.intensity != intensity;
}
