// ignore_for_file: curly_braces_in_flow_control_structures, prefer_function_declarations_over_variables
import 'dart:math' as math;
import 'package:flutter/material.dart';
class QuadrupedPuppetRig{
  void paintDog(Canvas c,Offset o,double s,double p,{bool barking=false}){
    final body=Paint()..color=const Color(0xFF956342),dark=Paint()..color=const Color(0xFF3B2A23),leg=Paint()..color=dark.color..strokeWidth=.16*s..strokeCap=StrokeCap.round;
    c.drawOval(Rect.fromCenter(center:o,width:2.6*s,height:1.1*s),body);final h=o+Offset(1.1*s,-.32*s);c.drawCircle(h,.58*s,body);
    c.drawPath(Path()..moveTo(h.dx-.35*s,h.dy-.3*s)..lineTo(h.dx-.1*s,h.dy-.75*s)..lineTo(h.dx+.08*s,h.dy-.2*s)..close(),dark);
    for(var i=0;i<4;i++){final x=o.dx+(-.75+i*.5)*s;final lift=math.max(0,math.sin(p*math.pi*2+i*math.pi/2))*.18*s;c.drawLine(Offset(x,o.dy+.3*s),Offset(x,o.dy+1*s-lift),leg);}
    c.drawLine(o+Offset(-1.1*s,-.1*s),o+Offset(-1.6*s,-.5*s+math.sin(p*math.pi*4)*.4*s),leg);
    if(barking){final jaw=.6+.4*((math.sin(p*math.pi*8)+1)/2);c.drawOval(Rect.fromCenter(center:h+Offset(.48*s,.23*s),width:.3*s,height:.2*s*jaw),dark);}
  }
}