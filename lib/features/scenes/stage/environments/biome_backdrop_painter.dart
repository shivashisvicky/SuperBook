import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/scene_stage_script.dart';

class BiomeBackdropPainter{
  void paint(Canvas c,Size s,EnvironmentBiome b,LightingMood l,double t,{bool blooming=false}){
    final night=l==LightingMood.nightMoon;final top=night?const Color(0xFF172236):const Color(0xFF91A8B8);final bottom=night?const Color(0xFF313849):const Color(0xFFD7C7A9);
    c.drawRect(Offset.zero&s,Paint()..shader=LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[top,bottom]).createShader(Offset.zero&s));
    final outdoor={EnvironmentBiome.forestWoodland,EnvironmentBiome.gardenMeadow,EnvironmentBiome.streetStation,EnvironmentBiome.seaHarbor,EnvironmentBiome.battlefield,EnvironmentBiome.roadCarriage}.contains(b);
    if(outdoor){final ground=b==EnvironmentBiome.seaHarbor?const Color(0xFF4B7082):b==EnvironmentBiome.battlefield?const Color(0xFF65503E):const Color(0xFF526A4C);c.drawRect(Rect.fromLTWH(0,s.height*.55,s.width,s.height*.45),Paint()..color=ground);
      if(b==EnvironmentBiome.forestWoodland||b==EnvironmentBiome.gardenMeadow){for(var i=0;i<6;i++){final x=s.width*(.06+i*.18),sw=math.sin(t*1.2+i)*4;c.drawLine(Offset(x,s.height*.30),Offset(x+sw,s.height*.58),Paint()..color=const Color(0xFF5B4635)..strokeWidth=8);c.drawCircle(Offset(x+sw,s.height*.29),28,Paint()..color=const Color(0xFF456143));if(blooming){final blossom=Paint()..color=const Color(0xFFF1D6DF);for(var j=0;j<7;j++){final a=j*math.pi*2/7+t*.2;c.drawCircle(Offset(x+sw+math.cos(a)*20,s.height*.29+math.sin(a)*15),3,blossom);}}}}
      if(b==EnvironmentBiome.seaHarbor){for(var i=0;i<7;i++){final y=s.height*(.58+i*.055);c.drawLine(Offset(0,y),Offset(s.width,y+math.sin(t*1.4+i)*4),Paint()..color=Colors.white.withValues(alpha:.18)..strokeWidth=2);}}
    }else{c.drawRect(Rect.fromLTWH(0,s.height*.68,s.width,s.height*.32),Paint()..color=const Color(0xFF51443D));c.drawRect(Rect.fromLTWH(0,0,s.width,s.height*.68),Paint()..color=const Color(0xFFE4D9C8));}
    if(l==LightingMood.overcastRain){final p=Paint()..color=Colors.white.withValues(alpha:.22)..strokeWidth=1.3;for(var i=0;i<70;i++){final x=(i*47+t*180)%s.width,y=(i*71+t*260)%s.height;c.drawLine(Offset(x,y),Offset(x-5,y+16),p);}}
    if(l==LightingMood.warmHearth||l==LightingMood.candlelight)c.drawCircle(Offset(s.width*.55,s.height*.4),s.width*.55,Paint()..shader=RadialGradient(colors:[Colors.amber.withValues(alpha:.12),Colors.transparent]).createShader(Rect.fromCircle(center:Offset(s.width*.55,s.height*.4),radius:s.width*.55)));
    if(night)c.drawCircle(Offset(s.width*.8,s.height*.17),s.width*.055,Paint()..color=const Color(0xFFF3EAC8));
  }
}
