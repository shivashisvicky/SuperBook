class AiScenePlan {
  const AiScenePlan({
    required this.schemaVersion,
    required this.sceneSummary,
    required this.visualStyle,
    required this.characters,
    required this.environment,
    required this.props,
    required this.actions,
    required this.camera,
    required this.lighting,
    required this.motion,
    required this.imagePrompt,
  });

  final String schemaVersion;
  final String sceneSummary;
  final String visualStyle;
  final List<AiSceneCharacter> characters;
  final AiSceneEnvironment environment;
  final List<String> props;
  final List<String> actions;
  final AiSceneCamera camera;
  final String lighting;
  final String motion;
  final String imagePrompt;

  factory AiScenePlan.fromJson(Map<String, dynamic> json) => AiScenePlan(
        schemaVersion: json['schemaVersion'] as String? ?? '1',
        sceneSummary: json['sceneSummary'] as String? ?? '',
        visualStyle: json['visualStyle'] as String? ?? 'cinematic literary realism',
        characters: _list(json['characters']).map(AiSceneCharacter.fromJson).toList(),
        environment: AiSceneEnvironment.fromJson(_map(json['environment'])),
        props: _strings(json['props']),
        actions: _strings(json['actions']),
        camera: AiSceneCamera.fromJson(_map(json['camera'])),
        lighting: json['lighting'] as String? ?? '',
        motion: json['motion'] as String? ?? '',
        imagePrompt: json['imagePrompt'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'sceneSummary': sceneSummary,
        'visualStyle': visualStyle,
        'characters': characters.map((e) => e.toJson()).toList(),
        'environment': environment.toJson(),
        'props': props,
        'actions': actions,
        'camera': camera.toJson(),
        'lighting': lighting,
        'motion': motion,
        'imagePrompt': imagePrompt,
      };

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static List<Map<String, dynamic>> _list(Object? value) => value is List
      ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : <Map<String, dynamic>>[];

  static List<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];
}

class AiSceneCharacter {
  const AiSceneCharacter({
    required this.id,
    required this.description,
    required this.action,
    required this.emotion,
    required this.position,
  });

  final String id;
  final String description;
  final String action;
  final String emotion;
  final String position;

  factory AiSceneCharacter.fromJson(Map<String, dynamic> json) => AiSceneCharacter(
        id: json['id'] as String? ?? '',
        description: json['description'] as String? ?? '',
        action: json['action'] as String? ?? '',
        emotion: json['emotion'] as String? ?? '',
        position: json['position'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'action': action,
        'emotion': emotion,
        'position': position,
      };
}

class AiSceneEnvironment {
  const AiSceneEnvironment({
    required this.location,
    required this.time,
    required this.description,
  });

  final String location;
  final String time;
  final String description;

  factory AiSceneEnvironment.fromJson(Map<String, dynamic> json) =>
      AiSceneEnvironment(
        location: json['location'] as String? ?? '',
        time: json['time'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'location': location,
        'time': time,
        'description': description,
      };
}

class AiSceneCamera {
  const AiSceneCamera({
    required this.shot,
    required this.angle,
    required this.movement,
  });

  final String shot;
  final String angle;
  final String movement;

  factory AiSceneCamera.fromJson(Map<String, dynamic> json) => AiSceneCamera(
        shot: json['shot'] as String? ?? 'wide',
        angle: json['angle'] as String? ?? 'eye level',
        movement: json['movement'] as String? ?? 'slow push-in',
      );

  Map<String, dynamic> toJson() => {
        'shot': shot,
        'angle': angle,
        'movement': movement,
      };
}
