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
  String? _assetError;

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
            '${character.id}|${character.description}|${character.action}|${character.emotion}')
        .join('||');
    final newCharacters = widget.plan.characters
        .map((character) =>
            '${character.id}|${character.description}|${character.action}|${character.emotion}')
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
              'Primary action: ${character.action}.',
              'Emotion: ${character.emotion}.',
              'Stage position: ${character.position}.',
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
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _assetError = error.toString().replaceFirst('Bad state: ', '');
        });
      }
    }
  }

  Future<ui.Image> _decodeAndChromaKey(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final width = image.width;
    final height = image.height;
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

      // FLUX/JPEG can turn the requested #0066FF key into pale cyan.
      // Remove the keyed background completely so it can never render as a
      // translucent rectangle over the generated scene.
      final blueDominance = b - ((r + g) ~/ 2);
      if (b > 145 && blueDominance > 22 && b > r + 18 && b > g - 2) {
        pixels[i + 3] = 0;
      }
    }

    return _decodePixels(pixels, width, height);
  }

  Future<ui.Image> _decodePixels(
    Uint8List pixels,
    int width,
    int height,
  ) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
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
        if (!_loading && _sheets.isEmpty && _assetError != null)
          const Positioned(
            left: 16,
            top: 16,
            child: SafeArea(
              bottom: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xCC6B1D1D),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Text(
                    'Animation asset unavailable',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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

  // AI prepares one semantic-part sheet. Flutter is the actor: joints,
  // timing, walk cycles, gestures, head movement and breathing all run locally.
  static const int _columns = 4;
  static const int _rows = 3;
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
    final action = '${actions[beatIndex]} ${character.action}';
    final lowerAction = action.toLowerCase();

    final isWalk = _containsAny(lowerAction, const [
      'walk', 'enter', 'move', 'approach', 'cross', 'traverse'
    ]);
    final isTalk = _containsAny(lowerAction, const [
      'talk', 'speak', 'say', 'conversation', 'discuss'
    ]);
    final isGesture = _containsAny(lowerAction, const [
      'gesture', 'point', 'reach', 'raise', 'pick', 'take', 'wave'
    ]);
    final isReact = _containsAny(lowerAction, const [
      'react', 'listen', 'notice', 'surprise', 'look', 'turn'
    ]);
    final isEat = _containsAny(lowerAction, const ['eat', 'drink']);

    final position = _positionAnchor(
      character.position,
      characterIndex,
      characterCount,
    );

    final cycle = elapsed * math.pi * 2.0;
    final walkCycle = math.sin(cycle * 1.25);
    final talkCycle = math.sin(cycle * 2.0);
    final breathe = math.sin(cycle * 0.7 + characterIndex * 0.7);
    final gestureCycle = math.sin(cycle * 0.9 + characterIndex);

    final walkOffset = isWalk
        ? ui.lerpDouble(
            -size.width * 0.12,
            size.width * 0.12,
            Curves.easeInOut.transform(beatProgress),
          )!
        : 0.0;

    final bodyHeight = size.height * 0.46;
    final top = size.height * 0.43;
    final anchor = Offset(
      size.width * position + walkOffset,
      top + bodyHeight * 0.52 -
          (isWalk ? walkCycle.abs() * size.height * 0.008 : 0),
    );

    final torsoScale = 1.0 + breathe * 0.012;
    final headTilt = isReact ? gestureCycle * 0.06 : breathe * 0.018;
    final torsoTilt = isWalk ? walkCycle * 0.035 : breathe * 0.008;

    final armSwing = isWalk ? walkCycle * 0.42 : 0.0;
    final forearmSwing = isWalk ? -walkCycle * 0.24 : 0.0;
    final talkArm = isTalk ? talkCycle * 0.24 : 0.0;
    final gestureArm = isGesture ? (0.35 + gestureCycle * 0.18) : 0.0;
    final reactArm = isReact ? (-0.18 + gestureCycle * 0.12) : 0.0;

    final leftArmAngle = -armSwing - talkArm - gestureArm - reactArm;
    final rightArmAngle = armSwing + talkArm + gestureArm + reactArm;
    final leftForearmAngle = forearmSwing + talkArm * 0.7;
    final rightForearmAngle = -forearmSwing - talkArm * 0.7;

    final leftLegAngle = isWalk ? walkCycle * 0.18 : breathe * 0.008;
    final rightLegAngle = -leftLegAngle;

    // Shared normalized skeleton. Each anatomical texture is transformed
    // independently, so the runtime produces continuous acting rather than
    // switching between whole-character images.
    final head = anchor.translate(0, -bodyHeight * 0.40);
    final torso = anchor.translate(0, -bodyHeight * 0.08);
    final leftShoulder =
        anchor.translate(-bodyHeight * 0.145, -bodyHeight * 0.24);
    final rightShoulder =
        anchor.translate(bodyHeight * 0.145, -bodyHeight * 0.24);
    final leftElbow =
        anchor.translate(-bodyHeight * 0.19, bodyHeight * 0.01);
    final rightElbow =
        anchor.translate(bodyHeight * 0.19, bodyHeight * 0.01);
    final leftHand =
        anchor.translate(-bodyHeight * 0.19, bodyHeight * 0.15);
    final rightHand =
        anchor.translate(bodyHeight * 0.19, bodyHeight * 0.15);
    final leftHip =
        anchor.translate(-bodyHeight * 0.075, bodyHeight * 0.25);
    final rightHip =
        anchor.translate(bodyHeight * 0.075, bodyHeight * 0.25);
    final leftKnee =
        anchor.translate(-bodyHeight * 0.08, bodyHeight * 0.50);
    final rightKnee =
        anchor.translate(bodyHeight * 0.08, bodyHeight * 0.50);
    final leftFoot =
        anchor.translate(-bodyHeight * 0.09, bodyHeight * 0.76);
    final rightFoot =
        anchor.translate(bodyHeight * 0.09, bodyHeight * 0.76);

    _drawPart(canvas, sheet, 8, leftKnee, bodyHeight * 0.13,
        bodyHeight * 0.30, leftLegAngle);
    _drawPart(canvas, sheet, 9, rightKnee, bodyHeight * 0.13,
        bodyHeight * 0.30, rightLegAngle);
    _drawPart(canvas, sheet, 6, leftHip, bodyHeight * 0.16,
        bodyHeight * 0.30, leftLegAngle * 0.65);
    _drawPart(canvas, sheet, 7, rightHip, bodyHeight * 0.16,
        bodyHeight * 0.30, rightLegAngle * 0.65);

    _drawPart(canvas, sheet, 1, torso, bodyHeight * 0.36 * torsoScale,
        bodyHeight * 0.38 * torsoScale, torsoTilt);

    _drawPart(canvas, sheet, 2, leftShoulder, bodyHeight * 0.14,
        bodyHeight * 0.27, leftArmAngle);
    _drawPart(canvas, sheet, 3, rightShoulder, bodyHeight * 0.14,
        bodyHeight * 0.27, rightArmAngle);
    _drawPart(canvas, sheet, 4, leftElbow, bodyHeight * 0.12,
        bodyHeight * 0.25, leftForearmAngle);
    _drawPart(canvas, sheet, 5, rightElbow, bodyHeight * 0.12,
        bodyHeight * 0.25, rightForearmAngle);
    _drawPart(canvas, sheet, 10, leftHand, bodyHeight * 0.11,
        bodyHeight * 0.12, leftForearmAngle);
    _drawPart(canvas, sheet, 11, rightHand, bodyHeight * 0.11,
        bodyHeight * 0.12, rightForearmAngle);

    _drawPart(
      canvas,
      sheet,
      0,
      head.translate(
        isReact ? gestureCycle * bodyHeight * 0.012 : 0,
        breathe * bodyHeight * 0.006,
      ),
      bodyHeight * 0.23,
      bodyHeight * 0.25,
      headTilt,
    );

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(anchor.dx, math.max(leftFoot.dy, rightFoot.dy) + 3),
        width: bodyHeight * 0.34,
        height: bodyHeight * 0.035,
      ),
      shadow,
    );

    if (isEat) {
      final handBob = math.sin(cycle * 1.5) * bodyHeight * 0.035;
      _drawPart(
        canvas,
        sheet,
        10,
        head.translate(-bodyHeight * 0.08, bodyHeight * 0.08 + handBob),
        bodyHeight * 0.11,
        bodyHeight * 0.12,
        -0.35,
      );
      _drawPart(
        canvas,
        sheet,
        11,
        head.translate(bodyHeight * 0.08, bodyHeight * 0.08 - handBob),
        bodyHeight * 0.11,
        bodyHeight * 0.12,
        0.35,
      );
    }
  }

  void _drawPart(
    Canvas canvas,
    ui.Image sheet,
    int cell,
    Offset center,
    double width,
    double height,
    double rotation,
  ) {
    final cellWidth = sheet.width / _columns;
    final cellHeight = sheet.height / _rows;
    final source = Rect.fromLTWH(
      (cell % _columns) * cellWidth,
      (cell ~/ _columns) * cellHeight,
      cellWidth,
      cellHeight,
    );
    final destination = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

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

  bool _containsAny(String value, List<String> terms) =>
      terms.any(value.contains);

  double _positionAnchor(String position, int index, int count) {
    final value = position.toLowerCase();
    if (value.contains('far left') || value.contains('left')) return 0.29;
    if (value.contains('far right') || value.contains('right')) return 0.71;
    if (value.contains('center') || value.contains('middle')) return 0.50;
    if (count == 2) return index == 0 ? 0.36 : 0.64;
    return 0.50;
  }

  @override
  bool shouldRepaint(covariant _LivingCharacterPainter oldDelegate) => true;
}

