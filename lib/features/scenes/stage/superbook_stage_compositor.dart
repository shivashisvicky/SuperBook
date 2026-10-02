// ignore_for_file: curly_braces_in_flow_control_structures, prefer_function_declarations_over_variables, prefer_interpolation_to_compose_strings
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models/scene_stage_script.dart';
import 'rigs/humanoid_puppet_rig.dart';
import 'rigs/quadruped_puppet_rig.dart';
import 'environments/biome_backdrop_painter.dart';
import 'environments/stage_set_piece_painter.dart';
import '../../../domain/book.dart';

class SuperBookStageCompositor extends StatefulWidget{
  const SuperBookStageCompositor({super.key,required this.script,required this.characters,required this.passage});
  final SceneStageScript script;final List<BookCharacter> characters;final List<String> passage;
  @override State<SuperBookStageCompositor> createState()=>_SuperBookStageCompositorState();
}
class _SuperBookStageCompositorState extends State<SuperBookStageCompositor> with SingleTickerProviderStateMixin{
  late final AnimationController controller;
  @override void initState(){super.initState();controller=AnimationController(vsync:this,duration:Duration(milliseconds:_duration()))..repeat();}
  String _scriptSignature(SceneStageScript s)=>s.biome.name+'|'+s.lighting.name+'|'+s.cast.map((c)=>c.id+':'+c.x.toStringAsFixed(3)).join(',')+'|'+s.beats.map((b)=>b.text+':'+b.durationMs.toString()).join('|');
  @override void didUpdateWidget(covariant SuperBookStageCompositor old){super.didUpdateWidget(old);if(_scriptSignature(old.script)!=_scriptSignature(widget.script)){controller.duration=Duration(milliseconds:_duration());controller..stop()..reset()..repeat();}}
  int _duration()=>math.max(3000,widget.script.beats.fold<int>(0,(a,b)=>a+b.durationMs));
  int _beat(double p){var left=p*_duration();for(var i=0;i<widget.script.beats.length;i++){if(left<widget.script.beats[i].durationMs)return i;left-=widget.script.beats[i].durationMs;}return math.max(0,widget.script.beats.length-1);}
  double _phase(double p,int index){var left=p*_duration();for(var i=0;i<index;i++)left-=widget.script.beats[i].durationMs;return ((left/widget.script.beats[index].durationMs).clamp(0.0,1.0)).toDouble();}
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:controller,builder:(context,_){final index=_beat(controller.value);final phase=widget.script.beats.isEmpty?0.0:_phase(controller.value,index);return CustomPaint(painter:_StagePainter(progress:controller.value,script:widget.script,characters:widget.characters,passage:widget.passage,beatIndex:index,beatProgress:phase),child:const SizedBox.expand());});
  @override void dispose(){controller.dispose();super.dispose();}
}

class _StagePainter extends CustomPainter{
  _StagePainter({required this.progress,required this.script,required this.characters,required this.passage,required this.beatIndex,required this.beatProgress});
  final double progress;final SceneStageScript script;final List<BookCharacter> characters;final List<String> passage;final int beatIndex;final double beatProgress;
  final backdrop=BiomeBackdropPainter();final setPieces=StageSetPiecePainter();final dogs=QuadrupedPuppetRig();

  @override void paint(Canvas c,Size s){
    final t=progress*math.pi*2;
    c.save();
    final zoom=1+.025*math.sin(t);c.translate(s.width/2,s.height/2);c.scale(zoom);c.translate(-s.width/2,-s.height/2);
    final storyText=passage.join(' ').toLowerCase();
    final blooming=storyText.contains('bloom')||storyText.contains('blossom')||storyText.contains('flower');
    backdrop.paint(c,s,script.biome,script.lighting,t,blooming:blooming);
    final pieces=[...script.setPieces]..sort((a,b)=>a.depth.compareTo(b.depth));
    for(final p in pieces)setPieces.paint(c,s,p,t);
    if(script.beats.isNotEmpty){
      final beat=script.beats[beatIndex];
      final ordered=[...script.cast]..sort((a,b)=>a.y.compareTo(b.y));
      CharacterVisualProfile? firstProfile;
      for(final actor in ordered){
        final track=beat.tracks.firstWhere((x)=>x.actorId==actor.id,orElse:()=>ActorTrack(actorId:actor.id,pose:ActorPose.idleStand));
        var x=track.startX??actor.x,y=actor.y;
        if((track.pose==ActorPose.walk||track.pose==ActorPose.run)&&track.targetX!=null){
          final e=Curves.easeInOut.transform(beatProgress);
          final startX=track.startX??actor.x;
          x=startX+(track.targetX!-startX)*e;
          y=actor.y+((track.targetY??actor.y)-actor.y)*e;
        }
        final bookCharacter=characters.where((c)=>c.name.toLowerCase()==actor.name.toLowerCase()).firstOrNull;
        final source=bookCharacter??BookCharacter(name:actor.name,role:'',description:actor.description);
        final slotIndex=script.cast.indexWhere((item)=>item.id==actor.id);
        final castIndex=slotIndex<0?0:slotIndex;
        var profile=CharacterVisualProfile.from(source,actor.description,slotIndex:castIndex);
        if(firstProfile!=null &&
            (profile.garment==firstProfile.garment || profile.hair==firstProfile.hair)){
          profile=CharacterVisualProfile.from(source,actor.description,slotIndex:castIndex+1);
        }
        firstProfile ??= profile;
        HumanoidPuppetRig(profile).paint(c,Offset(x*s.width,(y-.045)*s.height),math.min(s.width,s.height)/360,beatProgress,track.pose,track.facing??actor.facing);
      }
      _paintBeatBubble(c,s,beat,ordered);
    }
    final text=passage.join(' ').toLowerCase();
    if(text.contains('dog')||text.contains('hound')||text.contains('puppy'))dogs.paintDog(c,Offset(s.width*.82,s.height*.70),math.min(s.width,s.height)/125,progress,barking:text.contains('bark'));
    c.restore();
    if(script.lighting==LightingMood.overcastRain)c.drawRect(Offset.zero&s,Paint()..color=Colors.blueGrey.withValues(alpha:.035));
    if(script.lighting==LightingMood.warmHearth||script.lighting==LightingMood.candlelight)c.drawRect(Offset.zero&s,Paint()..color=Colors.amber.withValues(alpha:.018));
  }
  void _paintBeatBubble(Canvas c,Size s,ChoreographedBeat beat,List<CharacterPuppetSpec> ordered){
    final activeTrack=beat.tracks.firstWhere((track)=>track.pose!=ActorPose.listenAttentive&&track.pose!=ActorPose.idleStand,orElse:()=>beat.tracks.isEmpty?const ActorTrack(actorId:'',pose:ActorPose.idleStand):beat.tracks.first);
    final actor=ordered.firstWhere((item)=>item.id==activeTrack.actorId,orElse:()=>ordered.isEmpty?const CharacterPuppetSpec(id:'',name:'',description:'',x:.5,y:.78,facing:1):ordered.first);
    var text=beat.text.replaceAll('_','').replaceAll(RegExp(r'[\^§\$]+'),'').replaceAll(RegExp(r'\\s+'),' ').trim();
    if(text.length>150) text=text.substring(0,147)+'…';
    if(text.isEmpty)return;
    final textPainter=TextPainter(
      text:TextSpan(text:text,style:const TextStyle(color:Colors.white,fontSize:13,height:1.22,fontWeight:FontWeight.w500)),
      textDirection:TextDirection.ltr,maxLines:4,ellipsis:'…',
    );
    final maxWidth=s.width*.72;
    textPainter.layout(maxWidth:maxWidth);
    const paddingX=14.0;
    const paddingY=10.0;
    final width=(textPainter.width+paddingX*2).clamp(110.0,maxWidth+paddingX*2).toDouble();
    final height=textPainter.height+paddingY*2;
    final centerX=(actor.x*s.width).clamp(width/2+10,s.width-width/2-10).toDouble();
    final top=s.height*.17;
    final rect=RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(centerX,top+height/2),width:width,height:height),const Radius.circular(14));
    final bubblePaint=Paint()..color=const Color(0xE61A1D25);
    c.drawRRect(rect,bubblePaint);
    c.drawRRect(rect,Paint()..style=PaintingStyle.stroke..strokeWidth=1..color=Colors.white.withValues(alpha:.16));
    textPainter.paint(c,Offset(rect.left+paddingX,rect.top+paddingY));
    if(activeTrack.pose==ActorPose.talkGesture){
      final tailX=(actor.x*s.width).clamp(rect.left+18,rect.right-18).toDouble();
      final path=Path()..moveTo(tailX-7,rect.bottom-1)..lineTo(tailX,rect.bottom+10)..lineTo(tailX+7,rect.bottom-1)..close();
      c.drawPath(path,bubblePaint);
    }
  }

  @override bool shouldRepaint(covariant _StagePainter old)=>old.progress!=progress||old.beatIndex!=beatIndex||old.beatProgress!=beatProgress||old.script!=script;
}