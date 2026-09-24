import 'dart:convert';

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

class _SuperBookCinematicStageState extends State<SuperBookCinematicStage> {
  @override
  Widget build(BuildContext context) {
    final bytes = base64Decode(widget.imageBase64);
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: const Color(0xFF080A0E),
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
      ),
    );
  }
}

