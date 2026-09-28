import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/scene_stage_script.dart';

class BiomeBackdropPainter{
  void paint(Canvas c,Size s,EnvironmentBiome b,LightingMood l,double t,{bool blooming=false}){
    final night=l==LightingMood.nightMoon;
    final top=night?const Color(0xFF121A2B):const Color(0xFF7898AE);
    final bottom=night?const Color(0xFF303A50):const Color(0xFFD5C4A3);
    c.drawRect(Offset.zero&s,Paint()..shader=LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[top,bottom]).createShader(Offset.zero&s));
    final outdoor={EnvironmentBiome.forestWoodland,EnvironmentBiome.gardenMeadow,EnvironmentBiome.streetStation,EnvironmentBiome.seaHarbor,EnvironmentBiome.battlefield,EnvironmentBiome.roadCarriage}.contains(b);
    if(outdoor){_outdoor(c,s,b,t,blooming);}
    else if(b==EnvironmentBiome.neutral){c.drawRect(Rect.fromLTWH(0,s.height*.72,s.width,s.height*.28),Paint()..color=const Color(0xFF56483E));}
    else {_interior(c,s,b);}
    if(l==LightingMood.overcastRain){final p=Paint()..color=Colors.white.withValues(alpha:.22)..strokeWidth=1.4;for(var i=0;i<90;i++){final x=(i*47+t*180)%s.width,y=(i*71+t*260)%s.height;c.drawLine(Offset(x,y),Offset(x-5,y+18),p);}}
    if(l==LightingMood.warmHearth||l==LightingMood.candlelight)c.drawCircle(Offset(s.width*.55,s.height*.48),s.width*.58,Paint()..shader=RadialGradient(colors:[Colors.amber.withValues(alpha:.16),Colors.transparent]).createShader(Rect.fromCircle(center:Offset(s.width*.55,s.height*.48),radius:s.width*.58)));
    if(night)c.drawCircle(Offset(s.width*.82,s.height*.14),s.width*.045,Paint()..color=const Color(0xFFF4EAC9));
  }
  void _outdoor(Canvas c,Size s,EnvironmentBiome b,double t,bool blooming){
    final ground=b==EnvironmentBiome.seaHarbor?const Color(0xFF365F73):b==EnvironmentBiome.battlefield?const Color(0xFF62513F):const Color(0xFF486347);
    c.drawRect(Rect.fromLTWH(0,s.height*.58,s.width,s.height*.42),Paint()..color=ground);
    if(b==EnvironmentBiome.seaHarbor){
      c.drawRect(Rect.fromLTWH(0,s.height*.52,s.width,s.height*.48),Paint()..color=const Color(0xFF416F82));
      for(var i=0;i<9;i++){final y=s.height*(.58+i*.045);final p=Paint()..color=Colors.white.withValues(alpha:.18)..strokeWidth=2;for(var j=0;j<4;j++){final x=s.width*(j*.28)+math.sin(t*1.3+i)*8;c.drawLine(Offset(x,y),Offset(x+55,y+math.sin(t*1.5+i+j)*3),p);}}
    }
    if(b==EnvironmentBiome.streetStation){for(var i=0;i<5;i++){final x=s.width*(.05+i*.23);c.drawRect(Rect.fromLTWH(x,s.height*.31,s.width*.18,s.height*.28),Paint()..color=const Color(0xFF75665B));c.drawRect(Rect.fromLTWH(x+.02*s.width,s.height*.35,s.width*.14,s.height*.10),Paint()..color=const Color(0xFF9EB4BE));}}
    if(b==EnvironmentBiome.forestWoodland||b==EnvironmentBiome.gardenMeadow||b==EnvironmentBiome.roadCarriage){
      for(var i=0;i<8;i++){final x=s.width*(.03+i*.135);final far=i.isEven;final y=far?s.height*.38:s.height*.51;final scale=far?.72:1.0;_tree(c,Offset(x,y),scale,t+i*.4,blooming&&i%2==0);}
    }
    if(b==EnvironmentBiome.battlefield){for(var i=0;i<6;i++){final x=s.width*(.08+i*.17);c.drawCircle(Offset(x,s.height*.61+(i%2)*9),18,Paint()..color=const Color(0xFF514238));}}
  }
  void _tree(Canvas c,Offset o,double scale,double t,bool bloom){
    final sway=math.sin(t*1.4)*4*scale;final trunk=Paint()..color=const Color(0xFF594333)..strokeWidth=10*scale..strokeCap=StrokeCap.round;
    c.drawLine(o+Offset(sway,40*scale),o+Offset(sway,-20*scale),trunk);
    final leaf=Paint()..color=const Color(0xFF35553B);
    c.drawCircle(o+Offset(sway,-32*scale),34*scale,leaf);c.drawCircle(o+Offset(sway-24*scale,-15*scale),25*scale,leaf);c.drawCircle(o+Offset(sway+25*scale,-12*scale),27*scale,leaf);
    if(bloom){final p=Paint()..color=const Color(0xFFF0D1DB);for(var i=0;i<8;i++){final a=i*math.pi/4+t*.15;c.drawCircle(o+Offset(sway+math.cos(a)*25*scale,-28*scale+math.sin(a)*20*scale),3*scale,p);}}
  }
  void _interior(Canvas c,Size s,EnvironmentBiome b){
    final wall=b==EnvironmentBiome.libraryStudy?const Color(0xFF6E5B50):b==EnvironmentBiome.bedchamber?const Color(0xFFC8B6A2):b==EnvironmentBiome.hearthStudy?const Color(0xFF705A4B):b==EnvironmentBiome.diningHall?const Color(0xFFB89D78):b==EnvironmentBiome.corridorHall?const Color(0xFF8A7A6B):const Color(0xFFC7B49B);
    c.drawRect(Rect.fromLTWH(0,0,s.width,s.height*.72),Paint()..color=wall);
    c.drawRect(Rect.fromLTWH(0,s.height*.72,s.width,s.height*.28),Paint()..color=const Color(0xFF4B3B33));
    final trim=Paint()..color=const Color(0xFFE3D0AE)..strokeWidth=3;c.drawLine(Offset(0,s.height*.66),Offset(s.width,s.height*.66),trim);
    if(b==EnvironmentBiome.libraryStudy){for(var i=0;i<5;i++){final x=s.width*(.05+i*.20);c.drawRect(Rect.fromLTWH(x,s.height*.18,s.width*.14,s.height*.43),Paint()..color=const Color(0xFF46362F));for(var j=0;j<4;j++)c.drawRect(Rect.fromLTWH(x+8,s.height*(.22+j*.085),s.width*.12,5),Paint()..color=const Color(0xFF9B7650));}}
    if(b==EnvironmentBiome.diningHall)c.drawRect(Rect.fromLTWH(s.width*.08,s.height*.08,s.width*.84,4),Paint()..color=const Color(0xFF6B4D3D));
    if(b==EnvironmentBiome.bedchamber)c.drawRect(Rect.fromLTWH(s.width*.12,s.height*.14,s.width*.18,s.height*.38),Paint()..color=const Color(0xFFB8C5D0));
    if(b==EnvironmentBiome.corridorHall){for(var i=0;i<4;i++)c.drawRect(Rect.fromLTWH(s.width*(.18+i*.22),s.height*.22,s.width*.12,s.height*.30),Paint()..color=const Color(0xFF67584E));}
    if(b==EnvironmentBiome.drawingParlor||b==EnvironmentBiome.hearthStudy)c.drawCircle(Offset(s.width*.5,s.height*.34),s.width*.11,Paint()..color=const Color(0xFFD6C1A4)..style=PaintingStyle.stroke..strokeWidth=5);
  }
}