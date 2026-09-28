// ignore_for_file: curly_braces_in_flow_control_structures, prefer_function_declarations_over_variables
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
    final effectivePlan=scenePlan??const AiScenePlan(
      schemaVersion:'',
      sceneSummary:'',
      visualStyle:'',
      characters:[],
      environment:AiSceneEnvironment(location:'',time:'',description:''),
      props:[],
      actions:[],
      camera:AiSceneCamera(shot:'',angle:'',movement:''),
      lighting:'',
      motion:'',
      imagePrompt:'',
    );
    final graph=SuperBookSceneGraph.from(
      plan:effectivePlan,
      scene:scene,
      bookCharacters:characters,
      passage:passage,
      narrativeFocus:narrativeFocus,
    );
    return SceneStageScript.fromGraph(
      graph:graph,
      bookCharacters:characters,
      scene:scene,
      passage:passage,
    );
  }
  @override Widget build(BuildContext context)=>SuperBookStageCompositor(script:_script(),characters:characters,passage:passage);
}