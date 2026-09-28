import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/scene_stage_script.dart';

class StageSetPiecePainter{
  void paint(Canvas c,Size s,StageSetPiece p,double t){
    final x=s.width*p.x,y=s.height*p.y,k=math.min(s.width,s.height)*.01*p.scale,id=p.id.toLowerCase();
    if(id.contains('door')){c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(x,y),width:30*k,height:58*k),Radius.circular(2*k)),Paint()..color=const Color(0xFF5A4033));}
    else if(id.contains('window')){final r=Rect.fromCenter(center:Offset(x,y-18*k),width:42*k,height:34*k);c.drawRect(r,Paint()..color=const Color(0xFF7893A0));final q=Paint()..color=const Color(0xFFE0C79D)..strokeWidth=2*k;c.drawLine(r.centerLeft,r.centerRight,q);c.drawLine(r.topCenter,r.bottomCenter,q);}
    else if(id.contains('table')||id.contains('desk')){final q=Paint()..color=const Color(0xFF6B4B36)..strokeWidth=5*k..strokeCap=StrokeCap.round;c.drawLine(Offset(x-42*k,y),Offset(x+42*k,y),q);c.drawLine(Offset(x-30*k,y),Offset(x-34*k,y+32*k),q);c.drawLine(Offset(x+30*k,y),Offset(x+34*k,y+32*k),q);}
    else if(id.contains('fireplace')||id.contains('hearth')){c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(x,y),width:52*k,height:44*k),Radius.circular(4*k)),Paint()..color=const Color(0xFF4A3329));c.drawCircle(Offset(x,y+8*k),7*k,Paint()..color=const Color(0xFFE88A35));}
    else if(id.contains('tree')||id.contains('wood')){final sway=math.sin(t*1.7+x*.01)*3*k;c.drawLine(Offset(x,y),Offset(x+sway,y+55*k),Paint()..color=const Color(0xFF5A4030)..strokeWidth=7*k);final q=Paint()..color=const Color(0xFF47633F);c.drawCircle(Offset(x+sway,y),24*k,q);c.drawCircle(Offset(x-18*k+sway,y+8*k),18*k,q);c.drawCircle(Offset(x+18*k+sway,y+8*k),18*k,q);}
    else if(id.contains('carriage')){final q=Paint()..color=const Color(0xFF5B3425);c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(x,y),width:110*k,height:48*k),Radius.circular(8*k)),q);c.drawCircle(Offset(x-35*k,y+27*k),12*k,Paint()..color=const Color(0xFF29262A));c.drawCircle(Offset(x+35*k,y+27*k),12*k,Paint()..color=const Color(0xFF29262A));}
    else if(id.contains('chair')||id.contains('armchair')){c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(x,y),width:38*k,height:44*k),Radius.circular(5*k)),Paint()..color=const Color(0xFF71513F));}
    else if(id.contains('map')){c.drawRect(Rect.fromCenter(center:Offset(x,y),width:45*k,height:30*k),Paint()..color=const Color(0xFFE5D4A9));}
    else if(id.contains('key')){c.drawCircle(Offset(x,y),5*k,Paint()..style=PaintingStyle.stroke..strokeWidth=2*k..color=const Color(0xFFD2A94E));c.drawLine(Offset(x+5*k,y),Offset(x+20*k,y),Paint()..color=const Color(0xFFD2A94E)..strokeWidth=2*k);}
  }
}