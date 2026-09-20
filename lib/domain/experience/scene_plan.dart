import '../narrative/narrative_models.dart';

/// Provider-neutral presentation plan.
///
/// Renderers consume this model. AI/video/image providers must never leak
/// their own request formats into the domain layer.
class ScenePlan {
  final String id;
  final String sceneId;
  final PresentationIntensity intensity;
  final List<SceneShot> shots;
  final List<String> sourcePassageIds;

  const ScenePlan({
    required this.id,
    required this.sceneId,
    required this.intensity,
    this.shots = const [],
    this.sourcePassageIds = const [],
  });
}

class SceneShot {
  final String id;
  final Duration duration;
  final List<String> entityIds;
  final String? narration;
  final String? ambience;
  final String? visualIntent;

  const SceneShot({
    required this.id,
    required this.duration,
    this.entityIds = const [],
    this.narration,
    this.ambience,
    this.visualIntent,
  });
}
