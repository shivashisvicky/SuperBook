// ignore_for_file: curly_braces_in_flow_control_structures, prefer_function_declarations_over_variables
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/scene_stage_script.dart';
import '../../../../domain/book.dart';

class CharacterVisualProfile{
  const CharacterVisualProfile({required this.female,required this.child,required this.tall,required this.hair,required this.garment});
  final bool female,child,tall; final Color hair,garment;
  factory CharacterVisualProfile.from(BookCharacter c,String extra){
    final t='${c.name} ${c.role} ${c.description} $extra'.toLowerCase();
    final word=(String x)=>' ${t.replaceAll(RegExp(r'[^a-z0-9]+'),' ')} '.contains(' $x ');
    var h=17;for(final x in t.codeUnits)h=(h*31+x)&0x7fffffff;
    return CharacterVisualProfile(female:['woman','female','girl','lady','mrs','miss','ms','madam','daughter','sister','wife','mother','aunt','niece','queen','princess','duchess','she','her','elizabeth','jane','lydia','mary','kitty','catherine','charlotte','georgiana','alice','emma','elinor','marianne','anne','fanny','lucy','maria'].any(word),child:['child','boy','girl','young','little'].any(word),tall:['tall','large','broad','stout','gentleman'].any(word),hair:Color([0xFF38261F,0xFF211C1A,0xFF6B432B,0xFF8B5A36][h%4]),garment:Color([0xFF4B5D73,0xFF704B4A,0xFF566B50,0xFF6B5948,0xFF5C4B6F][h%5]));
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
  void paint(Canvas c, Offset o, double u, double p, ActorPose a, double facing) {
    final q = pose(a, p);
    final s = u * (profile.child ? .78 : profile.tall ? 1.08 : 1.0);
    final dir = facing < 0 ? -1.0 : 1.0;

    c.save();
    c.translate(o.dx, o.dy);
    c.scale(dir, 1.0);

    final hip = Offset(0, q.pelvisY * s);
    final shoulder = hip + Offset(math.sin(q.torso) * 10 * s, -52 * s);
    final torsoCenter =
        Offset((hip.dx + shoulder.dx) * .5, (hip.dy + shoulder.dy) * .5);
    final neck = shoulder + Offset(0, -6 * s);
    final head = neck + Offset(math.sin(q.head) * 4 * s, -16 * s);

    final skin = Paint()..color = const Color(0xFFE0B58F);
    final hair = Paint()..color = profile.hair;
    final cloth = Paint()..color = profile.garment;
    final darkCloth =
        Paint()..color = Color.lerp(profile.garment, Colors.black, .28)!;
    final limb = Paint()
      ..color = const Color(0xFF2C292C)
      ..strokeWidth = 7 * s
      ..strokeCap = StrokeCap.round;
    final armPaint = Paint()
      ..color = profile.garment
      ..strokeWidth = 6.5 * s
      ..strokeCap = StrokeCap.round;
    final shadow = Paint()..color = Colors.black.withValues(alpha: .16);

    c.drawOval(
      Rect.fromCenter(center: const Offset(0, 62) * s, width: 44 * s, height: 9 * s),
      shadow,
    );

    _arm(
      c,
      shoulder + Offset(-11 * s, 4 * s),
      23 * s,
      math.pi / 2 + q.lArm,
      21 * s,
      q.lFore,
      armPaint,
      skin,
    );

    _leg(
      c,
      hip + Offset(-7 * s, 0),
      29 * s,
      math.pi / 2 + q.lThigh,
      29 * s,
      q.lShin,
      limb,
    );
    _leg(
      c,
      hip + Offset(7 * s, 0),
      29 * s,
      math.pi / 2 + q.rThigh,
      29 * s,
      q.rShin,
      limb,
    );

    if (profile.female) {
      final skirtDrop = (a == ActorPose.sitIdle ||
              a == ActorPose.sitRead ||
              a == ActorPose.sitWrite)
          ? 26 * s
          : 46 * s;
      final d = Path()
        ..moveTo(shoulder.dx - 13 * s, shoulder.dy)
        ..lineTo(shoulder.dx + 13 * s, shoulder.dy)
        ..quadraticBezierTo(
          hip.dx + 20 * s,
          hip.dy + 10 * s,
          hip.dx + 26 * s,
          hip.dy + skirtDrop,
        )
        ..lineTo(hip.dx - 26 * s, hip.dy + skirtDrop)
        ..quadraticBezierTo(
          hip.dx - 20 * s,
          hip.dy + 10 * s,
          shoulder.dx - 13 * s,
          shoulder.dy,
        )
        ..close();
      c.drawPath(d, cloth);
    } else {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: torsoCenter, width: 30 * s, height: 54 * s),
          Radius.circular(8 * s),
        ),
        cloth,
      );
      c.drawRect(
        Rect.fromCenter(center: hip, width: 28 * s, height: 10 * s),
        darkCloth,
      );
    }

    c.drawLine(
      shoulder,
      head + Offset(0, 10 * s),
      Paint()
        ..color = const Color(0xFFE0B58F)
        ..strokeWidth = 8 * s
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(head, 15 * s, skin);
    c.drawOval(
      Rect.fromCenter(
        center: head + Offset(-2 * s, -8 * s),
        width: 32 * s,
        height: 18 * s,
      ),
      hair,
    );
    if (profile.female) {
      c.drawCircle(head + Offset(-12 * s, -2 * s), 7 * s, hair);
    }

    final eye = Paint()..color = const Color(0xFF211D1A);
    c.drawCircle(head + Offset(6 * s, -2 * s), 1.6 * s, eye);
    c.drawCircle(head + Offset(11 * s, -2 * s), 1.4 * s, eye);
    if (a == ActorPose.talkGesture) {
      final m = .6 + .6 * ((math.sin(p * math.pi * 8) + 1) / 2);
      c.drawOval(
        Rect.fromCenter(
          center: head + Offset(7 * s, 6 * s),
          width: 4.5 * s,
          height: m * 4 * s,
        ),
        Paint()..color = const Color(0xFF6B3838),
      );
    }

    final handPos = _arm(
      c,
      shoulder + Offset(11 * s, 4 * s),
      23 * s,
      math.pi / 2 + q.rArm,
      21 * s,
      q.rFore,
      armPaint,
      skin,
    );
    if (a == ActorPose.sitRead || a == ActorPose.sitWrite) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: handPos + Offset(6 * s, -3 * s),
            width: 14 * s,
            height: 18 * s,
          ),
          Radius.circular(2 * s),
        ),
        Paint()..color = const Color(0xFFF3E7C9),
      );
    }

    c.restore();
  }

  void _leg(Canvas c,Offset r,double l1,double a1,double l2,double a2,Paint p){final k=r+Offset(math.cos(a1)*l1,math.sin(a1)*l1),f=k+Offset(math.cos(a1+a2)*l2,math.sin(a1+a2)*l2);c.drawLine(r,k,p);c.drawLine(k,f,p);}
  void _arm(Canvas c,Offset r,double l1,double a1,double l2,double a2,Paint p){final e=r+Offset(math.cos(a1)*l1,math.sin(a1)*l1),h=e+Offset(math.cos(a1+a2)*l2,math.sin(a1+a2)*l2);c.drawLine(r,e,p);c.drawLine(e,h,p);c.drawCircle(h,p.strokeWidth*.55,p);}
}