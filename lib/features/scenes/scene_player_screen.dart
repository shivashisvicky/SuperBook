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
                theme: widget.scene.visualTheme,
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
                          Text('Narrative beat · intensity ${widget.beat.intensity}'),
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
  _ScenePainter({
    required this.progress,
    required this.intensity,
    required this.theme,
  });

  final double progress;
  final int intensity;
  final String theme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF090B13),
    );

    switch (theme) {
      case 'estate':
        _paintEstate(canvas, size);
        break;
      case 'sea':
        _paintSea(canvas, size);
        break;
      case 'forest':
        _paintForest(canvas, size);
        break;
      case 'city':
        _paintCity(canvas, size);
        break;
      case 'interior':
        _paintInterior(canvas, size);
        break;
      case 'night':
        _paintNight(canvas, size);
        break;
      case 'journey':
        _paintJourney(canvas, size);
        break;
      case 'battle':
        _paintBattle(canvas, size);
        break;
      default:
        _paintNeutral(canvas, size);
    }

    _paintVignette(canvas, size);
  }

  void _paintEstate(Canvas canvas, Size size) {
    final ground = size.height * 0.68;
    canvas.drawRect(
      Rect.fromLTWH(0, ground, size.width, size.height - ground),
      Paint()..color = const Color(0xFF172017),
    );

    final house = Path()
      ..moveTo(size.width * .18, ground)
      ..lineTo(size.width * .18, size.height * .43)
      ..lineTo(size.width * .50, size.height * .28)
      ..lineTo(size.width * .82, size.height * .43)
      ..lineTo(size.width * .82, ground)
      ..close();
    canvas.drawPath(house, Paint()..color = const Color(0xFF30313A));

    final warm = Paint()..color = const Color(0xFFFFD889);
    for (final x in [0.34, 0.50, 0.66]) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(size.width * x, size.height * .51),
          width: size.width * .07,
          height: size.height * .10,
        ),
        warm,
      );
    }

    final tree = Paint()..color = const Color(0xFF1C2A1E);
    for (final x in [.08, .92]) {
      canvas.drawCircle(Offset(size.width * x, ground * .73), size.width * .12, tree);
      canvas.drawCircle(Offset(size.width * x, ground * .52), size.width * .08, tree);
    }

    final people = Paint()..color = const Color(0xFFD8D2C4);
    final sway = math.sin(progress * math.pi * 2) * 5;
    for (final x in [0.44, 0.56]) {
      final px = size.width * x + (x < .5 ? sway : -sway);
      canvas.drawCircle(Offset(px, ground - 74), 10, people);
      canvas.drawLine(Offset(px, ground - 64), Offset(px, ground - 20), people..strokeWidth = 5);
      canvas.drawLine(Offset(px, ground - 48), Offset(px + (x < .5 ? 15 : -15), ground - 32), people..strokeWidth = 3);
    }
  }

  void _paintSea(Canvas canvas, Size size) {
    final horizon = size.height * .54;
    canvas.drawRect(Rect.fromLTWH(0, horizon, size.width, size.height - horizon),
        Paint()..color = const Color(0xFF123044));
    final sky = Paint()..color = const Color(0xFF151B2B);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizon), sky);

    final wave = Paint()
      ..color = const Color(0xFF8CB9C8).withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 7; i++) {
      final y = horizon + i * 34.0;
      final path = Path();
      for (var x = 0.0; x <= size.width; x += 24) {
        final yy = y + math.sin(x / 55 + progress * math.pi * 2 + i) * 6;
        if (x == 0) {
          path.moveTo(x, yy);
        } else {
          path.lineTo(x, yy);
        }
      }
      canvas.drawPath(path, wave);
    }

    final shipX = size.width * (.28 + .35 * progress);
    final hull = Path()
      ..moveTo(shipX - 90, horizon - 4)
      ..lineTo(shipX + 90, horizon - 4)
      ..lineTo(shipX + 58, horizon + 25)
      ..lineTo(shipX - 60, horizon + 25)
      ..close();
    canvas.drawPath(hull, Paint()..color = const Color(0xFF252A33));
    final mast = Paint()..color = const Color(0xFFB8A47A)..strokeWidth = 3;
    canvas.drawLine(Offset(shipX, horizon - 120), Offset(shipX, horizon + 8), mast);
    final sail = Path()
      ..moveTo(shipX, horizon - 112)
      ..lineTo(shipX + 65, horizon - 45)
      ..lineTo(shipX, horizon - 45)
      ..close();
    canvas.drawPath(sail, Paint()..color = const Color(0xFFD9D2BD));
  }

  void _paintForest(Canvas canvas, Size size) {
    final ground = size.height * .70;
    canvas.drawRect(Rect.fromLTWH(0, ground, size.width, size.height - ground),
        Paint()..color = const Color(0xFF101A16));
    for (var i = 0; i < 9; i++) {
      final x = size.width * (i / 8);
      final trunk = Paint()..color = const Color(0xFF29251F)..strokeWidth = 8;
      canvas.drawLine(Offset(x, ground), Offset(x + (i.isEven ? -12 : 12), size.height * .28), trunk);
      final crown = Paint()..color = const Color(0xFF173126);
      canvas.drawCircle(Offset(x, size.height * .25), size.width * .13, crown);
    }
    final path = Path()
      ..moveTo(size.width * .45, ground)
      ..quadraticBezierTo(size.width * .50, size.height * .54, size.width * .50, size.height * .31)
      ..lineTo(size.width * .56, size.height * .31)
      ..quadraticBezierTo(size.width * .56, size.height * .54, size.width * .62, ground)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF39442D));
  }

  void _paintCity(Canvas canvas, Size size) {
    final road = size.height * .70;
    canvas.drawRect(Rect.fromLTWH(0, road, size.width, size.height - road),
        Paint()..color = const Color(0xFF16171B));
    for (var i = 0; i < 7; i++) {
      final w = size.width * (.09 + (i % 3) * .035);
      final x = i * size.width / 6;
      final top = size.height * (.24 + (i % 3) * .08);
      canvas.drawRect(Rect.fromLTRB(x, top, x + w, road),
          Paint()..color = const Color(0xFF252733));
      for (var row = 0; row < 3; row++) {
        for (var col = 0; col < 2; col++) {
          canvas.drawRect(
            Rect.fromLTWH(x + 8 + col * 20, top + 18 + row * 26, 9, 12),
            Paint()..color = const Color(0xFFFFD982).withValues(alpha: .72),
          );
        }
      }
    }
    final personX = size.width * (.35 + .3 * math.sin(progress * math.pi * 2));
    final p = Paint()..color = const Color(0xFFD0D2D8);
    canvas.drawCircle(Offset(personX, road - 58), 8, p);
    p.strokeWidth = 4;
    canvas.drawLine(Offset(personX, road - 50), Offset(personX, road - 15), p);
  }

  void _paintInterior(Canvas canvas, Size size) {
    final wall = Paint()..color = const Color(0xFF29242A);
    canvas.drawRect(Offset.zero & size, wall);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .73, size.width, size.height * .27),
      Paint()..color = const Color(0xFF1C1515),
    );
    final table = Paint()..color = const Color(0xFF4A3022);
    canvas.drawRect(Rect.fromLTWH(size.width*.16, size.height*.65, size.width*.68, 18), table);
    canvas.drawRect(Rect.fromLTWH(size.width*.20, size.height*.67, 18, size.height*.18), table);
    canvas.drawRect(Rect.fromLTWH(size.width*.75, size.height*.67, 18, size.height*.18), table);
    final glow = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFFFFD984).withValues(alpha: .38),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(
        center: Offset(size.width*.5, size.height*.46),
        radius: size.width*.35,
      ));
    canvas.drawCircle(Offset(size.width*.5, size.height*.46), size.width*.35, glow);
    canvas.drawRect(Rect.fromCenter(
      center: Offset(size.width*.5, size.height*.46),
      width: 22,
      height: 70,
    ), Paint()..color = const Color(0xFFFFD984));
    final p = Paint()..color = const Color(0xFFD0C7BC);
    canvas.drawCircle(Offset(size.width*.38, size.height*.60), 9, p);
    canvas.drawCircle(Offset(size.width*.62, size.height*.60), 9, p);
  }

  void _paintNight(Canvas canvas, Size size) {
    canvas.drawCircle(Offset(size.width*.78, size.height*.22), size.width*.10,
        Paint()..color = const Color(0xFFE7E2C8));
    final ground = size.height*.70;
    canvas.drawRect(Rect.fromLTWH(0, ground, size.width, size.height-ground),
        Paint()..color = const Color(0xFF0E1416));
    final p = Paint()..color = const Color(0xFF252C36);
    canvas.drawRect(Rect.fromLTWH(size.width*.30, ground*.66, size.width*.40, ground*.34), p);
  }

  void _paintJourney(Canvas canvas, Size size) {
    final ground = size.height*.70;
    canvas.drawRect(Rect.fromLTWH(0, ground, size.width, size.height-ground),
        Paint()..color = const Color(0xFF253020));
    final road = Path()
      ..moveTo(size.width*.38, size.height)
      ..quadraticBezierTo(size.width*.48, ground, size.width*.52, size.height*.34)
      ..quadraticBezierTo(size.width*.55, ground, size.width*.68, size.height);
    canvas.drawPath(road, Paint()..color = const Color(0xFF6D604D));
    final x = size.width*(.30 + .25*progress);
    final p = Paint()..color = const Color(0xFFD2D0C8);
    canvas.drawCircle(Offset(x, ground-55), 8, p);
    p.strokeWidth = 4;
    canvas.drawLine(Offset(x, ground-47), Offset(x, ground-10), p);
  }

  void _paintBattle(Canvas canvas, Size size) {
    final ground = size.height*.66;
    canvas.drawRect(Rect.fromLTWH(0, ground, size.width, size.height-ground),
        Paint()..color = const Color(0xFF2A211E));
    for (var i=0;i<10;i++) {
      final x=size.width*(i/9);
      final smoke=Paint()..color=const Color(0xFF57515A).withValues(alpha:.35);
      canvas.drawCircle(Offset(x, size.height*(.28+(i%3)*.07)), 45+(i%4)*12.0, smoke);
    }
    final p=Paint()..color=const Color(0xFFC8B9A1);
    for(var i=0;i<5;i++){
      final x=size.width*(.18+i*.16)+math.sin(progress*math.pi*2+i)*8;
      canvas.drawCircle(Offset(x,ground-55),7,p);
      p.strokeWidth=4;
      canvas.drawLine(Offset(x,ground-47),Offset(x,ground-10),p);
    }
  }

  void _paintNeutral(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .48);
    final glow = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF8C8DFF).withValues(alpha: .24),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: center, radius: size.width*.42));
    canvas.drawCircle(center, size.width*.42, glow);
    final p=Paint()..color=const Color(0xFFD8D9E2);
    canvas.drawCircle(Offset(size.width*.5,size.height*.45),14,p);
    p.strokeWidth=5;
    canvas.drawLine(Offset(size.width*.5,size.height*.47),Offset(size.width*.5,size.height*.68),p);
  }

  void _paintVignette(Canvas canvas, Size size) {
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.48)],
        stops: const [0.55, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity ||
      oldDelegate.theme != theme;
}
