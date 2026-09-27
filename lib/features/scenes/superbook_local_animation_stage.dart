import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/book.dart';

/// Network-free animated storybook fallback. No AI, sprites, tokens, or cloud
/// services are required once the reader has the book content.
class SuperBookLocalAnimationStage extends StatefulWidget {
  const SuperBookLocalAnimationStage({
    super.key,
    required this.scene,
    required this.passage,
    required this.characters,
    this.actionHint = '',
  });

  final Scene scene;
  final List<String> passage;
  final List<BookCharacter> characters;
  final String actionHint;

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
    )..repeat();
  }

  int _cycleSeconds() {
    final raw = widget.passage
        .join(' ')
        .replaceFirst(RegExp(r'^\s*\[Illustration\]\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final words = raw.isEmpty ? 0 : raw.split(' ').length;
    final beats = math.max(1, (words / 22).ceil());
    return (beats * 15).clamp(30, 300);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _LocalStoryPainter(
              progress: _controller.value,
              scene: widget.scene,
              passage: widget.passage,
              characters: widget.characters,
              actionHint: widget.actionHint,
              avatarSeed: '${widget.scene.title}|${widget.scene.moment}|${widget.passage.join(' ')}',
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
}

class _LocalStoryPainter extends CustomPainter {
  _LocalStoryPainter({
    required this.progress,
    required this.scene,
    required this.passage,
    required this.characters,
    required this.actionHint,
    required this.avatarSeed,
  });

  final double progress;
  final Scene scene;
  final List<String> passage;
  final List<BookCharacter> characters;
  final String actionHint;
  final String avatarSeed;

  int get _avatarVariant {
    var h = 0;
    for (final code in avatarSeed.codeUnits) {
      h = (h * 31 + code) & 0x7fffffff;
    }
    return h % 8;
  }

  String get _text => '${scene.atmosphere} ${scene.moment} ${passage.join(' ')}'.toLowerCase();

  bool get _rain =>
      _text.contains('rain') || _text.contains('storm') || _text.contains('wet');

  bool get _night =>
      _text.contains('night') || _text.contains('dark') || _text.contains('moon');

  bool get _indoors {
    final t = '${scene.title} ${scene.moment} ${scene.atmosphere}'.toLowerCase();
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
    _paintBackground(canvas, size, t);

    final beat = _currentBeat;
    final narrativePhase = _isNarrativePhase;
    final phaseProgress = _phaseProgress;
    final currentAction = _action(beat);
    final groupScene = _text.contains(' they ') || _text.contains('gentlemen') || _text.contains('family') || _text.contains('women') || _text.contains('girls') || _text.contains('people');
    final count = groupScene ? 2 : math.min(2, math.max(1, characters.length));
    for (var i = 0; i < count; i++) {
      final baseX = size.width * (i == 0 ? .30 : .70);
      final travel = narrativePhase ? 0.0 : Curves.easeInOut.transform(phaseProgress);
      final x = currentAction == 'walk'
          ? baseX + (i == 0 ? size.width * .25 : -size.width * .18) * travel
          : baseX;
      final scale = math.min(size.width, size.height) / 430;
      final action = narrativePhase ? 'idle' : (i == 0 ? currentAction : _secondaryAction(beat));
      _paintCharacter(canvas, Offset(x, size.height * .69), scale, phaseProgress, i, action, actionProgress: phaseProgress);
    }

    if (_rain) _paintRain(canvas, size);
    if (_warmLight) _paintWarmLight(canvas, size, t);
    if (narrativePhase) {
      _paintNarrativeCloud(canvas, size, beat);
    }
  }

  List<String> get _beats {
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

  double get _beatProgress => progress * _beats.length;
  int get _beatIndex => math.min(_beats.length - 1, _beatProgress.floor());
  bool get _isNarrativePhase => (_beatProgress % 1.0) < .67;

  double get _phaseProgress {
    final phase = _beatProgress % 1.0;
    return _isNarrativePhase ? phase / .67 : (phase - .67) / .33;
  }

  String get _currentBeat {
    final beats = _beats;
    if (beats.isEmpty) return scene.moment;
    return beats[_beatIndex];
  }

  String _action(String beat) {
    final t = '$beat $actionHint'.toLowerCase();
    if (t.contains('say') || t.contains('said') || t.contains('says') || t.contains('spoke') ||
        t.contains('speak') || t.contains('tell') || t.contains('asked') ||
        t.contains('replied') || t.contains('answer') || t.contains('conversation') ||
        t.contains('love') || t.contains('danger') || t.contains('objection')) { return 'talk'; }
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
    if (t.contains('carriage') || t.contains('horse') || t.contains('door') || t.contains('window')) { return 'look'; }
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
    final windowScene = text.contains('window') || text.contains('garden');
    final hallScene = text.contains('hall') || text.contains('corridor') || text.contains('stairs');

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * .68),
      Paint()..color = const Color(0xFFE6DDCC),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .68, size.width, size.height * .32),
      Paint()..color = const Color(0xFF5A4C43),
    );

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

    final table = Rect.fromLTWH(
      size.width * .10,
      size.height * .56,
      size.width * .80,
      size.height * .06,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(table, const Radius.circular(5)),
      Paint()..color = const Color(0xFF6D4D39),
    );

    if (drawingRoom || diningRoom) {
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
    Canvas canvas,
    Offset feet,
    double s,
    double phase,
    int index,
    String action, {
    double actionProgress = 0,
  }) {
    final swing = math.sin(phase * math.pi * 2);
    final act = Curves.easeInOut.transform(actionProgress.clamp(0.0, 1.0));
    final walk = action == 'walk';
    final reach = action == 'reach';
    final bob = math.sin(phase * math.pi * 4) * (walk ? 5 : 1.5) * s;
    final double bodyLean = action == 'look' ? math.sin(act * math.pi) * 18 * s : action == 'walk' ? math.sin(act * math.pi) * 5 * s : 0.0;
    const skins = [
      Color(0xFFF1D9B7), Color(0xFFD7A77D), Color(0xFFC78C69),
      Color(0xFF9B654B), Color(0xFFE5C09A), Color(0xFFB97858),
      Color(0xFFF0CBA8), Color(0xFF8D5A43),
    ];
    const coats = [
      Color(0xFF6F4050), Color(0xFF3E5870), Color(0xFF7A5A3A),
      Color(0xFF3F6B5B), Color(0xFF7B4E3D), Color(0xFF5C4A73),
      Color(0xFF596B46), Color(0xFF754B63),
    ];
    const hairs = [
      Color(0xFF4A3027), Color(0xFF2F2927), Color(0xFF6A422D),
      Color(0xFF211D1B), Color(0xFF8A5A35), Color(0xFF3A2420),
      Color(0xFF5A3A28), Color(0xFF2B2423),
    ];
    final variant = (_avatarVariant + index * 3) % 8;
    final coat = coats[variant];
    final hair = hairs[variant];
    final skin = skins[variant];
    final taller = variant == 1 || variant == 5;
    final compact = variant == 2 || variant == 7;
    final bodyScale = taller ? 1.12 : compact ? .90 : 1.0;
    final body = feet + Offset(bodyLean, -88 * s * bodyScale + bob);
    final head = body + Offset((action == 'look' ? math.sin(act * math.pi) * 30 : 0) * s, -65 * s * bodyScale);

    final dress = Path()
      ..moveTo(body.dx - 22 * s * bodyScale, body.dy)
      ..lineTo(body.dx - 42 * s * bodyScale, feet.dy - 3 * s)
      ..lineTo(body.dx + 42 * s * bodyScale, feet.dy - 3 * s)
      ..lineTo(body.dx + 22 * s * bodyScale, body.dy)
      ..close();

    canvas.drawOval(
      Rect.fromCenter(center: feet + Offset(0, 2 * s), width: 58 * s, height: 15 * s),
      Paint()..color = Colors.black.withValues(alpha: .28),
    );

    if (action == 'sit') {
      feet = feet + Offset(0, 16 * s);
    }

    canvas.drawPath(dress, Paint()..color = coat);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: body + Offset(0, -24 * s * bodyScale), width: 36 * s * bodyScale, height: 48 * s * bodyScale),
        Radius.circular(12 * s),
      ),
      Paint()..color = coat,
    );

    canvas.drawCircle(head, (20 + (variant % 3) * 2) * s, Paint()..color = skin);
    canvas.drawOval(
      Rect.fromCenter(center: head + Offset(0, -10 * s), width: (43 + variant * 1.5) * s, height: 27 * s),
      Paint()..color = hair,
    );

    final eye = Paint()..color = const Color(0xFF211D1A);
    canvas.drawCircle(head + Offset(-7 * s, 1 * s), 1.6 * s, eye);
    canvas.drawCircle(head + Offset(7 * s, 1 * s), 1.6 * s, eye);

    final armPaint = Paint()
      ..color = skin
      ..strokeWidth = 11 * s
      ..strokeCap = StrokeCap.round;

    final leftAngle = reach ? -1.15 - .75 * act : action == 'talk' ? -.95 + swing * .85 : -.35 + swing * .25;
    final rightAngle = reach ? .35 + 1.05 * act : action == 'talk' ? .95 - swing * .85 : .35 - swing * .25;
    _arm(canvas, body + Offset(-16 * s, -18 * s), leftAngle, 40 * s, armPaint);
    _arm(canvas, body + Offset(16 * s, -18 * s), rightAngle, 40 * s, armPaint);

    final legPaint = Paint()
      ..color = const Color(0xFF2B2A2D)
      ..strokeWidth = 12 * s
      ..strokeCap = StrokeCap.round;
    final step = walk ? swing * 13 * s : 0;
    canvas.drawLine(
      feet + Offset(-11 * s, -4 * s),
      feet + Offset(-13 * s + step, 2 * s),
      legPaint,
    );
    canvas.drawLine(
      feet + Offset(11 * s, -4 * s),
      feet + Offset(13 * s - step, 2 * s),
      legPaint,
    );
  }

  void _arm(Canvas canvas, Offset shoulder, double angle, double length, Paint paint) {
    final elbow = shoulder +
        Offset(math.cos(angle) * length * .52, math.sin(angle) * length * .52);
    final hand = shoulder +
        Offset(math.cos(angle) * length, math.sin(angle) * length);
    canvas.drawLine(shoulder, elbow, paint);
    canvas.drawLine(elbow, hand, paint);
    canvas.drawCircle(hand, paint.strokeWidth * .48, paint);
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
