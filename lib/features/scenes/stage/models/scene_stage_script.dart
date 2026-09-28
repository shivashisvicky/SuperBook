import '../../../../domain/book.dart';
import '../../../../domain/experience/superbook_scene_graph.dart';

enum EnvironmentBiome { forestWoodland, gardenMeadow, streetStation, seaHarbor, battlefield, roadCarriage, drawingParlor, libraryStudy, hearthStudy, diningHall, bedchamber, corridorHall, neutral }
enum LightingMood { dawn, daylight, overcastRain, dusk, nightMoon, warmHearth, candlelight }
enum ActorPose { idleStand, walk, run, sitIdle, sitRead, sitWrite, talkGesture, listenAttentive, lookWindow, reachObject, combatSlash, boardCarriage }

class StageSetPiece { const StageSetPiece({required this.id,required this.x,required this.y,required this.depth,this.scale=1}); final String id; final double x,y,depth,scale; }
class CharacterPuppetSpec { const CharacterPuppetSpec({required this.id,required this.name,required this.description,required this.x,required this.y,required this.facing}); final String id,name,description; final double x,y,facing; }
class ActorTrack { const ActorTrack({required this.actorId,required this.pose,this.targetX,this.targetY,this.facing}); final String actorId; final ActorPose pose; final double? targetX,targetY,facing; }
class ChoreographedBeat { const ChoreographedBeat({required this.text,required this.durationMs,required this.tracks}); final String text; final int durationMs; final List<ActorTrack> tracks; }

class SceneStageScript {
  const SceneStageScript({required this.biome,required this.lighting,required this.setPieces,required this.cast,required this.beats});
  final EnvironmentBiome biome; final LightingMood lighting; final List<StageSetPiece> setPieces; final List<CharacterPuppetSpec> cast; final List<ChoreographedBeat> beats;

  factory SceneStageScript.fromGraph({required SuperBookSceneGraph graph,required List<BookCharacter> bookCharacters,required Scene scene,required List<String> passage}) {
    final pieces=<StageSetPiece>[];
    for(final e in graph.anchors.entries){ if({'left','right','center','outside'}.contains(e.key)) continue; pieces.add(StageSetPiece(id:e.key,x:e.value.x,y:e.value.y,depth:e.value.depth)); }
    for(final prop in graph.props){ final id=prop.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'),'_'); if(!pieces.any((p)=>p.id==id)) pieces.add(StageSetPiece(id:id,x:.5,y:.62,depth:.18)); }
    final cast=<CharacterPuppetSpec>[];
    for(var i=0;i<graph.actors.length;i++){ final a=graph.actors[i]; final an=graph.anchors[a.startAnchor]??graph.anchors['center']!; final matches=bookCharacters.where((c)=>c.name.toLowerCase()==a.name.toLowerCase()); final desc=[...matches.map((c)=>c.description),a.description].where((s)=>s.trim().isNotEmpty).join(' '); cast.add(CharacterPuppetSpec(id:a.id,name:a.name,description:desc,x:an.x,y:an.y,facing:i==0?1:-1)); }
    final beats=<ChoreographedBeat>[];
    for(final b in graph.timeline){ final tracks=<ActorTrack>[]; for(final a in cast){ final active=a.id==b.actorId; final target=b.targetAnchor==null?null:graph.anchors[b.targetAnchor!]; tracks.add(ActorTrack(actorId:a.id,pose:_pose(b.action,b.text,active),targetX:active?target?.x:null,targetY:active?target?.y:null,facing:active&&target!=null?(target.x>a.x?1:-1):a.facing)); } beats.add(ChoreographedBeat(text:b.text,durationMs:b.duration.inMilliseconds,tracks:tracks)); }
    if(beats.isEmpty&&cast.isNotEmpty) beats.add(ChoreographedBeat(text:scene.moment,durationMs:3200,tracks:cast.map((a)=>ActorTrack(actorId:a.id,pose:ActorPose.idleStand)).toList()));
    return SceneStageScript(biome:_biome(graph.environment),lighting:_lighting(scene,passage),setPieces:pieces,cast:cast,beats:beats);
  }

  static ActorPose _pose(String action,String text,bool active){
    if(!active)return ActorPose.listenAttentive;
    switch(action){case 'walk':return ActorPose.walk;case 'fight':return ActorPose.combatSlash;case 'sit':return _has(text,['read','book','letter'])?ActorPose.sitRead:ActorPose.sitIdle;case 'read':return ActorPose.sitRead;case 'reach':return ActorPose.reachObject;case 'talk':return ActorPose.talkGesture;case 'stand':return ActorPose.idleStand;case 'carriage':return ActorPose.boardCarriage;default:return _has(text,['window','outside'])?ActorPose.lookWindow:ActorPose.listenAttentive;}
  }
  static EnvironmentBiome _biome(String v){final t=v.toLowerCase();if(t.contains('forest')||t.contains('woodland'))return EnvironmentBiome.forestWoodland;if(t.contains('garden')||t.contains('grounds'))return EnvironmentBiome.gardenMeadow;if(t.contains('street')||t.contains('public'))return EnvironmentBiome.streetStation;if(t.contains('sea'))return EnvironmentBiome.seaHarbor;if(t.contains('battle'))return EnvironmentBiome.battlefield;if(t.contains('carriage')||t.contains('road'))return EnvironmentBiome.roadCarriage;if(t.contains('drawing'))return EnvironmentBiome.drawingParlor;if(t.contains('library')||t.contains('study'))return EnvironmentBiome.libraryStudy;if(t.contains('fireplace')||t.contains('hearth'))return EnvironmentBiome.hearthStudy;if(t.contains('dining'))return EnvironmentBiome.diningHall;if(t.contains('bedroom'))return EnvironmentBiome.bedchamber;if(t.contains('hall')||t.contains('corridor'))return EnvironmentBiome.corridorHall;return EnvironmentBiome.neutral;}
  static LightingMood _lighting(Scene s,List<String> p){final t='\${s.atmosphere} \${s.moment} \${p.join(' ')}'.toLowerCase();if(_has(t,['rain','storm','wet']))return LightingMood.overcastRain;if(_has(t,['night','moon','midnight']))return LightingMood.nightMoon;if(_has(t,['fireplace','hearth','fire']))return LightingMood.warmHearth;if(_has(t,['candle','lamp']))return LightingMood.candlelight;if(_has(t,['dusk','evening','sunset']))return LightingMood.dusk;if(_has(t,['dawn','morning']))return LightingMood.dawn;return LightingMood.daylight;}
  static bool _has(String t,List<String> terms){final n=' \${t.replaceAll(RegExp(r'[^a-z0-9]+'),' ')} ';return terms.any((x)=>n.contains(' \$x '));}
}