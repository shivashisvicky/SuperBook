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

    // The book passage is authoritative. AI may describe how to stage a
    // moment, but it must never manufacture the physical location.
    final physicalSource = literarySource;

    final indoorTerms = [
      'room', 'house', 'hall', 'dining', 'library', 'parlor', 'parlour',
      'bedroom', 'office', 'inside', 'interior', 'chamber', 'kitchen',
      'fireplace', 'hearth',
    ];
    final specificOutdoorTerms = [
      'forest', 'woods', 'woodland', 'trees', 'garden', 'meadow', 'field',
      'street', 'road', 'sea', 'ocean', 'shore', 'harbour', 'harbor',
      'beach', 'battlefield', 'station', 'courtyard', 'carriage', 'coach',
      'wagon', 'ship', 'deck',
    ];
    final explicitIndoor = _hasAny(physicalSource, indoorTerms);
    final explicitOutdoor = _hasAny(physicalSource, [
      ...specificOutdoorTerms,
      'outdoors', 'outside', 'path', 'battle',
    ]);
    // Resolve the immediate beat before falling back to the wider passage.
    // Words such as "outside" are incidental unless a concrete outdoor
    // location is actually named.
    final immediateSource = [
      scene.title,
      scene.moment,
      narrativeFocus,
      ...passage.take(2),
    ].join(' ');
    final immediateOutdoorTerms = [
      ...specificOutdoorTerms,
      'park', 'ramble', 'walk', 'walks', 'outside', 'outdoors', 'path', 'battle',
    ];
    final immediateIndoorTerms = [
      ...indoorTerms,
      'sitting', 'sat', 'writing', 'wrote', 'read', 'reading', 'letter',
      'dine', 'dinner', 'drawing room', 'parlor',
    ];
    final immediateIndoor = _hasAny(immediateSource, immediateIndoorTerms);
    final immediateOutdoor = _hasAny(immediateSource, immediateOutdoorTerms);
    final indoors = immediateIndoor
        ? true
        : immediateOutdoor
            ? false
            : explicitIndoor && !explicitOutdoor;

    final hasWindow = indoors && _hasAny(physicalSource, ['window']);
    final hasDoor = indoors && _hasAny(physicalSource, [
      'doorway', 'threshold', 'open door', 'opened the door',
      'through the door', 'at the door', 'door',
    ]);
    final hasTable = indoors &&
        _hasAny(physicalSource, ['table', 'desk']) &&
        _hasAny(physicalSource, [
          'sit', 'sat', 'sitting', 'seated', 'dinner', 'eat', 'ate',
          'write', 'wrote', 'map', 'key',
        ]);
    final hasCarriage = !indoors && _hasAny(physicalSource, [
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
    final actorLimit = explicitSolo ? 1 : 2;
    final planned = plan.characters.take(actorLimit).toList();
    if (planned.isEmpty) {
      final selected = <BookCharacter>[
        ..._orderedCharacterMentions(bookCharacters, immediateSource),
      ];
      final broader = _orderedCharacterMentions(bookCharacters, literarySource);
      for (final character in broader) {
        if (!selected.any((item) => item.name.toLowerCase() == character.name.toLowerCase())) {
          selected.add(character);
        }
      }
      for (final character in selected.take(actorLimit)) {
        actors.add(SceneActor(
          id: _slug(character.name),
          name: character.name,
          description: _genderedCharacterDescription(character, immediateSource),
          startAnchor: actors.isEmpty ? 'left' : 'right',
        ));
      }
      if (actors.length < actorLimit) {
        actors.addAll(_inferImmediateActors(
          immediateSource,
          limit: actorLimit - actors.length,
          startIndex: actors.length,
        ));
      }
    } else {
      for (var i = 0; i < planned.length; i++) {
        final character = planned[i];
        actors.add(SceneActor(
          id: _slug(character.id.isEmpty ? character.description : character.id),
          name: character.id.isEmpty
              ? (i < bookCharacters.length ? bookCharacters[i].name : 'Character ${i + 1}')
              : character.id,
          description: character.description,
          startAnchor: _anchorFor(character.position, i),
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

    // Build acting beats from the actual chapter prose first. The AI plan is
    // interpretation, not a replacement for what the book says happened.
    final literaryBeats = _literaryBeats(passage, scene.moment);
    final plannedActions = literaryBeats.isNotEmpty
        ? literaryBeats
        : <String>[
            ...plan.actions,
            ...plan.characters.map((c) => '${c.id}: ${c.action}'),
          ].where((a) => a.trim().isNotEmpty).take(6).toList();

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

  static List<BookCharacter> _orderedCharacterMentions(
    List<BookCharacter> characters,
    String source,
  ) {
    final matches = <({BookCharacter character, int index})>[];
    for (final character in characters) {
      final name = character.name.trim();
      if (name.isEmpty) continue;
      final match = RegExp(
        r'(?<![A-Za-z])' + RegExp.escape(name) + r'(?![A-Za-z])',
        caseSensitive: false,
      ).firstMatch(source);
      if (match != null) {
        matches.add((character: character, index: match.start));
      }
    }
    matches.sort((a, b) => a.index.compareTo(b.index));
    return matches.map((item) => item.character).toList();
  }

  static String _genderedCharacterDescription(
    BookCharacter character,
    String source,
  ) {
    final existing = character.description.trim();
    final lower = existing.toLowerCase();
    if (_hasAny(lower, [
      'female', 'woman', 'girl', 'lady', 'mrs', 'miss', 'daughter',
      'sister', 'wife', 'mother', 'aunt', 'niece',
    ])) {
      return existing.isEmpty ? 'female character' : existing;
    }
    if (_hasAny(lower, [
      'male', 'man', 'boy', 'gentleman', 'mr', 'sir', 'son', 'brother',
      'husband', 'father', 'uncle', 'nephew',
    ])) {
      return existing.isEmpty ? 'male character' : existing;
    }
    final name = RegExp.escape(character.name.trim());
    if (RegExp(r'\b(?:Mrs\.?|Ms\.?|Miss|Lady)\s+' + name + r'\b', caseSensitive: false)
        .hasMatch(source)) {
      return existing.isEmpty ? 'female character' : '$existing; female character';
    }
    if (RegExp(r'\b(?:Mr\.?|Sir|Captain|Colonel|Col|Capt)\s+' + name + r'\b', caseSensitive: false)
        .hasMatch(source)) {
      return existing.isEmpty ? 'male character' : '$existing; male character';
    }
    final mention = RegExp.escape(character.name.trim());
    final match = RegExp(
      r'(.{0,80})\b' + mention + r'\b(.{0,80})',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(source);
    final context = match == null ? '' : match.group(1)! + ' ' + match.group(2)!;
    if (_hasAny(context, ['she', 'her', 'herself'])) {
      return existing.isEmpty ? 'female character' : '\$existing; female character';
    }
    if (_hasAny(context, ['he', 'him', 'his', 'himself'])) {
      return existing.isEmpty ? 'male character' : '\$existing; male character';
    }
    return existing;
  }

  static bool _nameAppears(String name, String source) {
    final normalizedName = name.toLowerCase().trim();
    if (normalizedName.isEmpty) return false;
    if (_hasAny(source, [normalizedName])) return true;
    final tokens = normalizedName
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length >= 3)
        .toList();
    return tokens.any((token) => _hasAny(source, [token]));
  }

  static List<SceneActor> _inferImmediateActors(
    String source, {
    required int limit,
    required int startIndex,
  }) {
    final actors = <SceneActor>[];
    final named = RegExp(
      r'\b(?:Mr\.?|Mrs\.?|Ms\.?|Miss|Lady|Sir|Rev\.?|Dr\.?|Col\.?|Capt\.?|Captain|Colonel)\s+([A-Z][a-z]+)\b',
    ).allMatches(source);
    for (final match in named) {
      if (actors.length >= limit) break;
      final name = match.group(1);
      if (name == null) continue;
      final female = RegExp(r'\b(?:Mrs\.?|Ms\.?|Miss|Lady)\s+' + RegExp.escape(name) + r'\b', caseSensitive: false)
          .hasMatch(source);
      final male = RegExp(r'\b(?:Mr\.?|Sir|Rev\.?|Dr\.?|Col\.?|Capt\.?|Captain|Colonel)\s+' + RegExp.escape(name) + r'\b', caseSensitive: false)
          .hasMatch(source);
      actors.add(SceneActor(
        id: _slug(name),
        name: name,
        description: female
            ? 'female character present in the immediate passage'
            : male
                ? 'male character present in the immediate passage'
                : 'character present in the immediate passage',
        startAnchor: (startIndex + actors.length) == 0 ? 'left' : 'right',
      ));
    }
    if (actors.length < limit && _hasAny(source, ['she', 'her', 'herself'])) {
      actors.add(SceneActor(
        id: 'immediate_female',
        name: 'Character',
        description: 'female character present in the immediate passage',
        startAnchor: (startIndex + actors.length) == 0 ? 'left' : 'right',
      ));
    }
    if (actors.length < limit && _hasAny(source, ['he', 'him', 'his', 'himself'])) {
      actors.add(SceneActor(
        id: 'immediate_male',
        name: 'Character',
        description: 'male character present in the immediate passage',
        startAnchor: (startIndex + actors.length) == 0 ? 'left' : 'right',
      ));
    }
    return actors;
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
    final hasPhysicalSetting = _hasAny(source, [
      'room', 'house', 'hall', 'dining', 'library', 'parlor', 'parlour',
      'bedroom', 'office', 'inside', 'interior', 'chamber', 'kitchen',
      'fireplace', 'hearth', 'garden', 'forest', 'woods', 'woodland',
      'trees', 'field', 'meadow', 'street', 'road', 'sea', 'ocean', 'shore',
      'harbour', 'harbor', 'outdoors', 'outside', 'courtyard', 'path',
      'station', 'battlefield', 'battle', 'ship', 'deck', 'carriage',
      'coach', 'wagon', 'horse',
    ]);
    if (!hasPhysicalSetting) return 'Narrative setting not specified';
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
    if (_hasAny(source, ['forest', 'woods', 'woodland', 'trees'])) {
      return 'Forest or woodland';
    }
    if (_hasAny(source, ['garden', 'meadow', 'field', 'park', 'courtyard'])) {
      return 'Garden or open grounds';
    }
    if (_hasAny(source, ['sea', 'ocean', 'ship', 'shore', 'harbour', 'harbor', 'deck'])) {
      return 'At sea';
    }
    if (_hasAny(source, ['street', 'road', 'market', 'town', 'city', 'station'])) {
      return 'Street or public place';
    }
    if (_hasAny(source, ['battle', 'battlefield', 'army', 'soldier', 'enemy', 'cannon'])) {
      return 'Battlefield';
    }
    if (_hasAny(source, ['carriage', 'coach', 'wagon', 'horse'])) {
      return 'Road or carriage setting';
    }
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

  static List<String> _literaryBeats(
    List<String> passage,
    String sceneMoment,
  ) {
    final source = passage
        .where((line) => line.trim().isNotEmpty)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (source.isEmpty) return const [];

    const abbreviations = [
      'Mr.', 'Mrs.', 'Ms.', 'Miss.', 'Dr.', 'St.', 'Rev.', 'Col.',
      'Capt.', 'Lady.', 'Sir.',
    ];
    var protectedSource = source;
    for (final abbreviation in abbreviations) {
      protectedSource = protectedSource.replaceAll(
        abbreviation,
        abbreviation.substring(0, abbreviation.length - 1) + '\u0001',
      );
    }
    final sentences = protectedSource
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.replaceAll('\u0001', '.').trim())
        .where((s) => s.length >= 12)
        .toList();

    const actionWords = [
      'walk', 'walked', 'walking', 'went', 'go', 'entered', 'enter',
      'left', 'leaving', 'stood', 'stand', 'rose', 'rise', 'sat', 'sit', 'sitting',
      'read', 'reading', 'wrote', 'write', 'opened', 'open', 'closed',
      'looked', 'look', 'saw', 'see', 'heard', 'hear', 'said', 'spoke',
      'asked', 'replied', 'answered', 'protested', 'argued', 'insisted',
      'continued', 'ran', 'run', 'fought', 'fight', 'took', 'take',
      'held', 'hold', 'reached', 'reach', 'turned', 'knelt', 'kneel',
      'knocked', 'knock',
    ];

    final beats = <String>[];
    for (final sentence in sentences) {
      // Split coordinated actions so "sat ... and read ..." becomes two
      // distinct acting beats instead of one static frame.
      final clauses = sentence
          .split(RegExp(r'\s+(?:and|then)\s+', caseSensitive: false))
          .map((s) => s.trim())
          .where((s) => s.length >= 8);
      for (final clause in clauses) {
        if (_hasAny(clause.toLowerCase(), actionWords)) {
          beats.add(clause);
        }
      }
    }

    if (beats.isNotEmpty) return beats.take(8).toList();
    if (sceneMoment.trim().isNotEmpty && sceneMoment != '[Illustration]') {
      return [sceneMoment.trim()];
    }
    return const [];
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
      'reply', 'replied', 'answer', 'answered', 'protest', 'protested',
      'argue', 'argued', 'insist', 'insisted', 'continue', 'continued',
    ])) { return 'talk'; }
    return 'look';
  }
}
