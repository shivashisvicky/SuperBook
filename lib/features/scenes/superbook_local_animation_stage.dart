import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/book.dart';
import '../../domain/experience/ai_scene_plan.dart';
import '../../domain/experience/superbook_scene_graph.dart';

/// Network-free animated storybook experience. AI scene imagery may inform the
/// scene plan, but it is never composited underneath the live animation.
class SuperBookLocalAnimationStage extends StatefulWidget {
  const SuperBookLocalAnimationStage({
    super.key,
    required this.scene,
    required this.passage,
    required this.characters,
    this.actionHint = '',
    this.backgroundImageBase64,
    this.scenePlan,
    this.narrativeFocus = '',
  });

  final Scene scene;
  final List<String> passage;
  final List<BookCharacter> characters;
  final String actionHint;
  final String? backgroundImageBase64;
  final AiScenePlan? scenePlan;
  final String narrativeFocus;

  @override
  State<SuperBookLocalAnimationStage> createState() =>
      _SuperBookLocalAnimationStageState();
}

class _SuperBookLocalAnimationStageState
    extends State<SuperBookLocalAnimationStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _cycleSeconds()),
    )..forward();
  }

  SuperBookSceneGraph? get _sceneGraph => widget.scenePlan == null
      ? null
      : SuperBookSceneGraph.from(
          plan: widget.scenePlan!,
          scene: widget.scene,
          bookCharacters: widget.characters,
          passage: widget.passage,
          narrativeFocus: widget.narrativeFocus,
        );

  int _cycleSeconds() {
    final graph = _sceneGraph;
    if (graph != null && graph.timeline.isNotEmpty) {
      final totalMs = graph.timeline.fold<int>(0, (sum, beat) => sum + beat.duration.inMilliseconds);
      return (totalMs / 1000).ceil().clamp(8, 300);
    }
    final raw = widget.passage
        .join(' ')
        .replaceFirst(RegExp(r'^\s*\[Illustration\]\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final words = raw.isEmpty ? 0 : raw.split(' ').length;
    final beats = math.max(1, (words / 22).ceil());
    return (beats * 18).clamp(12, 120);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final graph = _sceneGraph;
    final hasImage = widget.backgroundImageBase64 != null &&
        widget.backgroundImageBase64!.isNotEmpty;
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.memory(
              base64Decode(widget.backgroundImageBase64!),
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _LocalStoryPainter(
                progress: _controller.value,
                scene: widget.scene,
                passage: widget.passage,
                characters: widget.characters,
                actionHint: widget.actionHint,
                sceneGraph: graph,
                avatarSeed: '${widget.scene.title}|${widget.scene.moment}|${widget.narrativeFocus}',
                narrativeFocus: widget.narrativeFocus,
                drawBackground: !hasImage,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalStoryPainter extends CustomPainter {
  _LocalStoryPainter({
    required this.progress,
    required this.scene,
    required this.passage,
    required this.characters,
    required this.actionHint,
    required this.sceneGraph,
    required this.avatarSeed,
    required this.narrativeFocus,
    required this.drawBackground,
  });

  final double progress;
  final Scene scene;
  final List<String> passage;
  final List<BookCharacter> characters;
  final String actionHint;
  final SuperBookSceneGraph? sceneGraph;
  final String avatarSeed;
  final String narrativeFocus;
  final bool drawBackground;

  bool get widgetHasImage => !drawBackground;

  int get _avatarVariant {
    var h = 0;
    for (final code in avatarSeed.codeUnits) {
      h = (h * 31 + code) & 0x7fffffff;
    }
    return h % 8;
  }

  String get _text {
    if (sceneGraph != null) {
      return [
        scene.title,
        scene.moment,
        narrativeFocus,
        ...passage.take(2),
        sceneGraph!.environment,
        ...sceneGraph!.props,
      ].join(' ').toLowerCase();
    }
    return [scene.title, scene.moment, passage.join(' ')]
        .join(' ')
        .toLowerCase();
  }

  bool get _rain =>
      _text.contains('rain') || _text.contains('storm') || _text.contains('wet');

  bool get _night =>
      _text.contains('night') || _text.contains('dark') || _text.contains('moon');

  bool get _indoors {
    final t = _text;
    return t.contains('room') ||
        t.contains('hall') ||
        t.contains('inside') ||
        t.contains('house') ||
        t.contains('door') ||
        t.contains('library') ||
        t.contains('parlor');
  }

  bool get _warmLight =>
      _text.contains('lamp') || _text.contains('candle') || _text.contains('fire');

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * math.pi * 2;
    if (drawBackground) _paintBackground(canvas, size, t);

    final beat = _currentBeat;
    final narrativePhase = _isNarrativePhase;
    final phaseProgress = _phaseProgress;
    final currentAction = _action(beat);
    final activeBeat = sceneGraph != null && sceneGraph!.timeline.isNotEmpty
        ? sceneGraph!.timeline[_beatIndex.clamp(0, sceneGraph!.timeline.length - 1)]
        : null;
    final groupScene = _text.contains(' they ') || _text.contains('gentlemen') || _text.contains('family') || _text.contains('women') || _text.contains('girls') || _text.contains('people');
    final count = sceneGraph != null
        ? math.min(2, sceneGraph!.actors.length)
        : (groupScene ? 2 : math.min(2, math.max(1, characters.length)));
    for (var i = 0; i < count; i++) {
      final actor = sceneGraph != null ? sceneGraph!.actors[i] : null;
      final startAnchor = actor == null ? null : sceneGraph!.anchors[actor.startAnchor];
      final targetAnchor = activeBeat?.targetAnchor == null ? null : sceneGraph?.anchors[activeBeat!.targetAnchor!];
      final baseX = startAnchor == null ? size.width * (i == 0 ? .30 : .70) : size.width * startAnchor.x;
      final targetX = targetAnchor == null ? baseX : size.width * targetAnchor.x;
      final travel = narrativePhase ? 0.0 : Curves.easeInOut.transform(phaseProgress);
      final x = currentAction == 'walk' ? baseX + (targetX - baseX) * travel : baseX;
      final baseY = startAnchor?.y ?? .69;
      final scale = math.min(size.width, size.height) / 430 *
          (widgetHasImage ? .78 : 1.0);
      final action = i == 0 ? currentAction : _secondaryAction(beat);
      _paintCharacter(
        canvas,
        Offset(x, size.height * (widgetHasImage ? .665 : baseY)),
        scale,
        phaseProgress,
        i,
        action,
        characterSeed: actor == null ? '$i' : '${actor.id}|${actor.description}',
        actionProgress: phaseProgress,
        integrated: widgetHasImage,
      );
    }

    if (currentAction == 'carriage' && !narrativePhase) {
      _paintCarriage(canvas, size, phaseProgress, sceneGraph);
    }

    if (_rain) _paintRain(canvas, size);
    if (_warmLight) _paintWarmLight(canvas, size, t);
    if (narrativePhase) {
      _paintNarrativeCloud(canvas, size, beat);
    }
  }

  List<String> get _beats {
    if (sceneGraph != null && sceneGraph!.timeline.isNotEmpty) {
      return sceneGraph!.timeline.map((beat) => beat.text).toList();
    }
    final raw = passage
        .join(' ')
        .replaceFirst(RegExp(r'^\s*\[Illustration\]\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (raw.isEmpty) return const [];

    final clauses = raw
        .split(RegExp(r'(?<=[.!?;])\s+|(?<=,)\s+(?=[A-Z])'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final beats = <String>[];
    for (final clause in clauses) {
      final words = clause.split(RegExp(r'\s+'));
      for (var i = 0; i < words.length; i += 22) {
        beats.add(words.sublist(i, math.min(i + 22, words.length)).join(' '));
      }
    }
    return beats.isEmpty ? [raw] : beats;
  }

  int get _timelineTotalMs {
    if (sceneGraph == null || sceneGraph!.timeline.isEmpty) return _beats.length * 1800;
    return sceneGraph!.timeline.fold<int>(0, (sum, beat) => sum + beat.duration.inMilliseconds);
  }

  int get _beatIndex {
    final count = _beats.length;
    if (count == 0) return 0;
    final target = (progress * _timelineTotalMs).floor();
    var elapsed = 0;
    for (var i = 0; i < count; i++) {
      final duration = sceneGraph == null ? 1800 : sceneGraph!.timeline[i].duration.inMilliseconds;
      if (target < elapsed + duration) return i;
      elapsed += duration;
    }
    return count - 1;
  }

  bool get _isNarrativePhase => false;

  double get _phaseProgress {
    final count = _beats.length;
    if (count == 0) return 0;
    final target = (progress * _timelineTotalMs).floor();
    var elapsed = 0;
    for (var i = 0; i < count; i++) {
      final duration = sceneGraph == null ? 1800 : sceneGraph!.timeline[i].duration.inMilliseconds;
      if (target < elapsed + duration) return ((target - elapsed) / duration).clamp(0.0, 1.0);
      elapsed += duration;
    }
    return 1.0;
  }

  String get _currentBeat {
    final beats = _beats;
    if (beats.isEmpty) return scene.moment;
    return beats[_beatIndex];
  }

  String _action(String beat) {
    if (sceneGraph != null && sceneGraph!.timeline.isNotEmpty) {
      return sceneGraph!.timeline[_beatIndex.clamp(0, sceneGraph!.timeline.length - 1)].action;
    }
    final t = beat.toLowerCase();
    if (t.contains('say') || t.contains('said') || t.contains('says') || t.contains('spoke') ||
        t.contains('speak') || t.contains('tell') || t.contains('asked') ||
        t.contains('replied') || t.contains('answer') || t.contains('conversation') ||
        t.contains('love') || t.contains('danger') || t.contains('objection')) { return 'talk'; }
    if (t.contains('carriage') || t.contains('horse') || t.contains('coach')) { return 'carriage'; }
    if (t.contains('left') || t.contains('leave') || t.contains('leaving') ||
        t.contains('depart') || t.contains('departed') || t.contains('went') ||
        t.contains('walk') || t.contains('approach') || t.contains('cross') ||
        t.contains('enter') || t.contains('step') || t.contains('move') ||
        t.contains('arrive') || t.contains('go ') || t.contains('did not see')) { return 'walk'; }
    if (t.contains('attention') || t.contains('drawn to') || t.contains('look') ||
        t.contains('notice') || t.contains('see') || t.contains('watch') ||
        t.contains('window') || t.contains('sound') || t.contains('hear') ||
        t.contains('listen') || t.contains('turn')) { return 'look'; }
    if (t.contains('walk') || t.contains('approach') || t.contains('cross') ||
        t.contains('enter') || t.contains('step') || t.contains('move') ||
        t.contains('leave') || t.contains('arrive') || t.contains('go ')) { return 'walk'; }
    if (t.contains('door') || t.contains('window')) { return 'look'; }
    if (t.contains('reach') || t.contains('open') || t.contains('lift') ||
        t.contains('take') || t.contains('pick') || t.contains('hold') ||
        t.contains('door')) { return 'reach'; }
    if (t.contains('sit') || t.contains('sitting')) { return 'sit'; }
    if (t.contains('stand') || t.contains('rise')) { return 'stand'; }
    if (t.contains('said') || t.contains('says') || t.contains('speak') || t.contains('tell') ||
        t.contains('ask') || t.contains('reply') || t.contains('answer') ||
        t.contains('conversation')) { return 'talk'; }
    return 'look';
  }

  String _secondaryAction(String beat) {
    final t = beat.toLowerCase();
    if (t.contains('attention') || t.contains('drawn to') || t.contains('look') ||
        t.contains('notice') || t.contains('window') || t.contains('sound') ||
        t.contains('hear') || t.contains('listen')) { return 'look'; }
    if (t.contains('say') || t.contains('speak') || t.contains('tell') ||
        t.contains('ask') || t.contains('reply')) { return 'talk'; }
    return 'listen';
  }


  void _paintCarriage(Canvas canvas, Size size, double progress, SuperBookSceneGraph? graph) {
    final e = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));
    final anchor = graph?.anchors['outside_window'] ?? graph?.anchors['outside'];
    final targetX = anchor == null ? size.width * .72 : size.width * anchor.x;
    final targetY = anchor == null ? size.height * .49 : size.height * anchor.y;
    final x = (size.width * 1.08) + (targetX - (size.width * 1.08)) * e;
    final y = targetY;
    final body = Paint()..color = const Color(0xFF5B3425);
    final trim = Paint()..color = const Color(0xFFD1A45B)..style = PaintingStyle.stroke..strokeWidth = 4;
    final wheel = Paint()..color = const Color(0xFF242124);
    canvas.save();
    canvas.translate(x, y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-72, -30, 118, 52),
        const Radius.circular(10),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-63, -22, 100, 31),
        const Radius.circular(6),
      ),
      trim,
    );
    canvas.drawRect(
      Rect.fromLTWH(-54, -14, 20, 18),
      Paint()..color = const Color(0xFF9AB0B8),
    );
    canvas.drawRect(
      Rect.fromLTWH(-5, -14, 20, 18),
      Paint()..color = const Color(0xFF9AB0B8),
    );
    canvas.drawCircle(const Offset(-45, 25), 14, wheel);
    canvas.drawCircle(const Offset(23, 25), 14, wheel);
    canvas.drawLine(const Offset(-86, -2), const Offset(-72, -2), trim);
    canvas.drawLine(const Offset(46, -2), const Offset(60, -2), trim);
    canvas.restore();
  }

  void _paintNarrativeCloud(Canvas canvas, Size size, String narrative) {
    final text = TextPainter(
      text: TextSpan(
        text: narrative,
        style: const TextStyle(
          color: Color(0xFF24201C),
          fontSize: 16,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 7,
      ellipsis: '…',
    )..layout(maxWidth: size.width * .78);

    final center = Offset(size.width * .50, size.height * .19);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width * .86,
      height: math.max(88, text.height + 38),
    );
    final paint = Paint()..color = Colors.white.withValues(alpha: .94);
    canvas.drawOval(rect, paint);
    canvas.drawCircle(center + Offset(-rect.width * .28, rect.height * .43), 13, paint);
    canvas.drawCircle(center + Offset(-rect.width * .19, rect.height * .53), 7, paint);
    text.paint(
      canvas,
      Offset(
        rect.center.dx - text.width / 2,
        rect.center.dy - text.height / 2,
      ),
    );
  }

  void _paintBackground(Canvas canvas, Size size, double t) {
    final top = _night ? const Color(0xFF101827) : const Color(0xFF687A91);
    final bottom = _night ? const Color(0xFF252B39) : const Color(0xFFD9C7AA);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(Offset.zero & size),
    );
    if (_indoors) {
      _paintRoom(canvas, size, t);
    } else {
      _paintOutdoors(canvas, size, t);
    }
  }

  void _paintRoom(Canvas canvas, Size size, double t) {
    final text = _text;
    final drawingRoom = text.contains('drawing room') || text.contains('drawing-room') || text.contains('parlor');
    final diningRoom = text.contains('dining room') || text.contains('dining-room') || text.contains('dinner');
    final windowScene = text.contains('window');
    final hallScene = text.contains('hall') || text.contains('corridor') || text.contains('stairs');

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * .68),
      Paint()..color = const Color(0xFFE6DDCC),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .68, size.width, size.height * .32),
      Paint()..color = const Color(0xFF5A4C43),
    );

    final doorScene = hallScene || text.contains('door') || text.contains('entrance');
    if (doorScene) {
      final door = Rect.fromCenter(
        center: Offset(size.width * (hallScene ? .52 : .5), size.height * .43),
        width: size.width * .34,
        height: size.height * .55,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(door, const Radius.circular(6)),
        Paint()..color = const Color(0xFF694C39),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(door.deflate(size.width * .018), const Radius.circular(4)),
        Paint()..color = const Color(0xFFD8B982),
      );
    }

    final tableScene = text.contains('table') || text.contains('desk');
    final table = Rect.fromLTWH(
      size.width * .10,
      size.height * .56,
      size.width * .80,
      size.height * .06,
    );
    if (tableScene) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(table, const Radius.circular(5)),
        Paint()..color = const Color(0xFF6D4D39),
      );
    }

    if (drawingRoom || diningRoom || tableScene) {
      final chairPaint = Paint()..color = const Color(0xFF7B5A43);
      for (final x in [size.width * .18, size.width * .82]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, size.height * .61), width: size.width * .14, height: size.height * .13),
            const Radius.circular(6),
          ),
          chairPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(x - size.width * .05, size.height * .65, size.width * .025, size.height * .12),
          chairPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(x + size.width * .025, size.height * .65, size.width * .025, size.height * .12),
          chairPaint,
        );
      }
    }

    if (windowScene) {
      final window = Rect.fromCenter(
        center: Offset(size.width * .76, size.height * .31),
        width: size.width * .22,
        height: size.height * .23,
      );
      canvas.drawRect(window, Paint()..color = const Color(0xFF6E7E72));
      canvas.drawRect(window.deflate(size.width * .012), Paint()..color = const Color(0xFFD7C39A));
      canvas.drawLine(window.centerLeft, window.centerRight, Paint()..color = const Color(0xFF76563E)..strokeWidth = 4);
      canvas.drawLine(window.topCenter, window.bottomCenter, Paint()..color = const Color(0xFF76563E)..strokeWidth = 4);
    }

    if (_warmLight) {
      final pulse = .5 + .5 * math.sin(t * 2);
      canvas.drawCircle(
        Offset(size.width * .5, size.height * .40),
        size.width * .48,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.amber.withValues(alpha: .10 + .05 * pulse),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .5, size.height * .40),
              radius: size.width * .48,
            ),
          ),
      );
    }
  }

  void _paintOutdoors(Canvas canvas, Size size, double t) {
    canvas.drawOval(
      Rect.fromLTWH(-size.width * .2, size.height * .57, size.width * 1.4, size.height * .7),
      Paint()..color = const Color(0xFF435A45),
    );

    if (_night) {
      canvas.drawCircle(
        Offset(size.width * .78, size.height * .18),
        size.width * .075,
        Paint()..color = const Color(0xFFF2E9C9),
      );
      final stars = Paint()..color = Colors.white.withValues(alpha: .72);
      for (var i = 0; i < 18; i++) {
        final x = (i * 83.0) % size.width;
        final y = 25.0 + ((i * 47.0) % (size.height * .25));
        canvas.drawCircle(
          Offset(x, y),
          1.0 + .7 * ((math.sin(t + i) + 1) / 2),
          stars,
        );
      }
    }

    final house = Path()
      ..moveTo(size.width * .16, size.height * .58)
      ..lineTo(size.width * .16, size.height * .30)
      ..lineTo(size.width * .50, size.height * .17)
      ..lineTo(size.width * .84, size.height * .30)
      ..lineTo(size.width * .84, size.height * .58)
      ..close();
    canvas.drawPath(house, Paint()..color = const Color(0xFF8D765F));

    final roof = Path()
      ..moveTo(size.width * .10, size.height * .32)
      ..lineTo(size.width * .50, size.height * .10)
      ..lineTo(size.width * .90, size.height * .32)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF403B39));

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * .50, size.height * .36),
        width: size.width * .11,
        height: size.height * .14,
      ),
      Paint()..color = const Color(0xFFFFD98A),
    );

    for (var i = 0; i < 7; i++) {
      _paintTree(
        canvas,
        Offset(size.width * (.08 + i * .14), size.height * (.28 + (i % 3) * .055)),
        size.width * .10,
      );
    }
  }

  void _paintTree(Canvas canvas, Offset center, double radius) {
    canvas.drawRect(
      Rect.fromCenter(
        center: center + Offset(0, radius * .9),
        width: radius * .18,
        height: radius * 1.2,
      ),
      Paint()..color = const Color(0xFF4D3B30),
    );
    final leaves = Paint()..color = const Color(0xFF304735);
    canvas.drawCircle(center, radius, leaves);
    canvas.drawCircle(center + Offset(-radius * .45, radius * .22), radius * .7, leaves);
    canvas.drawCircle(center + Offset(radius * .45, radius * .20), radius * .7, leaves);
  }

  void _paintCharacter(
    Canvas canvas, Offset feet, double s, double phase, int index, String action, {
    double actionProgress = 0,
    bool integrated = false,
    String characterSeed = '',
  }) {
    final swing = math.sin(phase * math.pi * 2);
    final act = Curves.easeInOut.transform(actionProgress.clamp(0.0, 1.0));
    final walk = action == 'walk';
    final stand = action == 'stand';
    final reach = action == 'reach';
    final listen = action == 'listen' || action == 'look';
    final talk = action == 'talk';
    final seatedTalk = talk && _indoors;
    final bob = walk ? math.sin(phase * math.pi * 2) * 3.0 * s : talk ? math.sin(phase * math.pi * 2) * 1.2 * s : 0.0;
    final lean = stand ? -10 * (1 - act) : walk ? 2 : 0;
    const skins = [Color(0xFFF1D9B7),Color(0xFFD7A77D),Color(0xFFC78C69),Color(0xFF9B654B),Color(0xFFE5C09A),Color(0xFFB97858),Color(0xFFF0CBA8),Color(0xFF8D5A43)];
    const coats = [Color(0xFF6F4050),Color(0xFF3E5870),Color(0xFF7A5A3A),Color(0xFF3F6B5B),Color(0xFF7B4E3D),Color(0xFF5C4A73),Color(0xFF596B46),Color(0xFF754B63)];
    const hairs = [Color(0xFF4A3027),Color(0xFF2F2927),Color(0xFF6A422D),Color(0xFF211D1B),Color(0xFF8A5A35),Color(0xFF3A2420),Color(0xFF5A3A28),Color(0xFF2B2423)];
    var characterHash = 0;
    for (final code in characterSeed.codeUnits) {
      characterHash = (characterHash * 31 + code) & 0x7fffffff;
    }
    final variant = (characterHash + _avatarVariant + index * 3) % 8;
    final skin = skins[variant], coat = coats[variant], hair = hairs[variant];
    final coatLight = Color.lerp(coat, Colors.white, .18)!;
    final coatDark = Color.lerp(coat, Colors.black, .18)!;
    final skinShadow = Color.lerp(skin, Colors.black, .12)!;
    final taller = variant == 1 || variant == 5;
    final bodyScale = taller ? 1.08 : (variant == 2 || variant == 7 ? .94 : 1.0);
    final standY = stand ? math.min(0.0, -28 * act) : 0.0;
    final hip = feet + Offset(lean * s, -78 * s * bodyScale + standY * s + bob);
    final shoulder = hip + Offset(lean * .55 * s, -70 * s * bodyScale);
    final head = shoulder + Offset(lean * .18 * s, -49 * s * bodyScale);
    final leg = Paint()..color = const Color(0xFF29282C)..strokeWidth = 11 * s..strokeCap = StrokeCap.round;
    final footPaint = Paint()..color = const Color(0xFF1E1D20)..strokeWidth = 7 * s..strokeCap = StrokeCap.round;
    final stride = walk ? swing * 12 * s : 0.0;
    final liftL = walk ? math.max(0, math.cos(phase * math.pi * 2)) * 6 * s : 0.0;
    final liftR = walk ? math.max(0, -math.cos(phase * math.pi * 2)) * 6 * s : 0.0;
    final leftHip = hip + Offset(-11 * s, 0), rightHip = hip + Offset(11 * s, 0);
    final leftKnee = leftHip + Offset(-3 * s + stride * .35, 34 * s - liftL);
    final rightKnee = rightHip + Offset(3 * s - stride * .35, 34 * s - liftR);
    final leftFoot = Offset(feet.dx - 13 * s + stride, feet.dy - liftL);
    final rightFoot = Offset(feet.dx + 13 * s - stride, feet.dy - liftR);
    if (action == 'sit' || seatedTalk || (stand && act < .55)) {
      final seatedY = feet.dy - 4 * s;
      canvas.drawLine(hip + Offset(-10 * s, 0), Offset(feet.dx - 31 * s, seatedY - 34 * s), leg);
      canvas.drawLine(Offset(feet.dx - 31 * s, seatedY - 34 * s), Offset(feet.dx - 31 * s, seatedY), leg);
      canvas.drawLine(hip + Offset(10 * s, 0), Offset(feet.dx + 31 * s, seatedY - 34 * s), leg);
      canvas.drawLine(Offset(feet.dx + 31 * s, seatedY - 34 * s), Offset(feet.dx + 31 * s, seatedY), leg);
    } else {
      canvas.drawLine(leftHip, leftKnee, leg); canvas.drawLine(leftKnee, leftFoot, leg);
      canvas.drawLine(rightHip, rightKnee, leg); canvas.drawLine(rightKnee, rightFoot, leg);
      canvas.drawLine(leftFoot, leftFoot + Offset(15 * s, 0), footPaint);
      canvas.drawLine(rightFoot, rightFoot + Offset(15 * s, 0), footPaint);
    }
    final contactShadow = Paint()
      ..color = Colors.black.withValues(alpha: integrated ? .30 : .22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawOval(
      Rect.fromCenter(
        center: feet + Offset(0, 3 * s),
        width: 64 * s,
        height: 11 * s,
      ),
      contactShadow,
    );
    final dress = Path()..moveTo(shoulder.dx - 20 * s, shoulder.dy + 4 * s)..quadraticBezierTo(hip.dx - 28 * s, hip.dy + 18 * s, feet.dx - 40 * s, feet.dy - 5 * s)..lineTo(feet.dx + 40 * s, feet.dy - 5 * s)..quadraticBezierTo(hip.dx + 28 * s, hip.dy + 18 * s, shoulder.dx + 20 * s, shoulder.dy + 4 * s)..close();
    canvas.drawPath(dress, Paint()..color = coat);
    canvas.drawPath(
      Path()
        ..moveTo(shoulder.dx, shoulder.dy + 8 * s)
        ..lineTo(hip.dx - 18 * s, hip.dy + 14 * s)
        ..lineTo(hip.dx - 10 * s, hip.dy + 18 * s)
        ..lineTo(shoulder.dx + 3 * s, shoulder.dy + 13 * s)
        ..close(),
      Paint()..color = coatLight.withValues(alpha: integrated ? .72 : .9),
    );
    canvas.drawPath(
      Path()
        ..moveTo(hip.dx + 10 * s, hip.dy + 12 * s)
        ..lineTo(feet.dx + 34 * s, feet.dy - 5 * s)
        ..lineTo(feet.dx + 20 * s, feet.dy - 5 * s)
        ..lineTo(hip.dx + 2 * s, hip.dy + 16 * s)
        ..close(),
      Paint()..color = coatDark.withValues(alpha: integrated ? .70 : .9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: shoulder + Offset(0, 23 * s),
          width: 38 * s,
          height: 56 * s,
        ),
        Radius.circular(11 * s),
      ),
      Paint()..color = coat,
    );
    canvas.drawCircle(head, (20 + (variant % 3) * 2) * s, Paint()..color = skin);
    canvas.drawArc(
      Rect.fromCircle(center: head, radius: (20 + (variant % 3) * 2) * s),
      .35,
      2.45,
      false,
      Paint()
        ..color = skinShadow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * s,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: head + Offset(0, -10 * s),
        width: (43 + variant * 1.3) * s,
        height: 27 * s,
      ),
      Paint()..color = hair,
    );
    canvas.drawCircle(
      head + Offset((listen ? 14 : 13) * s, 4 * s),
      1.7 * s,
      Paint()..color = skinShadow,
    );
    final eye = Paint()..color = const Color(0xFF211D1A);
    final eyeShift = listen ? 3 * s : 0.0;
    canvas.drawCircle(head + Offset(-7 * s + eyeShift, 1 * s), 1.5 * s, eye);
    canvas.drawCircle(head + Offset(7 * s + eyeShift, 1 * s), 1.5 * s, eye);
    if (talk) {
      final mouthOpen = .8 + .8 * ((math.sin(phase * math.pi * 6) + 1) / 2);
      canvas.drawOval(
        Rect.fromCenter(
          center: head + Offset(0, 9 * s),
          width: 7 * s,
          height: mouthOpen * 5 * s,
        ),
        Paint()..color = const Color(0xFF6B3E3B),
      );
    }
    final armPaint = Paint()
      ..color = skin
      ..strokeWidth = 9 * s
      ..strokeCap = StrokeCap.round;
    Offset leftHand, rightHand;
    if (reach) {
      leftHand = shoulder + Offset(28 * s + 38 * s * act, 56 * s - 16 * s * act);
      rightHand = shoulder + Offset(42 * s + 52 * s * act, 42 * s - 10 * s * act);
    } else if (stand) {
      leftHand = shoulder + Offset(-28 * s, 68 * s + 8 * s * (1 - act));
      rightHand = shoulder + Offset(28 * s, 68 * s + 8 * s * (1 - act));
    } else if (talk) {
      final gesture = math.sin(phase * math.pi * 2);
      leftHand = shoulder + Offset(-30 * s - gesture * 16 * s, 53 * s - math.max(0, gesture) * 20 * s);
      rightHand = shoulder + Offset(30 * s + gesture * 18 * s, 50 * s - math.max(0, -gesture) * 20 * s);
    } else if (listen) {
      leftHand = shoulder + Offset(-28 * s, 60 * s);
      rightHand = shoulder + Offset(28 * s, 55 * s - math.sin(phase * math.pi * 2) * 4 * s);
    } else {
      leftHand = shoulder + Offset(-30 * s - swing * 10 * s, 58 * s);
      rightHand = shoulder + Offset(30 * s + swing * 10 * s, 58 * s);
    }
    final leftShoulder = shoulder + Offset(-17 * s, 7 * s), rightShoulder = shoulder + Offset(17 * s, 7 * s);
    _drawLimb(canvas, leftShoulder, leftHand, armPaint, bend: -7 * s);
    _drawLimb(canvas, rightShoulder, rightHand, armPaint, bend: 7 * s);
    if (talk) {
      final gesture = .5 + .5 * math.sin(phase * math.pi * 2);
      final accent = Paint()
        ..color = Colors.white.withValues(alpha: integrated ? .16 : .10)
        ..strokeWidth = 2 * s
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        shoulder + Offset(-10 * s, 22 * s),
        shoulder + Offset((-5 + gesture * 8) * s, 34 * s),
        accent,
      );
      canvas.drawLine(
        shoulder + Offset(10 * s, 22 * s),
        shoulder + Offset((5 - gesture * 8) * s, 34 * s),
        accent,
      );
    }
  }

  void _drawLimb(Canvas canvas, Offset shoulder, Offset hand, Paint paint, {double bend = 0}) {
    final elbow = Offset((shoulder.dx + hand.dx) / 2 + bend, (shoulder.dy + hand.dy) / 2 + 7);
    canvas.drawLine(shoulder, elbow, paint);
    canvas.drawLine(elbow, hand, paint);
    canvas.drawCircle(hand, paint.strokeWidth * .46, paint);
  }


  void _paintRain(Canvas canvas, Size size) {
    final rain = Paint()
      ..color = Colors.white.withValues(alpha: .22)
      ..strokeWidth = math.max(1, size.width * .002)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 80; i++) {
      final x = (i * 53.0 + progress * size.width * .8) % size.width;
      final y = (i * 91.0 + progress * size.height * 1.4) % size.height;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - size.width * .012, y + size.height * .035),
        rain,
      );
    }
  }

  void _paintWarmLight(Canvas canvas, Size size, double t) {
    final pulse = .5 + .5 * math.sin(t * 2.0);
    final center = Offset(size.width * .5, size.height * .38);
    canvas.drawCircle(
      center,
      size.width * .55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.amber.withValues(alpha: .10 + .05 * pulse),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: size.width * .55)),
    );
  }


  @override
  bool shouldRepaint(covariant _LocalStoryPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
