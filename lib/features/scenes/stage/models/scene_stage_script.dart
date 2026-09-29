// ignore_for_file: curly_braces_in_flow_control_structures, prefer_function_declarations_over_variables, prefer_interpolation_to_compose_strings

import '../../../../domain/book.dart';
import '../../../../domain/experience/superbook_scene_graph.dart';

enum EnvironmentBiome {
  forestWoodland,
  gardenMeadow,
  streetStation,
  seaHarbor,
  battlefield,
  roadCarriage,
  drawingParlor,
  libraryStudy,
  hearthStudy,
  diningHall,
  bedchamber,
  corridorHall,
  neutral,
}
enum LightingMood { dawn, daylight, overcastRain, dusk, nightMoon, warmHearth, candlelight }
enum ActorPose { idleStand, walk, run, sitIdle, sitRead, sitWrite, talkGesture, listenAttentive, lookWindow, reachObject, combatSlash, boardCarriage }

class StageSetPiece { const StageSetPiece({required this.id,required this.x,required this.y,required this.depth,this.scale=1}); final String id; final double x,y,depth,scale; }
class CharacterPuppetSpec { const CharacterPuppetSpec({required this.id,required this.name,required this.description,required this.x,required this.y,required this.facing}); final String id,name,description; final double x,y,facing; }
class ActorTrack { const ActorTrack({required this.actorId,required this.pose,this.startX,this.targetX,this.targetY,this.facing}); final String actorId; final ActorPose pose; final double? startX,targetX,targetY,facing; }
class ChoreographedBeat { const ChoreographedBeat({required this.text,required this.durationMs,required this.tracks}); final String text; final int durationMs; final List<ActorTrack> tracks; }

class SceneStageScript {
  const SceneStageScript({required this.biome,required this.lighting,required this.setPieces,required this.cast,required this.beats});
  final EnvironmentBiome biome; final LightingMood lighting; final List<StageSetPiece> setPieces; final List<CharacterPuppetSpec> cast; final List<ChoreographedBeat> beats;

  factory SceneStageScript.fromGraph({required SuperBookSceneGraph graph,required List<BookCharacter> bookCharacters,required Scene scene,required List<String> passage}) {
    final biome=_biome(graph.environment);
    final pieces=<StageSetPiece>[];
    final Set<EnvironmentBiome> outdoorBiomes = {
      EnvironmentBiome.forestWoodland,
      EnvironmentBiome.gardenMeadow,
      EnvironmentBiome.streetStation,
      EnvironmentBiome.seaHarbor,
      EnvironmentBiome.battlefield,
      EnvironmentBiome.roadCarriage,
    };
    final isOutdoorBiome = outdoorBiomes.contains(biome);
    for(final e in graph.anchors.entries){
      if({'left','right','center','outside','outside_window'}.contains(e.key)) continue;
      if(isOutdoorBiome && {'window','door','table'}.contains(e.key)) continue;
      pieces.add(StageSetPiece(id:e.key,x:e.value.x,y:e.value.y,depth:e.value.depth));
    }
    for(final prop in graph.props){
      final id=prop.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'),'_');
      if(isOutdoorBiome && {'window','outside_window','door','table'}.contains(id)) continue;
      if(!pieces.any((p)=>p.id==id)) pieces.add(StageSetPiece(id:id,x:.5,y:.62,depth:.18));
    }
    pieces.addAll(_environmentPieces(biome,pieces));
    final cast=<CharacterPuppetSpec>[];
    for(var i=0;i<graph.actors.length;i++){
      final a=graph.actors[i];
      final an=graph.anchors[a.startAnchor]??graph.anchors['center']!;
      final matches=bookCharacters.where((c)=>c.name.toLowerCase()==a.name.toLowerCase());
      final desc=[...matches.map((c)=>c.description),a.description].where((s)=>s.trim().isNotEmpty).join(' ');
      var x=an.x;
      if(cast.isNotEmpty && (x-cast.last.x).abs()<.26){
        x=cast.last.x<.5 ? (cast.last.x+.26).clamp(.14,.86).toDouble() : (cast.last.x-.26).clamp(.14,.86).toDouble();
      }
      cast.add(CharacterPuppetSpec(id:a.id,name:a.name,description:desc,x:x,y:.78,facing:i==0?1:-1));
    }
    final beats=<ChoreographedBeat>[];
    final currentX=<String,double>{for(final a in cast)a.id:a.x};
    for(final b in graph.timeline){
      final tracks=<ActorTrack>[];
      for(final a in cast){
        final active=a.id==b.actorId;
        final target=b.targetAnchor==null?null:graph.anchors[b.targetAnchor!];
        final pose=_pose(b.action,b.text,active);
        final sx=currentX[a.id]!;
        double? tx;
        if(active && {ActorPose.walk,ActorPose.run}.contains(pose)){
          final candidateX = target?.x ?? (sx < .5 ? .64 : .36);
          tx = candidateX;
          for(final other in cast){
            if(other.id==a.id) continue;
            final otherX=currentX[other.id]!;
            if((candidateX-otherX).abs()<.24){
              tx=sx<otherX
                  ? (otherX-.24).clamp(.16,.84).toDouble()
                  : (otherX+.24).clamp(.16,.84).toDouble();
            }
          }
        } else if(active){
          tx=target?.x;
        }
        tracks.add(ActorTrack(
          actorId:a.id,
          pose:pose,
          startX:sx,
          targetX:tx,
          targetY:active && tx!=null ? .78 : null,
          facing:active&&tx!=null?(tx>sx?1:-1):a.facing,
        ));
        if(tx!=null) currentX[a.id]=tx;
      }
      beats.add(ChoreographedBeat(text:b.text,durationMs:b.duration.inMilliseconds.clamp(2200,5200).toInt(),tracks:tracks));
    }
    for(final a in cast){
      final seated=beats.any((b)=>b.tracks.any((t)=>t.actorId==a.id && {ActorPose.sitIdle,ActorPose.sitRead,ActorPose.sitWrite}.contains(t.pose)));
      if(!isOutdoorBiome && seated && !pieces.any((p)=>p.id.contains('chair') && (p.x-a.x).abs()<.12)){
        pieces.add(StageSetPiece(id:'chair_'+a.id,x:a.x,y:.73,depth:.12));
      }
    }
    if(beats.isEmpty&&cast.isNotEmpty) beats.add(ChoreographedBeat(text:scene.moment,durationMs:3200,tracks:cast.map((a)=>ActorTrack(actorId:a.id,pose:ActorPose.idleStand,startX:a.x)).toList()));
    return SceneStageScript(biome:biome,lighting:_lighting(scene,passage),setPieces:pieces,cast:cast,beats:beats);
  }

  static List<StageSetPiece> _environmentPieces(EnvironmentBiome b,List<StageSetPiece> existing){
    final ids=existing.map((p)=>p.id).toSet();
    StageSetPiece add(String id,double x,double y,double d,[double scale=1])=>StageSetPiece(id:id,x:x,y:y,depth:d,scale:scale);
    final out=<StageSetPiece>[];
    void maybe(String id,double x,double y,double d,[double scale=1]){if(!ids.contains(id))out.add(add(id,x,y,d,scale));}
    switch(b){
      case EnvironmentBiome.drawingParlor:
        maybe('armchair_left',.22,.67,.30,1.15);
        maybe('armchair_right',.78,.67,.30,1.15);
        if(ids.contains('window')) maybe('window',.78,.35,.05,1.25);
        if(ids.contains('table')) maybe('table',.52,.64,.20,1.0);
        if(ids.contains('door')) maybe('door',.10,.54,.10,1.15);
        break;
      case EnvironmentBiome.libraryStudy: maybe('bookcase_left',.14,.48,.05,1.5); maybe('bookcase_right',.86,.48,.05,1.5); maybe('desk',.53,.62,.18,1.05); maybe('chair',.53,.73,.28,1.0); break;
      case EnvironmentBiome.hearthStudy: maybe('fireplace',.18,.53,.04,1.35); maybe('desk',.67,.62,.18,1.0); maybe('chair',.67,.73,.28,1.0); break;
      case EnvironmentBiome.diningHall: maybe('table',.50,.62,.18,1.5); maybe('chair_left',.30,.72,.28,1.0); maybe('chair_right',.70,.72,.28,1.0); maybe('window',.82,.34,.04,1.1); break;
      case EnvironmentBiome.bedchamber: maybe('bed',.68,.58,.16,1.35); maybe('bedside_table',.48,.65,.20,.85); maybe('window',.18,.34,.04,1.1); break;
      case EnvironmentBiome.corridorHall: maybe('door_left',.15,.55,.08,1.1); maybe('door_right',.85,.55,.08,1.1); maybe('window',.50,.30,.03,1.0); break;
      case EnvironmentBiome.forestWoodland: maybe('tree_left',.12,.57,.02,1.5); maybe('tree_mid',.78,.55,.04,1.35); maybe('tree_far',.92,.48,.70,1.0); break;
      case EnvironmentBiome.gardenMeadow: maybe('tree_left',.12,.57,.02,1.25); maybe('tree_right',.88,.57,.04,1.25); maybe('bench',.72,.67,.22,1.0); break;
      case EnvironmentBiome.streetStation: maybe('building_left',.14,.48,.04,1.4); maybe('lamp',.82,.49,.08,1.0); maybe('bench',.70,.68,.25,1.0); break;
      case EnvironmentBiome.seaHarbor: maybe('pier',.56,.67,.20,1.5); maybe('boat',.78,.57,.45,1.15); break;
      case EnvironmentBiome.battlefield: maybe('rock_left',.16,.67,.12,1.2); maybe('flag',.82,.48,.05,1.2); break;
      case EnvironmentBiome.roadCarriage: maybe('carriage',.73,.68,.22,1.15); maybe('tree_left',.12,.57,.04,1.25); maybe('tree_right',.88,.57,.06,1.1); break;
      case EnvironmentBiome.neutral: break;
    }
    return out;
  }

  static ActorPose _pose(String action,String text,bool active){
    if(!active)return ActorPose.listenAttentive;
    switch(action){
      case 'walk':return ActorPose.walk;
      case 'fight':return ActorPose.combatSlash;
      case 'sit':return _has(text,['read','book','letter'])?ActorPose.sitRead:ActorPose.sitIdle;
      case 'read':return ActorPose.sitRead;
      case 'reach':return ActorPose.reachObject;
      case 'talk':return ActorPose.talkGesture;
      case 'stand':return ActorPose.idleStand;
      case 'carriage':return ActorPose.boardCarriage;
      default:return _has(text,['window','outside'])?ActorPose.lookWindow:ActorPose.listenAttentive;
    }
  }
  static EnvironmentBiome _biome(String v){
    final t=v.toLowerCase();
    if(t.contains('forest')||t.contains('woodland'))return EnvironmentBiome.forestWoodland;
    if(t.contains('garden')||t.contains('grounds'))return EnvironmentBiome.gardenMeadow;
    if(t.contains('street')||t.contains('public'))return EnvironmentBiome.streetStation;
    if(t.contains('sea'))return EnvironmentBiome.seaHarbor;
    if(t.contains('battle'))return EnvironmentBiome.battlefield;
    if(t.contains('carriage')||t.contains('road'))return EnvironmentBiome.roadCarriage;
    if(t.contains('drawing'))return EnvironmentBiome.drawingParlor;
    if(t.contains('library')||t.contains('study'))return EnvironmentBiome.libraryStudy;
    if(t.contains('fireplace')||t.contains('hearth'))return EnvironmentBiome.hearthStudy;
    if(t.contains('dining'))return EnvironmentBiome.diningHall;
    if(t.contains('bedroom'))return EnvironmentBiome.bedchamber;
    if(t.contains('hall')||t.contains('corridor'))return EnvironmentBiome.corridorHall;
    return EnvironmentBiome.neutral;
  }
  static LightingMood _lighting(Scene s,List<String> p){
    final t='${s.atmosphere} ${s.moment} ${p.join(' ')}';
    if(_has(t,['rain','storm','wet']))return LightingMood.overcastRain;
    if(_has(t,['night','moon','midnight']))return LightingMood.nightMoon;
    if(_has(t,['fireplace','hearth','fire']))return LightingMood.warmHearth;
    if(_has(t,['candle','lamp']))return LightingMood.candlelight;
    if(_has(t,['dusk','evening','sunset']))return LightingMood.dusk;
    if(_has(t,['dawn','morning']))return LightingMood.dawn;
    return LightingMood.daylight;
  }
  static bool _has(String t,List<String> terms){
    final n=' ${t.replaceAll(RegExp(r'[^a-z0-9]+'), ' ')} ';
    return terms.any((x)=>n.contains(' $x '));
  }
}