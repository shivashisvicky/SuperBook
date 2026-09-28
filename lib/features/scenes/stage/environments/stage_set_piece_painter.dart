// ignore_for_file: curly_braces_in_flow_control_structures, prefer_function_declarations_over_variables

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/scene_stage_script.dart';

class StageSetPiecePainter {
  void paint(Canvas c, Size s, StageSetPiece p, double t) {
    final id = p.id.toLowerCase();
    if (id == 'outside_window' || id == 'outside') return;
    final x = s.width * p.x;
    final y = s.height * p.y;
    final k = math.min(s.width, s.height) * .0055 * p.scale;
    final shadow = Paint()..color = Colors.black.withValues(alpha: .14);

    if (id.contains('door')) {
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y + 28 * k), width: 45 * k, height: 8 * k),
        shadow,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y - 12 * k), width: 38 * k, height: 78 * k),
          Radius.circular(2 * k),
        ),
        Paint()..color = const Color(0xFF563B2E),
      );
      c.drawCircle(
        Offset(x + 11 * k, y - 12 * k),
        2.5 * k,
        Paint()..color = const Color(0xFFD6A84A),
      );
    } else if (id.contains('window')) {
      final r = Rect.fromCenter(
        center: Offset(x, y - 18 * k),
        width: 58 * k,
        height: 48 * k,
      );
      c.drawRect(r, Paint()..color = const Color(0xFF557C92));
      final q = Paint()
        ..color = const Color(0xFFE7D5B2)
        ..strokeWidth = 3 * k
        ..style = PaintingStyle.stroke;
      c.drawRect(r, q);
      c.drawLine(r.centerLeft, r.centerRight, q);
      c.drawLine(r.topCenter, r.bottomCenter, q);
    } else if (id.contains('table') || id.contains('desk')) {
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y + 22 * k), width: 105 * k, height: 13 * k),
        shadow,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 92 * k, height: 10 * k),
          Radius.circular(2 * k),
        ),
        Paint()..color = const Color(0xFF704A32),
      );
      final leg = Paint()
        ..color = const Color(0xFF543A2C)
        ..strokeWidth = 5 * k;
      c.drawLine(
        Offset(x - 32 * k, y + 5 * k),
        Offset(x - 38 * k, y + 45 * k),
        leg,
      );
      c.drawLine(
        Offset(x + 32 * k, y + 5 * k),
        Offset(x + 38 * k, y + 45 * k),
        leg,
      );
    } else if (id.contains('fireplace') || id.contains('hearth')) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 78 * k, height: 62 * k),
          Radius.circular(4 * k),
        ),
        Paint()..color = const Color(0xFF49352D),
      );
      c.drawRect(
        Rect.fromCenter(center: Offset(x, y + 5 * k), width: 45 * k, height: 32 * k),
        Paint()..color = const Color(0xFF241D1A),
      );
      c.drawCircle(Offset(x, y + 10 * k), 9 * k, Paint()..color = const Color(0xFFE88A35));
      c.drawCircle(Offset(x - 7 * k, y + 8 * k), 5 * k, Paint()..color = const Color(0xFFF4C34E));
    } else if (id.contains('tree') || id.contains('wood')) {
      final sway = math.sin(t * 1.7 + x * .01) * 3 * k;
      c.drawLine(
        Offset(x, y),
        Offset(x + sway, y + 55 * k),
        Paint()..color = const Color(0xFF5A4030)..strokeWidth = 9 * k,
      );
      final q = Paint()..color = const Color(0xFF3F613F);
      c.drawCircle(Offset(x + sway, y), 30 * k, q);
      c.drawCircle(Offset(x - 20 * k + sway, y + 10 * k), 21 * k, q);
      c.drawCircle(Offset(x + 20 * k + sway, y + 10 * k), 21 * k, q);
    } else if (id.contains('carriage')) {
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y + 32 * k), width: 125 * k, height: 15 * k),
        shadow,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 125 * k, height: 52 * k),
          Radius.circular(9 * k),
        ),
        Paint()..color = const Color(0xFF5B3425),
      );
      c.drawRect(
        Rect.fromCenter(center: Offset(x, y - 8 * k), width: 76 * k, height: 27 * k),
        Paint()..color = const Color(0xFF7D4A32),
      );
      for (final wx in <double>[-40, 40]) {
        c.drawCircle(Offset(x + wx * k, y + 28 * k), 14 * k, Paint()..color = const Color(0xFF28262A));
      }
    } else if (id.contains('chair') || id.contains('armchair')) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 48 * k, height: 54 * k),
          Radius.circular(7 * k),
        ),
        Paint()..color = const Color(0xFF76513D),
      );
      c.drawRect(
        Rect.fromLTWH(x - 20 * k, y + 22 * k, 40 * k, 5 * k),
        Paint()..color = const Color(0xFF543A2C),
      );
    } else if (id.contains('bookcase')) {
      c.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 72 * k, height: 155 * k),
        Paint()..color = const Color(0xFF46352E),
      );
      for (var i = 0; i < 5; i++) {
        c.drawRect(
          Rect.fromCenter(center: Offset(x, y - 62 * k + i * 31 * k), width: 62 * k, height: 4 * k),
          Paint()..color = const Color(0xFF98724D),
        );
      }
    } else if (id.contains('bed')) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 145 * k, height: 62 * k),
          Radius.circular(5 * k),
        ),
        Paint()..color = const Color(0xFF61463B),
      );
      c.drawRect(
        Rect.fromCenter(center: Offset(x, y - 8 * k), width: 125 * k, height: 42 * k),
        Paint()..color = const Color(0xFFB9A7A0),
      );
    } else if (id.contains('lamp')) {
      final q = Paint()
        ..color = const Color(0xFF47382F)
        ..strokeWidth = 4 * k;
      c.drawLine(Offset(x, y + 55 * k), Offset(x, y - 5 * k), q);
      c.drawCircle(Offset(x, y - 10 * k), 13 * k, Paint()..color = const Color(0xFFE9C46A));
    } else if (id.contains('bench')) {
      final q = Paint()
        ..color = const Color(0xFF68452F)
        ..strokeWidth = 7 * k;
      c.drawLine(Offset(x - 35 * k, y), Offset(x + 35 * k, y), q);
      c.drawLine(Offset(x - 25 * k, y + 5 * k), Offset(x - 30 * k, y + 30 * k), q);
      c.drawLine(Offset(x + 25 * k, y + 5 * k), Offset(x + 30 * k, y + 30 * k), q);
    } else if (id.contains('boat')) {
      final path = Path()
        ..moveTo(x - 48 * k, y)
        ..quadraticBezierTo(x, y + 28 * k, x + 48 * k, y)
        ..lineTo(x + 35 * k, y + 10 * k)
        ..lineTo(x - 35 * k, y + 10 * k)
        ..close();
      c.drawPath(path, Paint()..color = const Color(0xFF5C3A2A));
    } else if (id.contains('pier')) {
      final q = Paint()
        ..color = const Color(0xFF6B4A32)
        ..strokeWidth = 9 * k;
      for (var i = -2; i <= 2; i++) {
        c.drawLine(Offset(x + i * 25 * k, y), Offset(x + i * 25 * k, y + 55 * k), q);
      }
      c.drawLine(Offset(x - 60 * k, y), Offset(x + 60 * k, y), q);
    } else if (id.contains('flag')) {
      final q = Paint()
        ..color = const Color(0xFF514238)
        ..strokeWidth = 3 * k;
      c.drawLine(Offset(x, y + 50 * k), Offset(x, y - 45 * k), q);
      final path = Path()
        ..moveTo(x, y - 44 * k)
        ..lineTo(x + 35 * k, y - 33 * k)
        ..lineTo(x, y - 20 * k)
        ..close();
      c.drawPath(path, Paint()..color = const Color(0xFF8B463D));
    } else if (id.contains('rock')) {
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 38 * k, height: 22 * k),
        Paint()..color = const Color(0xFF5A5048),
      );
    } else if (id.contains('map')) {
      c.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 55 * k, height: 38 * k),
        Paint()..color = const Color(0xFFE5D4A9),
      );
    } else if (id.contains('key')) {
      c.drawCircle(
        Offset(x, y),
        6 * k,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * k
          ..color = const Color(0xFFD2A94E),
      );
      c.drawLine(
        Offset(x + 6 * k, y),
        Offset(x + 24 * k, y),
        Paint()
          ..color = const Color(0xFFD2A94E)
          ..strokeWidth = 2 * k,
      );
    }
  }
}
