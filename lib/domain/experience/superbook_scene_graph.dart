import '../../domain/book.dart';
import '../../domain/experience/ai_scene_plan.dart';

class SceneAnchor {
  const SceneAnchor(this.id, this.x, this.y, {this.depth = 0});
  final String id;
  final double x;
  final double y;
  final double depth;
}

class SceneActionBeat {
  const SceneActionBeat({
    required this.text,
    required this.action,
    required this.actorId,
    this.targetAnchor,
    required this.duration,
  });
  final String text;
  final String action;
  final String actorId;
  final String? targetAnchor;
  final Duration duration;
}

class SceneActor {
  const SceneActor({
    required this.id,
    required this.name,
    required this.description,
    required this.startAnchor,
  });
  final String id;
  final String name;
  final String description;
  final String startAnchor;
}

class SuperBookSceneGraph {
  const SuperBookSceneGraph({
    required this.environment,
    required this.anchors,
    required this.actors,
    required this.props,
    required this.timeline,
  });

  final String environment;
  final Map<String, SceneAnchor> anchors;
  final List<SceneActor> actors;
  final List<String> props;
  final List<SceneActionBeat> timeline;

  static SuperBookSceneGraph from({
    required AiScenePlan plan,
    required Scene scene,
    required List<BookCharacter> bookCharacters,
    required List<String> passage,
  }) {
    final source = [
      plan.environment.location,
      plan.environment.description,
      scene.title,
      scene.moment,
      scene.atmosphere,
      ...passage,
      ...plan.actions,
      ...plan.characters.map((c) => '${c.id} ${c.action} ${c.position}'),
      ...plan.props,
    ].join(' ').toLowerCase();

    final indoors = _hasAny(source, [
      'room', 'house', 'hall', 'dining', 'library', 'parlor', 'parlour',
      'bedroom', 'office', 'inside', 'interior',
    ]);
    final hasWindow = source.contains('window');
    final hasDoor = _hasAny(source, ['door', 'entrance', 'threshold']);
    final hasTable = _hasAny(source, ['table', 'dining', 'desk']);
    final hasCarriage = _hasAny(source, ['carriage', 'coach', 'wagon', 'horse']);

    final anchors = <String, SceneAnchor>{
      'center': const SceneAnchor('center', .50, .68),
      'left': const SceneAnchor('left', .27, .68),
      'right': const SceneAnchor('right', .73, .68),
      if (hasTable) 'table': const SceneAnchor('table', .50, .60),
      if (hasWindow) 'window': const SceneAnchor('window', .78, .38, depth: .15),
      if (hasWindow) 'outside_window': const SceneAnchor('outside_window', .88, .44, depth: .65),
      if (hasDoor) 'door': const SceneAnchor('door', .14, .52),
      'outside': const SceneAnchor('outside', .92, .62, depth: .75),
    };

    final actors = <SceneActor>[];
    final planned = plan.characters.take(2).toList();
    if (planned.isEmpty) {
      for (final c in bookCharacters.take(2)) {
        actors.add(SceneActor(
          id: _slug(c.name),
          name: c.name,
          description: c.description,
          startAnchor: actors.isEmpty ? 'left' : 'right',
        ));
      }
    } else {
      for (var i = 0; i < planned.length; i++) {
        final c = planned[i];
        actors.add(SceneActor(
          id: _slug(c.id.isEmpty ? c.description : c.id),
          name: c.id.isEmpty ? (i < bookCharacters.length ? bookCharacters[i].name : 'Character ${i + 1}') : c.id,
          description: c.description,
          startAnchor: _anchorFor(c.position, i),
        ));
      }
    }
    if (actors.isEmpty) {
      actors.add(const SceneActor(
        id: 'protagonist',
        name: 'Protagonist',
        description: '',
        startAnchor: 'center',
      ));
    }

    final timeline = <SceneActionBeat>[];
    final plannedActions = <String>[
      ...plan.actions,
      ...plan.characters.map((c) => '${c.id}: ${c.action}'),
    ].where((a) => a.trim().isNotEmpty).take(6).toList();

    // Production scenes must be driven by the actual AI plan. The old
    // animation-lab canary was intentionally removed from the reader path:
    // otherwise any passage mentioning a carriage/window/standing/walking
    // could collapse into the same five-beat demonstration.
    for (var i = 0; i < plannedActions.length; i++) {
      final text = plannedActions[i];
      final action = _normalizeAction(text);
      final actor = _actorFor(text, actors, i);
      timeline.add(SceneActionBeat(
        text: text,
        action: action,
        actorId: actor.id,
        targetAnchor: _targetFor(text, anchors),
        duration: _durationFor(action),
      ));
    }

    if (timeline.isEmpty) {
      timeline.add(SceneActionBeat(
        text: scene.moment,
        action: _normalizeAction('${scene.moment} ${plan.motion}'),
        actorId: actors.first.id,
        targetAnchor: _targetFor(scene.moment, anchors),
        duration: const Duration(milliseconds: 2600),
      ));
    }

    return SuperBookSceneGraph(
      environment: plan.environment.location.trim().isNotEmpty
          ? plan.environment.location.trim()
          : (indoors ? 'Interior' : 'Exterior'),
      anchors: anchors,
      actors: actors,
      props: plan.props.isNotEmpty
          ? plan.props.take(3).toList()
          : (hasCarriage ? const ['carriage'] : const []),
      timeline: timeline,
    );
  }

  static bool _hasAny(String text, List<String> terms) =>
      terms.any((term) => text.contains(term));

  static String _slug(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  static String _anchorFor(String value, int index) {
    final t = value.toLowerCase();
    if (t.contains('window')) return 'window';
    if (t.contains('table') || t.contains('desk') || t.contains('chair')) return 'table';
    if (t.contains('door')) return 'door';
    if (t.contains('right')) return 'right';
    if (t.contains('left')) return 'left';
    return index == 0 ? 'left' : 'right';
  }

  static SceneActor _actorFor(String text, List<SceneActor> actors, int index) {
    final t = text.toLowerCase();
    for (final actor in actors) {
      if (t.contains(actor.id.replaceAll('_', ' ')) || t.contains(actor.name.toLowerCase())) return actor;
    }
    return actors[index % actors.length];
  }

  static String? _targetFor(String text, Map<String, SceneAnchor> anchors) {
    final t = text.toLowerCase();

    // "reach and look outside" means the character is interacting with the
    // exterior through the window, not walking to the generic outside anchor.
    if (anchors.containsKey('outside_window') &&
        t.contains('outside') &&
        _hasAny(t, ['look', 'turn', 'reach'])) {
      return 'outside_window';
    }

    for (final key in ['outside_window', 'window', 'table', 'door', 'outside']) {
      if (anchors.containsKey(key) && t.contains(key.replaceAll('_', ' '))) return key;
    }
    if (anchors.containsKey('window') && _hasAny(t, ['look', 'turn', 'reach'])) {
      return 'window';
    }
    return null;
  }

  static Duration _durationFor(String action) {
    switch (action) {
      case 'walk':
        return const Duration(milliseconds: 4200);
      case 'carriage':
        return const Duration(milliseconds: 4500);
      case 'reach':
        return const Duration(milliseconds: 3200);
      case 'stand':
        return const Duration(milliseconds: 2800);
      case 'talk':
        return const Duration(milliseconds: 3600);
      case 'look':
        return const Duration(milliseconds: 3000);
      case 'sit':
        return const Duration(milliseconds: 2800);
      default:
        return const Duration(milliseconds: 3000);
    }
  }

  static String _normalizeAction(String value) {
    final t = value.toLowerCase();
    if (_hasAny(t, ['carriage', 'coach', 'wagon', 'horse arrives'])) return 'carriage';
    if (_hasAny(t, ['walk', 'approach', 'enter', 'leave', 'move to', 'go to', 'cross'])) return 'walk';
    if (_hasAny(t, ['stand', 'rise', 'get up'])) return 'stand';
    if (_hasAny(t, ['reach', 'open', 'take', 'pick up', 'hold'])) return 'reach';
    if (_hasAny(t, ['turn', 'look', 'watch', 'notice', 'see', 'hear', 'listen'])) return 'look';
    if (_hasAny(t, ['sit', 'sitting'])) return 'sit';
    if (_hasAny(t, ['say', 'speak', 'talk', 'ask', 'reply'])) return 'talk';
    return 'look';
  }
}
