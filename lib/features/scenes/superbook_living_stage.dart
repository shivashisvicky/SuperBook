import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/experience/ai_scene_plan.dart';
import '../../services/scene_generation/puppet_asset_provider.dart';

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
  List<_PuppetSheet> _sheets = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    unawaited(_loadAssets());
  }

  @override
  void didUpdateWidget(covariant SuperBookLivingStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plan.characters.length != widget.plan.characters.length ||
        oldWidget.plan.characters.map((e) => e.description).join('|') !=
            widget.plan.characters.map((e) => e.description).join('|')) {
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

    try {
      final provider = PuppetAssetProvider(endpoint: widget.endpoint);
      final generated = await Future.wait(
        characters.map(
          (character) => provider.generate(
            character: [
              character.description,
              'Action: ${character.action}.',
              'Emotion: ${character.emotion}.',
              'Position: ${character.position}.',
            ].join(' '),
          ),
        ),
      );

      final decoded = <_PuppetSheet>[];
      for (final sheet in generated) {
        final bytes = base64Decode(sheet.base64);
        final image = await _decodeAndChromaKey(bytes);
        decoded.add(_PuppetSheet(image));
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
      if (mounted) setState(() => _loading = false);
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
      throw StateError('Unable to decode puppet sprite sheet.');
    }

    final pixels = Uint8List.fromList(raw.buffer.asUint8List());
    for (var i = 0; i + 3 < pixels.length; i += 4) {
      final r = pixels[i];
      final g = pixels[i + 1];
      final b = pixels[i + 2];
      if (b > 110 && b > r * 1.22 && b > g * 1.08) {
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
            painter: _LivingPuppetPainter(
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

class _PuppetSheet {
  const _PuppetSheet(this.image);

  final ui.Image image;
}

class _LivingPuppetPainter extends CustomPainter {
  _LivingPuppetPainter({
    required this.animation,
    required this.plan,
    required this.sheets,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final AiScenePlan plan;
  final List<_PuppetSheet> sheets;

  static const double _cell = 256;

  static const Map<String, int> _cells = {
    'head': 0,
    'torso': 1,
    'armR': 4,
    'forearmR': 5,
    'handR': 6,
    'footR': 7,
    'armL': 8,
    'forearmL': 9,
    'handL': 10,
    'footL': 11,
    'legR': 12,
    'shinR': 13,
    'legL': 14,
    'shinL': 15,
  };

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < sheets.length; i++) {
      _paintCharacter(
        canvas,
        size,
        sheets[i].image,
        plan.characters[i],
        i,
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
    final phase = animation.value * math.pi * 2;
    final action = _actionFor(characterIndex);
    final anchorX = _anchorX(character.position, characterIndex, characterCount);
    final anchor = Offset(
      size.width * anchorX,
      size.height * 0.70,
    );

    final characterScale = math.min(size.width, size.height) / 1050;
    final walk = action.contains('walk') ||
        action.contains('enter') ||
        action.contains('move') ||
        action.contains('travers');
    final travel = walk
        ? math.sin(animation.value * math.pi * 2) * size.width * 0.16
        : 0.0;
    final breath = math.sin(phase * 1.7 + characterIndex) * 0.012;
    final sway = math.sin(phase * 1.15 + characterIndex) * 0.025;
    final talking = action.contains('talk') || action.contains('speak');
    final listening = action.contains('listen') || action.contains('react');
    final gesture = action.contains('gesture') ||
        action.contains('point') ||
        action.contains('reach');
    final eating = action.contains('eat');
    final handWave = math.sin(phase * 1.8) * 0.08;

    final center = anchor.translate(travel, breath * 40 * characterScale);

    final transforms = <ui.RSTransform>[];
    final rects = <Rect>[];

    void addPart(
      String name,
      Offset pivot,
      double rotation, {
      double scale = 1,
      double anchorX = _cell / 2,
      double anchorY = _cell / 2,
    }) {
      final cellIndex = _cells[name];
      if (cellIndex == null) return;
      final row = cellIndex ~/ 4;
      final col = cellIndex % 4;
      rects.add(
        Rect.fromLTWH(
          col * _cell,
          row * _cell,
          _cell,
          _cell,
        ),
      );
      transforms.add(
        ui.RSTransform.fromComponents(
          rotation: rotation,
          scale: characterScale * scale,
          anchorX: anchorX,
          anchorY: anchorY,
          translateX: center.dx + pivot.dx * characterScale,
          translateY: center.dy + pivot.dy * characterScale,
        ),
      );
    }

    final walkPhase = math.sin(phase * 1.6 + characterIndex);
    final armTalk = talking ? math.sin(phase * 2.1) * 0.12 : 0.0;
    final armGesture = gesture
        ? -0.35 - math.sin(phase * 1.35).abs() * 0.28
        : 0.0;
    final armEat = eating ? -0.72 + math.sin(phase * 1.2) * 0.18 : 0.0;

    addPart('legL', const Offset(-72, 245), walk ? -walkPhase * 0.12 : 0);
    addPart('shinL', const Offset(-72, 480), walk ? walkPhase * 0.10 : 0);
    addPart('legR', const Offset(72, 245), walk ? walkPhase * 0.12 : 0);
    addPart('shinR', const Offset(72, 480), walk ? -walkPhase * 0.10 : 0);
    addPart('footL', const Offset(-72, 620), walk ? -walkPhase * 0.06 : 0);
    addPart('footR', const Offset(72, 620), walk ? walkPhase * 0.06 : 0);

    addPart('torso', const Offset(0, 60), sway);
    addPart('armL', const Offset(-150, -40), -sway * 0.7);
    addPart(
      'armR',
      const Offset(150, -40),
      talking ? armTalk : (gesture || eating ? armGesture + armEat : sway * 0.5),
      anchorY: 18,
    );
    addPart(
      'forearmL',
      const Offset(-150, 150),
      -sway * 0.4,
      anchorY: 18,
    );
    addPart(
      'forearmR',
      const Offset(150, 150),
      eating ? -0.55 + math.sin(phase * 1.2) * 0.18 : armTalk * 0.6,
      anchorY: 18,
    );

    addPart(
      'head',
      const Offset(0, -220),
      listening
          ? -0.055 + math.sin(phase * .8) * .025
          : math.sin(phase * .65) * .035,
      anchorY: 238,
    );
    addPart(
      'handL',
      const Offset(-165, 300),
      handWave * .4,
    );
    addPart(
      'handR',
      const Offset(165, 300),
      eating
          ? -0.38 + math.sin(phase * 1.2) * .12
          : (gesture ? -0.22 + handWave : armTalk),
    );

    canvas.drawAtlas(
      sheet,
      transforms,
      rects,
      null,
      null,
      null,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  String _actionFor(int index) {
    final actions = plan.actions.isNotEmpty
        ? plan.actions
        : plan.characters.map((character) => character.action).toList();
    if (actions.isEmpty) return 'idle';

    final slot = (animation.value * actions.length).floor() % actions.length;
    final action = actions[(slot + index) % actions.length].toLowerCase();
    final characterAction = plan.characters[index].action.toLowerCase();
    return '$action $characterAction';
  }

  double _anchorX(String position, int index, int count) {
    final text = position.toLowerCase();
    if (text.contains('left')) return .30;
    if (text.contains('right')) return .70;
    if (count == 2) return index == 0 ? .34 : .66;
    return .50;
  }

  @override
  bool shouldRepaint(covariant _LivingPuppetPainter oldDelegate) =>
      oldDelegate.plan != plan || oldDelegate.sheets != sheets;
}
