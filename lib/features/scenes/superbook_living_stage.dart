import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/experience/ai_scene_plan.dart';
import '../../services/scene_generation/puppet_asset_provider.dart';

/// The scene image is the environment. Characters are AI-authored pose sheets
/// and are animated locally by this runtime. AI is never called per frame.
class SuperBookLivingStage extends StatefulWidget {
  const SuperBookLivingStage({
    super.key,
    required this.imageBase64,
    required this.plan,
    required this.endpoint,
  });

  final String imageBase64;
  final AiScenePlan plan;
  final String endpoint;

  @override
  State<SuperBookLivingStage> createState() => _SuperBookLivingStageState();
}

class _SuperBookLivingStageState extends State<SuperBookLivingStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<_PoseSheet> _sheets = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    unawaited(_loadAssets());
  }

  @override
  void didUpdateWidget(covariant SuperBookLivingStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCharacters = oldWidget.plan.characters
        .map((character) =>
            '\${character.id}|\${character.description}|\${character.action}|\${character.emotion}')
        .join('||');
    final newCharacters = widget.plan.characters
        .map((character) =>
            '\${character.id}|\${character.description}|\${character.action}|\${character.emotion}')
        .join('||');

    if (oldCharacters != newCharacters ||
        oldWidget.imageBase64 != widget.imageBase64) {
      unawaited(_loadAssets());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final sheet in _sheets) {
      sheet.image.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAssets() async {
    final characters = widget.plan.characters.take(2).toList(growable: false);
    if (characters.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final provider = PuppetAssetProvider(endpoint: widget.endpoint);
      final generated = await Future.wait(
        characters.map(
          (character) => provider.generate(
            character: [
              character.description,
              'Primary action: \${character.action}.',
              'Emotion: \${character.emotion}.',
              'Stage position: \${character.position}.',
            ].join(' '),
          ),
        ),
      );

      final decoded = <_PoseSheet>[];
      for (final sheet in generated) {
        final bytes = base64Decode(sheet.base64);
        final image = await _decodeAndChromaKey(bytes);
        decoded.add(_PoseSheet(image));
      }

      if (!mounted) {
        for (final sheet in decoded) {
          sheet.image.dispose();
        }
        return;
      }

      final old = _sheets;
      setState(() {
        _sheets = List.unmodifiable(decoded);
        _loading = false;
      });
      for (final sheet in old) {
        sheet.image.dispose();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<ui.Image> _decodeAndChromaKey(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 1024,
      targetHeight: 1024,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final raw = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    image.dispose();
    codec.dispose();

    if (raw == null) {
      throw StateError('Unable to decode animation pose sheet.');
    }

    final pixels = Uint8List.fromList(raw.buffer.asUint8List());
    for (var i = 0; i + 3 < pixels.length; i += 4) {
      final r = pixels[i];
      final g = pixels[i + 1];
      final b = pixels[i + 2];

      if (b > 125 && b > r * 1.35 && b > g * 1.15) {
        pixels[i] = 0;
        pixels[i + 1] = 0;
        pixels[i + 2] = 0;
        pixels[i + 3] = 0;
      }
    }

    return ui.decodeImageFromPixelsSync(
      pixels,
      1024,
      1024,
      ui.PixelFormat.rgba8888,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: const Color(0xFF05070B),
          child: Image.memory(
            base64Decode(widget.imageBase64),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.high,
          ),
        ),
        if (_sheets.isNotEmpty)
          CustomPaint(
            painter: _LivingCharacterPainter(
              animation: _controller,
              plan: widget.plan,
              sheets: _sheets,
            ),
            willChange: true,
            isComplex: true,
          ),
        if (_loading)
          const Positioned(
            left: 16,
            top: 16,
            child: SafeArea(
              bottom: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x55000000),
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    'Bringing the characters to life…',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PoseSheet {
  const _PoseSheet(this.image);

  final ui.Image image;
}

class _LivingCharacterPainter extends CustomPainter {
  _LivingCharacterPainter({
    required this.animation,
    required this.plan,
    required this.sheets,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final AiScenePlan plan;
  final List<_PoseSheet> sheets;

  static const int _columns = 4;
  static const int _rows = 2;
  static const double _frameRate = 8.0;
  static const double _beatSeconds = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < sheets.length; index++) {
      if (index >= plan.characters.length) break;
      _paintCharacter(
        canvas,
        size,
        sheets[index].image,
        plan.characters[index],
        index,
        sheets.length,
      );
    }
  }

  void _paintCharacter(
    Canvas canvas,
    Size size,
    ui.Image sheet,
    AiSceneCharacter character,
    int characterIndex,
    int characterCount,
  ) {
    final elapsed = animation.value * 18.0;
    final actions = _narrativeActions();
    final beatIndex = (elapsed / _beatSeconds).floor() % actions.length;
    final beatProgress =
        (elapsed - beatIndex * _beatSeconds) / _beatSeconds;
    final action = '\${actions[beatIndex]} \${character.action}'.toLowerCase();

    final position = _positionAnchor(
      character.position,
      characterIndex,
      characterCount,
    );
    final isWalk = _containsAny(action, const [
      'walk',
      'enter',
      'move',
      'approach',
      'cross',
      'traverse',
    ]);
    final isTalk = _containsAny(action, const [
      'talk',
      'speak',
      'say',
      'conversation',
    ]);
    final isGesture = _containsAny(action, const [
      'gesture',
      'point',
      'reach',
      'raise',
      'pick',
      'take',
    ]);
    final isReact = _containsAny(action, const [
      'react',
      'listen',
      'notice',
      'surprise',
      'look',
      'turn',
    ]);
    final isEat = _containsAny(action, const ['eat', 'drink']);

    final walkWave = math.sin(elapsed * math.pi * 2.0 * 1.25);
    final idleWave = math.sin(elapsed * math.pi * 2.0 * 0.55 + characterIndex);
    final walkOffset = isWalk
        ? ui.lerpDouble(-size.width * 0.11, size.width * 0.11, beatProgress)!
        : 0.0;

    final center = Offset(
      size.width * position + walkOffset,
      size.height * 0.68 + idleWave * size.height * 0.006,
    );

    final cellWidth = sheet.width / _columns;
    final cellHeight = sheet.height / _rows;
    final sequence = _poseSequence(
      isWalk: isWalk,
      isTalk: isTalk,
      isGesture: isGesture,
      isReact: isReact,
      isEat: isEat,
    );

    final poseTime = beatProgress * sequence.length;
    final posePosition = poseTime % sequence.length;
    final poseIndex = posePosition.floor();
    final poseA = sequence[poseIndex];
    final poseB = sequence[(poseIndex + 1) % sequence.length];
    final poseBlend = posePosition - poseIndex;

    final breathing =
        1.0 + math.sin(elapsed * math.pi * 2.0 * 0.7 + characterIndex) * 0.012;
    final stepBounce = isWalk ? (walkWave.abs() * 0.012) : 0.0;
    final scale = (size.height * 0.47 / cellHeight) * breathing;
    final angle = isWalk
        ? math.sin(elapsed * math.pi * 2.0 * 1.25) * 0.018
        : math.sin(elapsed * math.pi * 2.0 * 0.3) * 0.008;

    final centerWithBounce = center.translate(0, -stepBounce * size.height);

    _drawPose(
      canvas,
      sheet,
      Rect.fromLTWH(
        (poseA % _columns) * cellWidth,
        (poseA ~/ _columns) * cellHeight,
        cellWidth,
        cellHeight,
      ),
      centerWithBounce,
      scale,
      angle,
      opacity: 1.0 - poseBlend,
    );

    _drawPose(
      canvas,
      sheet,
      Rect.fromLTWH(
        (poseB % _columns) * cellWidth,
        (poseB ~/ _columns) * cellHeight,
        cellWidth,
        cellHeight,
      ),
      centerWithBounce,
      scale,
      angle,
      opacity: poseBlend,
    );
  }

  void _drawPose(
    Canvas canvas,
    ui.Image sheet,
    Rect source,
    Offset center,
    double scale,
    double rotation, {
    required double opacity,
  }) {
    final destination = Rect.fromCenter(
      center: center,
      width: source.width * scale,
      height: source.height * scale,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: opacity * 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          center.dx,
          destination.bottom - destination.height * 0.06,
        ),
        width: destination.width * 0.42,
        height: destination.height * 0.035,
      ),
      shadowPaint,
    );

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true
      ..color = Colors.white.withValues(alpha: opacity);

    canvas.drawImageRect(sheet, source, destination, paint);
    canvas.restore();
  }

  List<String> _narrativeActions() {
    final actions = <String>[
      ...plan.actions,
      ...plan.characters.map((character) => character.action),
    ]
        .map((action) => action.trim())
        .where((action) => action.isNotEmpty)
        .toList();

    if (actions.isEmpty) return const ['idle', 'idle', 'idle'];
    return actions.take(6).toList(growable: false);
  }

  List<int> _poseSequence({
    required bool isWalk,
    required bool isTalk,
    required bool isGesture,
    required bool isReact,
    required bool isEat,
  }) {
    if (isWalk) return const [2, 3, 2, 3];
    if (isTalk) return const [4, 5, 4, 5];
    if (isGesture) return const [4, 6, 4, 6];
    if (isReact) return const [1, 7, 1, 7];
    if (isEat) return const [4, 6, 4, 6];
    return const [0, 1, 0, 1];
  }

  bool _containsAny(String value, List<String> terms) =>
      terms.any(value.contains);

  double _positionAnchor(String position, int index, int count) {
    final value = position.toLowerCase();
    if (value.contains('far left') || value.contains('left')) return 0.29;
    if (value.contains('far right') || value.contains('right')) return 0.71;
    if (value.contains('center') || value.contains('middle')) return 0.50;
    if (count == 2) return index == 0 ? 0.34 : 0.66;
    return 0.50;
  }

  @override
  bool shouldRepaint(covariant _LivingCharacterPainter oldDelegate) =>
      oldDelegate.plan != plan || oldDelegate.sheets != sheets;
}
