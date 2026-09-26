import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../domain/experience/ai_scene_plan.dart';
import '../../services/scene_generation/scene_generation_provider.dart';

class SuperBookCinematicStage extends StatefulWidget {
  const SuperBookCinematicStage({
    super.key,
    required this.imageBase64,
    required this.plan,
    this.motionFrames = const <GeneratedMotionFrame>[],
  });

  final String imageBase64;
  final AiScenePlan plan;
  final List<GeneratedMotionFrame> motionFrames;

  @override
  State<SuperBookCinematicStage> createState() => _SuperBookCinematicStageState();
}

class _SuperBookCinematicStageState extends State<SuperBookCinematicStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<Uint8List> _frameBytes = const [];
  Uint8List? _singleBytes;

  @override
  void initState() {
    super.initState();
    _singleBytes = base64Decode(widget.imageBase64);
    _frameBytes = widget.motionFrames
        .map((frame) => base64Decode(frame.base64))
        .toList(growable: false);
    final seconds = math.max(5.0, widget.motionFrames.length * 1.8);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (seconds * 1000).round()),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant SuperBookCinematicStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBase64 != widget.imageBase64 ||
        oldWidget.motionFrames.length != widget.motionFrames.length) {
      _singleBytes = base64Decode(widget.imageBase64);
      _frameBytes = widget.motionFrames
          .map((frame) => base64Decode(frame.base64))
          .toList(growable: false);
      final seconds = math.max(5.0, widget.motionFrames.length * 1.8);
      _controller.duration = Duration(milliseconds: (seconds * 1000).round());
      _controller
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frames = widget.motionFrames;
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (frames.isEmpty) {
            return _singleFrame();
          }
          return _motionStory(frames);
        },
      ),
    );
  }

  Widget _singleFrame() {
    final bytes = _singleBytes ?? base64Decode(widget.imageBase64);
    final movement = _movement(widget.plan.camera.movement);
    final breathe = math.sin(_controller.value * math.pi * 2) * 0.004;
    final scale = 1.045 + movement.zoom + breathe;
    final drift = math.sin(_controller.value * math.pi * 2);

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: const Color(0xFF080A0E),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translateByDouble(
                movement.x * drift,
                movement.y * drift,
                0,
                1,
              )
              ..scaleByDouble(scale, scale, 1, 1),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: _CinematicAtmospherePainter(
              progress: _controller.value,
              intensity: _atmosphereIntensity(widget.plan),
            ),
          ),
        ),
      ],
    );
  }

  Widget _motionStory(List<GeneratedMotionFrame> frames) {
    final position = _controller.value * frames.length;
    final index = position.floor().clamp(0, frames.length - 1);
    final local = position - index;
    final next = (index + 1) % frames.length;

    // Hold each AI-authored acting state, then smoothly hand the scene to the
    // next state. The crossfade is deliberately short so the page reads as a
    // moving story moment rather than a slideshow.
    final blend = Curves.easeInOutCubic.transform(
      ((local - 0.52) / 0.48).clamp(0.0, 1.0),
    );

    final current = _frameBytes[index];
    final following = _frameBytes[next];
    final drift = math.sin((position + 0.2) * math.pi * 2) * 0.006;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: const Color(0xFF080A0E),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _frameImage(current, 1.0 - blend, drift),
              _frameImage(following, blend, -drift),
            ],
          ),
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: _CinematicAtmospherePainter(
              progress: position / frames.length,
              intensity: _atmosphereIntensity(widget.plan),
            ),
          ),
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .32),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Text(
                  frames[index].beat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _frameImage(Uint8List bytes, double opacity, double drift) {
    final scale = 1.035 + math.sin(_controller.value * math.pi * 2) * .006;
    return Opacity(
      opacity: opacity,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..translateByDouble(drift * 80, drift * 35, 0, 1)
          ..scaleByDouble(scale, scale, 1, 1),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  ({double x, double y, double zoom}) _movement(String value) {
    final text = value.toLowerCase();
    if (text.contains('pan left')) return (x: -22, y: 3, zoom: .010);
    if (text.contains('pan right')) return (x: 22, y: 3, zoom: .010);
    if (text.contains('tilt')) return (x: 5, y: -12, zoom: .008);
    if (text.contains('pull')) return (x: 8, y: 3, zoom: .006);
    return (x: -8, y: -3, zoom: .012);
  }

  double _atmosphereIntensity(AiScenePlan plan) {
    final text = (plan.lighting + ' ' + plan.motion).toLowerCase();
    if (text.contains('rain') || text.contains('storm')) return .85;
    if (text.contains('fire') || text.contains('candle')) return .65;
    return .35;
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
    final pulse = math.sin(progress * math.pi * 2);
    final glow = Paint()
      ..shader = RadialGradient(
        center: Alignment(-.38 + progress * .35, -.34),
        radius: .72,
        colors: [
          Colors.white.withValues(alpha: .055 * intensity * (pulse.abs() * .5 + .5)),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(_CinematicAtmospherePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.intensity != intensity;
}
