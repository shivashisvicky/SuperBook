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
    String narrativeFocus = '',
  }) {
    // Literary prose is authoritative for physical setting. AI supplies a
    // fallback only when the supplied prose contains no usable setting evidence.
    final literarySource = [
      ...passage,
      scene.title,
      scene.moment,
      narrativeFocus,
    ].join(' ').toLowerCase();

    final aiSource = [
      plan.environment.location,
      plan.environment.description,
      plan.sceneSummary,
      ...plan.actions,
      ...plan.characters.map((c) => '${c.id} ${c.action} ${c.position}'),
    ].join(' ').toLowerCase();

    final literaryHasSetting = _hasAny(literarySource, [
      'room', 'house', 'hall', 'dining', 'library', 'parlor', 'parlour',
      'bedroom', 'office', 'inside', 'interior', 'chamber', 'kitchen',
      'fireplace', 'hearth', 'garden', 'forest', 'woods', 'woodland',
      'field', 'meadow', 'street', 'road', 'sea', 'ocean', 'shore',
      'harbour', 'harbor', 'outdoors', 'outside', 'courtyard', 'path',
      'station', 'battlefield', 'battle', 'ship', 'deck',
    ]);
    final physicalSource = literaryHasSetting
        ? literarySource
        : '$literarySource $aiSource';

    final explicitIndoor = _hasAny(physicalSource, [
      'room', 'house', 'hall', 'dining', 'library', 'parlor', 'parlour',
      'bedroom', 'office', 'inside', 'interior', 'chamber', 'kitchen',
      'fireplace', 'hearth',
    ]);
    final explicitOutdoor = _hasAny(physicalSource, [
      'garden', 'forest', 'woods', 'woodland', 'field', 'meadow', 'street',
      'road', 'sea', 'ocean', 'shore', 'harbour', 'harbor', 'outdoors',
      'outside', 'courtyard', 'path', 'station', 'battlefield', 'battle',
      'ship', 'deck',
    ]);
    final indoors = explicitIndoor && !explicitOutdoor;

    final hasWindow = _hasAny(physicalSource, ['window']) &&
        _hasAny(physicalSource, [
          'look', 'looked', 'see', 'saw', 'watch', 'outside', 'through',
          'open', 'opened', 'view',
        ]);
    final hasDoor = _hasAny(physicalSource, [
      'doorway', 'threshold', 'open door', 'opened the door',
      'through the door', 'at the door', 'enter', 'entered', 'entering',
      'exit', 'exited', 'door',
    ]);
    final hasTable = _hasAny(physicalSource, ['table', 'desk']) &&
        _hasAny(physicalSource, [
          'sit', 'sat', 'sitting', 'seated', 'dinner', 'eat', 'ate',
          'write', 'wrote', 'map', 'key', 'desk', 'table',
        ]);
    final hasCarriage = _hasAny(physicalSource, [
      'carriage', 'coach', 'wagon', 'horse',
    ]);

    // A prop only becomes renderable when the literary source actually
    // establishes it. The AI prop list cannot ground itself.
    final groundedProps = plan.props
        .where((prop) => _isGroundedProp(prop, literarySource))
        .take(3)
        .toList();

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
    final explicitSolo = _hasAny(literarySource, [
      'alone', 'by himself', 'by herself', 'on his own', 'on her own',
      'single figure', 'solitary',
    ]);
    final planned = plan.characters.take(explicitSolo ? 1 : 2).toList();
    if (planned.isEmpty) {
      for (final c in bookCharacters.take(explicitSolo ? 1 : 2)) {
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
      environment: _environmentLabel(physicalSource, indoors),
      anchors: anchors,
      actors: actors,
      props: groundedProps.isNotEmpty
          ? groundedProps
          : (hasCarriage ? const ['carriage'] : const []),
      timeline: timeline,
    );
  }

  static bool _hasAny(String text, List<String> terms) {
    final normalized = ' ${text
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')} ';
    return terms.any((term) {
      final normalizedTerm =
          term.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
      return normalized.contains(' $normalizedTerm ');
    });
  }

  static bool _isGroundedProp(String prop, String source) {
    final words = prop
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.length >= 4)
        .toList();
    return words.isNotEmpty && words.every((word) => _hasAny(source, [word]));
  }

  static String _environmentLabel(String source, bool indoors) {
    if (indoors) {
      if (_hasAny(source, ['library', 'study'])) { return 'Library or study'; }
      if (_hasAny(source, ['bedroom'])) { return 'Bedroom'; }
      if (_hasAny(source, ['dining', 'dinner'])) { return 'Dining room'; }
      if (_hasAny(source, ['drawing room', 'drawing-room', 'parlor', 'parlour'])) {
        return 'Drawing room';
      }
      if (_hasAny(source, ['fireplace', 'hearth'])) { return 'Fireplace interior'; }
      return 'Interior';
    }
    if (_hasAny(source, ['forest', 'woods', 'woodland', 'trees'])) { return 'Forest or woodland'; }
    if (_hasAny(source, ['garden', 'meadow', 'field', 'park', 'courtyard'])) { return 'Garden or open grounds'; }
    if (_hasAny(source, ['sea', 'ocean', 'ship', 'shore', 'harbour', 'harbor', 'deck'])) { return 'At sea'; }
    if (_hasAny(source, ['street', 'road', 'market', 'town', 'city', 'station'])) { return 'Street or public place'; }
    if (_hasAny(source, ['battle', 'battlefield', 'army', 'soldier', 'enemy', 'cannon'])) { return 'Battlefield'; }
    if (_hasAny(source, ['carriage', 'coach', 'wagon', 'horse'])) { return 'Road or carriage setting'; }
    return 'Outdoor setting';
  }

  static String _slug(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  static String _anchorFor(String value, int index) {
    final t = value.toLowerCase();
    if (_hasAny(t, ['window'])) { return 'window'; }
    if (_hasAny(t, ['table', 'desk', 'chair'])) { return 'table'; }
    if (_hasAny(t, ['door', 'doorway', 'threshold'])) { return 'door'; }
    if (_hasAny(t, ['right'])) { return 'right'; }
    if (_hasAny(t, ['left'])) { return 'left'; }
    return index == 0 ? 'left' : 'right';
  }

  static SceneActor _actorFor(String text, List<SceneActor> actors, int index) {
    final t = text.toLowerCase();
    for (final actor in actors) {
      if (_hasAny(t, [actor.id.replaceAll('_', ' '), actor.name])) { return actor; }
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
      if (anchors.containsKey(key) && t.contains(key.replaceAll('_', ' '))) { return key; }
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
    if (_hasAny(t, ['carriage', 'coach', 'wagon', 'horse arrives'])) { return 'carriage'; }
    if (_hasAny(t, [
      'walk', 'walked', 'walking', 'approach', 'approached', 'enter', 'entered',
      'leave', 'left', 'leaving', 'move', 'moved', 'go', 'went', 'cross', 'crossed',
      'run', 'ran', 'running', 'rush', 'rushed', 'flee', 'fled',
    ])) { return 'walk'; }
    if (_hasAny(t, ['stand', 'stood', 'rise', 'rose', 'get up', 'got up'])) { return 'stand'; }
    if (_hasAny(t, [
      'reach', 'reached', 'open', 'opened', 'take', 'took', 'pick up', 'picked up',
      'hold', 'held', 'write', 'wrote',
    ])) { return 'reach'; }
    if (_hasAny(t, ['fight', 'fought', 'fighting', 'strike', 'struck', 'duel', 'attack', 'attacked'])) { return 'fight'; }
    if (_hasAny(t, ['sit', 'sits', 'sat', 'sitting', 'seated'])) { return 'sit'; }
    if (_hasAny(t, ['read', 'reads', 'reading', 'letter', 'book'])) { return 'read'; }
    if (_hasAny(t, [
      'turn', 'turned', 'look', 'looked', 'watch', 'watched', 'notice', 'noticed',
      'see', 'saw', 'hear', 'heard', 'listen', 'listened',
    ])) { return 'look'; }
    if (_hasAny(t, [
      'say', 'said', 'speak', 'spoke', 'talk', 'talked', 'ask', 'asked',
      'reply', 'replied', 'answer', 'answered',
    ])) { return 'talk'; }
    return 'look';
  }
}
