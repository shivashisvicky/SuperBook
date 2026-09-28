import 'package:flutter/material.dart';
import '../../domain/book.dart';
import '../../domain/experience/ai_scene_plan.dart';
import '../../domain/experience/superbook_scene_graph.dart';
import 'stage/models/scene_stage_script.dart';
import 'stage/superbook_stage_compositor.dart';

class SuperBookLocalAnimationStage extends StatelessWidget {
  const SuperBookLocalAnimationStage({super.key,required this.scene,required this.passage,required this.characters,this.actionHint='',this.backgroundImageBase64,this.scenePlan,this.narrativeFocus=''});

  final Scene scene;final List<String> passage;final List<BookCharacter> characters;final String actionHint;final String? backgroundImageBase64;final AiScenePlan? scenePlan;final String narrativeFocus;

  SceneStageScript _script(){
    if(scenePlan!=null){
      final graph=SuperBookSceneGraph.from(plan:scenePlan!,scene:scene,bookCharacters:characters,passage:passage,narrativeFocus:narrativeFocus);
      return SceneStageScript.fromGraph(graph:graph,bookCharacters:characters,scene:scene,passage:passage);
    }
    final cast=<CharacterPuppetSpec>[];
    for(var i=0;i<characters.length&&i<2;i++){cast.add(CharacterPuppetSpec(id:'character_$i',name:characters[i].name,description:characters[i].description,x:(i == 0 ? .34 : .66),y:.68,facing:i==0?1:-1));}
    if(cast.isEmpty)cast.add(const CharacterPuppetSpec(id:'protagonist',name:'Protagonist',description:'',x:.5,y:.68,facing:1));
    final text='${scene.moment} $actionHint'.toLowerCase();var pose=ActorPose.idleStand;
    if(text.contains('walk')||text.contains('enter')||text.contains('cross'))pose=ActorPose.walk;
    else if(text.contains('talk')||text.contains('said')||text.contains('asked'))pose=ActorPose.talkGesture;
    else if(text.contains('read')||text.contains('book')||text.contains('letter'))pose=ActorPose.sitRead;
    else if(text.contains('reach')||text.contains('open'))pose=ActorPose.reachObject;
    return SceneStageScript(biome:EnvironmentBiome.neutral,lighting:LightingMood.daylight,setPieces:const [],cast:cast,beats:[ChoreographedBeat(text:scene.moment,durationMs:4200,tracks:cast.map((a)=>ActorTrack(actorId:a.id,pose:pose)).toList())]);
  }
  @override Widget build(BuildContext context)=>SuperBookStageCompositor(script:_script(),characters:characters,passage:passage);
}