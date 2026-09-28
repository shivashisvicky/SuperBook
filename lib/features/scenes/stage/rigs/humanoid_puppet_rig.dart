import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/scene_stage_script.dart';
import '../../../domain/book.dart';

class CharacterVisualProfile{
  const CharacterVisualProfile({required this.female,required this.child,required this.tall,required this.hair,required this.garment});
  final bool female,child,tall; final Color hair,garment;
  factory CharacterVisualProfile.from(BookCharacter c,String extra){
    final t='\${c.name} \${c.role} \${c.description} $extra'.toLowerCase();
    final word=(String x)=>' \${t.replaceAll(RegExp(r'[^a-z0-9]+'),' ')} '.contains(' $x ');
    var h=17;for(final x in t.codeUnits)h=(h*31+x)&0x7fffffff;
    return CharacterVisualProfile(female:['woman','female','girl','lady','mrs','miss','daughter','wife','mother','she','her'].any(word),child:['child','boy','girl','young'].any(word),tall:['tall','large','broad','stout'].any(word),hair:Color([0xFF38261F,0xFF211C1A,0xFF6B432B,0xFF8B5A36][h%4]),garment:Color([0xFF4B5D73,0xFF704B4A,0xFF566B50,0xFF6B5948,0xFF5C4B6F][h%5]));
  }
}
class HumanoidPose{
  const HumanoidPose({this.torso=0,this.head=0,this.lArm=-.2,this.rArm=.2,this.lFore=.1,this.rFore=-.1,this.lThigh=0,this.rThigh=0,this.lShin=0,this.rShin=0,this.pelvisY=0});
  final double torso,head,lArm,rArm,lFore,rFore,lThigh,rThigh,lShin,rShin,pelvisY;
  static HumanoidPose lerp(HumanoidPose a,HumanoidPose b,double t)=>HumanoidPose(torso:a.torso+(b.torso-a.torso)*t,head:a.head+(b.head-a.head)*t,lArm:a.lArm+(b.lArm-a.lArm)*t,rArm:a.rArm+(b.rArm-a.rArm)*t,lFore:a.lFore+(b.lFore-a.lFore)*t,rFore:a.rFore+(b.rFore-a.rFore)*t,lThigh:a.lThigh+(b.lThigh-a.lThigh)*t,rThigh:a.rThigh+(b.rThigh-a.rThigh)*t,lShin:a.lShin+(b.lShin-a.lShin)*t,rShin:a.rShin+(b.rShin-a.rShin)*t,pelvisY:a.pelvisY+(b.pelvisY-a.pelvisY)*t);
  static const idle=HumanoidPose();
  static const walkA=HumanoidPose(torso:-.06,lArm:-.8,rArm:.8,lFore:-.15,rFore:.15,lThigh:-.5,rThigh:.4,lShin:.1,rShin:-.12);
  static const walkB=HumanoidPose(torso:-.03,lArm:.55,rArm:-.55,lThigh:.3,rThigh:-.25,lShin:-.2,rShin:.25,pelvisY:-.025);
  static const sit=HumanoidPose(pelvisY:.16,torso:-.02,lArm:-.2,rArm:.2,lThigh:1.28,rThigh:1.28,lShin:-.35,rShin:-.35);
  static const talkA=HumanoidPose(head:-.04,lArm:-.9,lFore:-.9,rArm:.3,rFore:-.3);
  static const talkB=HumanoidPose(head:.04,lArm:-.25,lFore:.45,rArm:.9,rFore:.1);
  static const listen=HumanoidPose(head:.04);
  static const reach=HumanoidPose(torso:-.1,head:-.06,lArm:-1,lFore:-.2,rArm:.95,rFore:-.1);
  static const fightA=HumanoidPose(torso:-.12,lArm:-1.5,lFore:-.4,rArm:1.25,rFore:-.8,lThigh:-.2,rThigh:.2);
  static const fightB=HumanoidPose(torso:.08,lArm:-.8,lFore:-1.2,rArm:1.5,rFore:-.2,lThigh:.15,rThigh:-.15);
}
class HumanoidPuppetRig{
  HumanoidPuppetRig(this.profile);final CharacterVisualProfile profile;
  HumanoidPose pose(ActorPose a,double p){switch(a){case ActorPose.walk:case ActorPose.run:return HumanoidPose.lerp(HumanoidPose.walkA,HumanoidPose.walkB,(math.sin(p*math.pi*2)+1)/2);case ActorPose.sitIdle:case ActorPose.sitRead:case ActorPose.sitWrite:return HumanoidPose.sit;case ActorPose.talkGesture:return HumanoidPose.lerp(HumanoidPose.talkA,HumanoidPose.talkB,(math.sin(p*math.pi*2)+1)/2);case ActorPose.listenAttentive:case ActorPose.lookWindow:return HumanoidPose.listen;case ActorPose.reachObject:return HumanoidPose.reach;case ActorPose.combatSlash:return HumanoidPose.lerp(HumanoidPose.fightA,HumanoidPose.fightB,(math.sin(p*math.pi*2)+1)/2);default:return HumanoidPose.idle;}}
  void paint(Canvas c,Offset o,double u,double p,ActorPose a,double facing){
    final q=pose(a,p),s=u*(profile.child?.78:profile.tall?1.08:1),hip=o+Offset(0,q.pelvisY*s),torso=hip+Offset(math.sin(q.torso)*12*s,-54*s),shoulder=torso+Offset(math.sin(q.torso)*8*s,-44*s),head=shoulder+Offset(math.sin(q.head)*8*s,-32*s);
    final skin=Paint()..color=const Color(0xFFE0B58F),hair=Paint()..color=profile.hair,cloth=Paint()..color=profile.garment,limb=Paint()..color=const Color(0xFF2C292C)..strokeWidth=7*s..strokeCap=StrokeCap.round,arm=Paint()..color=const Color(0xFFE0B58F)..strokeWidth=7*s..strokeCap=StrokeCap.round;
    _leg(c,hip,31*s,-math.pi/2+q.lThigh,30*s,q.lShin,limb);_leg(c,hip,31*s,-math.pi/2+q.rThigh,30*s,q.rShin,limb);
    if(profile.female){final d=Path()..moveTo(shoulder.dx-15*s,shoulder.dy)..lineTo(shoulder.dx+15*s,shoulder.dy)..quadraticBezierTo(hip.dx+30*s,hip.dy+22*s,hip.dx+38*s,hip.dy+44*s)..lineTo(hip.dx-38*s,hip.dy+44*s)..quadraticBezierTo(hip.dx-30*s,hip.dy+22*s,shoulder.dx-15*s,shoulder.dy)..close();c.drawPath(d,cloth);}else{c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:torso,width:36*s,height:56*s),Radius.circular(7*s)),cloth);}
    _arm(c,shoulder+Offset(-15*s,3*s),29*s,-math.pi/2+q.lArm,27*s,q.lFore,arm);_arm(c,shoulder+Offset(15*s,3*s),29*s,-math.pi/2+q.rArm,27*s,q.rFore,arm);
    c.drawCircle(head,17*s,skin);c.drawOval(Rect.fromCenter(center:head+Offset(0,-8*s),width:38*s,height:22*s),hair);
    if(profile.female){c.drawCircle(head+Offset(-15*s,8*s),7*s,hair);c.drawCircle(head+Offset(15*s,8*s),7*s,hair);}
    final eye=Paint()..color=const Color(0xFF211D1A),ex=7*s*(facing<0?-1:1);c.drawCircle(head+Offset(ex,-s),1.5*s,eye);c.drawCircle(head+Offset(ex+4*s*(facing<0?-1:1),-s),1.2*s,eye);
    if(a==ActorPose.talkGesture){final m=.7+.6*((math.sin(p*math.pi*8)+1)/2);c.drawOval(Rect.fromCenter(center:head+Offset(8*s*(facing<0?-1:1),8*s),width:6*s,height:m*5*s),Paint()..color=const Color(0xFF6B3838));}
  }
  void _leg(Canvas c,Offset r,double l1,double a1,double l2,double a2,Paint p){final k=r+Offset(math.cos(a1)*l1,math.sin(a1)*l1),f=k+Offset(math.cos(a1+a2)*l2,math.sin(a1+a2)*l2);c.drawLine(r,k,p);c.drawLine(k,f,p);}
  void _arm(Canvas c,Offset r,double l1,double a1,double l2,double a2,Paint p){final e=r+Offset(math.cos(a1)*l1,math.sin(a1)*l1),h=e+Offset(math.cos(a1+a2)*l2,math.sin(a1+a2)*l2);c.drawLine(r,e,p);c.drawLine(e,h,p);c.drawCircle(h,p.strokeWidth*.55,p);}
}