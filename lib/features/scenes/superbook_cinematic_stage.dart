import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../domain/experience/ai_scene_plan.dart';
import '../../services/scene_generation/scene_generation_provider.dart';

class SuperBookCinematicStage extends StatefulWidget {
  const SuperBookCinematicStage({
    super.key,
    required this.imageBase64,
    required this.plan,
    this.motionFrames = const [],
  });

  final String imageBase64;
  final AiScenePlan plan;
  final List<GeneratedMotionFrame> motionFrames;

  @override
  State<SuperBookCinematicStage> createState() => _SuperBookCinematicStageState();
}

class _SuperBookCinematicStageState extends State<SuperBookCinematicStage> {
  Timer? _timer;
  int _frameIndex = -1;

  bool get _hasMotion => widget.motionFrames.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _startMotion();
  }

  @override
  void didUpdateWidget(covariant SuperBookCinematicStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motionFrames != widget.motionFrames) {
      _startMotion();
    }
  }

  void _startMotion() {
    _timer?.cancel();
    _frameIndex = -1;
    if (!_hasMotion) return;

    _timer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted) return;
      setState(() {
        _frameIndex = (_frameIndex + 1) % widget.motionFrames.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialBytes = base64Decode(widget.imageBase64);
    final frame = _frameIndex >= 0 && _frameIndex < widget.motionFrames.length
        ? widget.motionFrames[_frameIndex]
        : null;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: const Color(0xFF080A0E),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 900),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: frame == null
                  ? Image.memory(
                      initialBytes,
                      key: const ValueKey('keyframe'),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 42,
                        ),
                      ),
                    )
                  : Image.memory(
                      base64Decode(frame.base64),
                      key: ValueKey(Object.hash(frame.beat, _frameIndex)),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
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
          if (_hasMotion)
            const Positioned(
              top: 18,
              right: 18,
              child: _MotionBadge(),
            ),
        ],
      ),
    );
  }
}

class _MotionBadge extends StatelessWidget {
  const _MotionBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xCC0A0D13),
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_motion, size: 14),
            SizedBox(width: 6),
            Text('AI motion', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
