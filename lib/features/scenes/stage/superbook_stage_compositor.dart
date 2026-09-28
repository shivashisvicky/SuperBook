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
  @override void didUpdateWidget(covariant SuperBookStageCompositor old){super.didUpdateWidget(old);if(old.script!=widget.script){controller.duration=Duration(milliseconds:_duration());controller..stop()..reset()..repeat();}}
  int _duration()=>math.max(3000,widget.script.beats.fold<int>(0,(a,b)=>a+b.durationMs));
  int _beat(double p){var left=p*_duration();for(var i=0;i<widget.script.beats.length;i++){if(left<widget.script.beats[i].durationMs)return i;left-=widget.script.beats[i].durationMs;}return math.max(0,widget.script.beats.length-1);}
  double _phase(double p,int index){var left=p*_duration();for(var i=0;i<index;i++)left-=widget.script.beats[i].durationMs;return (left/widget.script.beats[index].durationMs).clamp(0.0,1.0);}
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:controller,builder:(context,_){final index=_beat(controller.value);final phase=widget.script.beats.isEmpty?0:_phase(controller.value,index);return CustomPaint(painter:_StagePainter(progress:controller.value,script:widget.script,characters:widget.characters,passage:widget.passage,beatIndex:index,beatProgress:phase),child:const SizedBox.expand());});
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
      for(final actor in ordered){
        final track=beat.tracks.firstWhere((x)=>x.actorId==actor.id,orElse:()=>ActorTrack(actorId:actor.id,pose:ActorPose.idleStand));
        var x=actor.x,y=actor.y;
        if(track.pose==ActorPose.walk&&track.targetX!=null){
          final e=Curves.easeInOut.transform(beatProgress);
          x=actor.x+(track.targetX!-actor.x)*e;
          y=actor.y+((track.targetY??actor.y)-actor.y)*e;
        }
        final bookCharacter=characters.where((c)=>c.name.toLowerCase()==actor.name.toLowerCase()).firstOrNull;
        final source=bookCharacter??BookCharacter(name:actor.name,role:'',description:actor.description);
        final profile=CharacterVisualProfile.from(source,actor.description);
        HumanoidPuppetRig(profile).paint(c,Offset(x*s.width,y*s.height),math.min(s.width,s.height)/360,beatProgress,track.pose,track.facing??actor.facing);
      }
    }
    final text=passage.join(' ').toLowerCase();
    if(text.contains('dog')||text.contains('hound')||text.contains('puppy'))dogs.paintDog(c,Offset(s.width*.82,s.height*.70),math.min(s.width,s.height)/125,progress,barking:text.contains('bark'));
    c.restore();
    if(script.lighting==LightingMood.overcastRain)c.drawRect(Offset.zero&s,Paint()..color=Colors.blueGrey.withValues(alpha:.035));
    if(script.lighting==LightingMood.warmHearth||script.lighting==LightingMood.candlelight)c.drawRect(Offset.zero&s,Paint()..color=Colors.amber.withValues(alpha:.018));
  }
  @override bool shouldRepaint(covariant _StagePainter old)=>old.progress!=progress||old.beatIndex!=beatIndex||old.script!=script;
}