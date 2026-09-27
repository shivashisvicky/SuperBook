import 'dart:math' as math;
import 'package:flutter/material.dart';

class SuperBookAnimationLabScreen extends StatefulWidget {
  const SuperBookAnimationLabScreen({super.key});
  @override
  State<SuperBookAnimationLabScreen> createState() => _SuperBookAnimationLabScreenState();
}

class _SuperBookAnimationLabScreenState extends State<SuperBookAnimationLabScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _story = 0;

  static const stories = <_LabStory>[
    _LabStory('The Arrival', 'The traveler walks to the gate, stops, and looks toward the house.', _LabKind.arrival),
    _LabStory('The Door', 'The traveler crosses the porch, reaches for the handle, and opens the door.', _LabKind.door),
    _LabStory('The Key', 'The traveler reaches for the brass key, lifts it, and studies the mark.', _LabKind.key),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _selectStory(int index) {
    setState(() => _story = index);
    _controller.forward(from: 0);
    _controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    final story = stories[_story];
    return Scaffold(
      backgroundColor: const Color(0xFF111317),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Row(
                children: [
                  const Icon(Icons.movie_creation_outlined),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('SuperBook Animation Lab',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                  Text('\${_story + 1} / \${stories.length}',
                      style: const TextStyle(color: Colors.white60)),
                ],
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _AnimationLabPainter(progress: _controller.value, kind: story.kind),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF191C22),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Text(story.title,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text(story.action, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, height: 1.3)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: stories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => ChoiceChip(
                        label: Text(stories[index].title),
                        selected: index == _story,
                        onSelected: (_) => _selectStory(index),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _LabKind { arrival, door, key }

class _LabStory {
  const _LabStory(this.title, this.action, this.kind);
  final String title;
  final String action;
  final _LabKind kind;
}

class _AnimationLabPainter extends CustomPainter {
  _AnimationLabPainter({required this.progress, required this.kind});
  final double progress;
  final _LabKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final scene = Offset.zero & size;
    canvas.drawRect(
      scene,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8FA1B5), Color(0xFFE0CDAE)],
        ).createShader(scene),
    );
    switch (kind) {
      case _LabKind.arrival: _arrival(canvas, size);
      case _LabKind.door: _door(canvas, size);
      case _LabKind.key: _keyScene(canvas, size);
    }
  }

  void _arrival(Canvas c, Size s) {
    _ground(c, s);
    _house(c, s);
    final p = Curves.easeInOut.transform(progress);
    final walk = _segment(p, 0, .45);
    final look = _segment(p, .45, .63);
    final point = _segment(p, .63, .84);
    final x = _lerp(s.width * .08, s.width * .43, walk);
    _person(c, Offset(x, s.height * .72), walk: p < .45, look: look, point: point, phase: p * math.pi * 2);
  }

  void _door(Canvas c, Size s) {
    _ground(c, s);
    _porch(c, s);
    final p = Curves.easeInOut.transform(progress);
    final walk = _segment(p, 0, .24);
    final open = _segment(p, .24, .57);
    final enter = _segment(p, .57, .84);
    final x = _lerp(s.width * .22, s.width * .50, walk);
    final finalX = _lerp(x, s.width * .68, enter);
    _doorLeaf(c, s, open);
    _person(c, Offset(finalX, s.height * .72),
        walk: p < .24 || (p > .57 && p < .84),
        reach: open, look: _segment(p, .84, 1), phase: p * math.pi * 2);
  }

  void _keyScene(Canvas c, Size s) {
    _room(c, s);
    _table(c, s);
    final p = Curves.easeInOut.transform(progress);
    final reach = _segment(p, 0, .34);
    final lift = _segment(p, .34, .62);
    final study = _segment(p, .62, .88);
    _key(c, s, lift);
    _person(c, Offset(s.width * .48, s.height * .76),
        reach: reach, liftKey: lift, look: study, phase: p * math.pi * 2);
  }

  void _ground(Canvas c, Size s) {
    c.drawRect(Rect.fromLTWH(0, s.height * .72, s.width, s.height * .28),
        Paint()..color = const Color(0xFF4C5A49));
  }

  void _house(Canvas c, Size s) {
    c.drawRect(Rect.fromLTWH(s.width * .42, s.height * .30, s.width * .46, s.height * .43),
        Paint()..color = const Color(0xFF9A8065));
    final roof = Path()..moveTo(s.width * .35, s.height * .32)
      ..lineTo(s.width * .65, s.height * .12)..lineTo(s.width * .95, s.height * .32)..close();
    c.drawPath(roof, Paint()..color = const Color(0xFF3F3A38));
    c.drawRect(Rect.fromLTWH(s.width * .62, s.height * .48, s.width * .13, s.height * .25),
        Paint()..color = const Color(0xFF543E32));
    c.drawRect(Rect.fromLTWH(s.width * .75, s.height * .43, s.width * .09, s.height * .13),
        Paint()..color = const Color(0xFFFFD889));
  }

  void _porch(Canvas c, Size s) {
    c.drawRect(Rect.fromLTWH(0, s.height * .72, s.width, s.height * .28),
        Paint()..color = const Color(0xFF564A43));
    c.drawRect(Rect.fromLTWH(s.width * .28, s.height * .28, s.width * .44, s.height * .44),
        Paint()..color = const Color(0xFFD8C2A0));
    c.drawRect(Rect.fromLTWH(s.width * .28, s.height * .28, s.width * .44, s.height * .44),
        Paint()..style = PaintingStyle.stroke..strokeWidth = 10..color = const Color(0xFF694C39));
  }

  void _doorLeaf(Canvas c, Size s, double open) {
    final hinge = Offset(s.width * .72, s.height * .28);
    c.save();
    c.translate(hinge.dx, hinge.dy);
    c.rotate(-open * math.pi * .62);
    c.drawRect(Rect.fromLTWH(-s.width * .44, 0, s.width * .44, s.height * .44),
        Paint()..color = const Color(0xFF9E7955));
    c.restore();
  }

  void _room(Canvas c, Size s) {
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height * .72),
        Paint()..color = const Color(0xFFE5DDCD));
    c.drawRect(Rect.fromLTWH(0, s.height * .72, s.width, s.height * .28),
        Paint()..color = const Color(0xFF514943));
  }

  void _table(Canvas c, Size s) {
    c.drawRect(Rect.fromLTWH(s.width * .16, s.height * .55, s.width * .68, s.height * .08),
        Paint()..color = const Color(0xFF6B4D3A));
    c.drawRect(Rect.fromLTWH(s.width * .33, s.height * .48, s.width * .28, s.height * .09),
        Paint()..color = const Color(0xFFD0B277));
  }

  void _key(Canvas c, Size s, double lift) {
    final y = _lerp(s.height * .47, s.height * .33, lift);
    final p = Offset(s.width * .48, y);
    final paint = Paint()..color = const Color(0xFFD7AA45)..style = PaintingStyle.stroke..strokeWidth = 5;
    c.drawCircle(p, 10, paint);
    c.drawLine(p + const Offset(8, 0), p + const Offset(38, 0), paint);
    c.drawLine(p + const Offset(27, 0), p + const Offset(27, 10), paint);
    c.drawLine(p + const Offset(34, 0), p + const Offset(34, 8), paint);
  }

  void _person(Canvas c, Offset feet, {
    bool walk = false, double look = 0, double reach = 0, double point = 0,
    double liftKey = 0, required double phase,
  }) {
    final s = math.min(c.getLocalClipBounds().width, 500) / 430;
    final swing = math.sin(phase);
    final bob = walk ? math.sin(phase * 2) * 5 * s : 0;
    final body = feet + Offset(0, -92 * s + bob);
    final head = body + Offset(look * 20 * s, -66 * s);
    final skin = const Color(0xFFF1D9B7);
    final coat = const Color(0xFF6B4051);
    final dark = const Color(0xFF292A2D);

    c.drawOval(Rect.fromCenter(center: feet + const Offset(0, 2), width: 64 * s, height: 16 * s),
        Paint()..color = Colors.black.withValues(alpha: .25));
    c.drawPath(Path()..moveTo(body.dx - 23*s, body.dy)..lineTo(body.dx - 43*s, feet.dy)
      ..lineTo(body.dx + 43*s, feet.dy)..lineTo(body.dx + 23*s, body.dy)..close(),
      Paint()..color = coat);
    c.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: body + Offset(0, -25*s), width: 38*s, height: 50*s),
      Radius.circular(10*s)), Paint()..color = coat);
    c.drawCircle(head, 22*s, Paint()..color = skin);
    c.drawOval(Rect.fromCenter(center: head + Offset(0,-11*s), width: 45*s, height: 28*s),
        Paint()..color = const Color(0xFF432F27));

    final arm = Paint()..color = skin..strokeWidth = 11*s..strokeCap = StrokeCap.round;
    final leftAngle = reach > 0 ? -1.25 - reach*.75 : point > 0 ? -.55 - point*.55 : -.35 + swing*.30;
    final rightAngle = reach > 0 ? -.20 - reach*.35 : point > 0 ? -.10 - point*.10 : .35 - swing*.30;
    _arm(c, body + Offset(-16*s,-18*s), leftAngle, 44*s, arm);
    _arm(c, body + Offset(16*s,-18*s), rightAngle, 44*s, arm);

    final legs = Paint()..color = dark..strokeWidth = 12*s..strokeCap = StrokeCap.round;
    final step = walk ? swing * 15*s : 0;
    c.drawLine(feet + Offset(-11*s,-5*s), feet + Offset(-14*s+step,2*s), legs);
    c.drawLine(feet + Offset(11*s,-5*s), feet + Offset(14*s-step,2*s), legs);

    if (liftKey > 0) {
      final hand = body + Offset(12*s, -48*s - liftKey*24*s);
      c.drawCircle(hand, 5*s, Paint()..color = const Color(0xFFD7AA45));
    }
  }

  void _arm(Canvas c, Offset shoulder, double angle, double length, Paint paint) {
    final elbow = shoulder + Offset(math.cos(angle)*length*.52, math.sin(angle)*length*.52);
    final hand = shoulder + Offset(math.cos(angle)*length, math.sin(angle)*length);
    c.drawLine(shoulder, elbow, paint);
    c.drawLine(elbow, hand, paint);
    c.drawCircle(hand, paint.strokeWidth*.48, paint);
  }

  double _segment(double p, double start, double end) {
    if (p <= start) return 0;
    if (p >= end) return 1;
    return Curves.easeInOut.transform((p-start)/(end-start));
  }

  double _lerp(double a, double b, double t) => a + (b-a)*t;

  @override
  bool shouldRepaint(covariant _AnimationLabPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.kind != kind;
}
