import '../../domain/experience/ai_scene_plan.dart';
import 'scene_generation_provider.dart';

abstract interface class SceneVideoProvider {
  Future<GeneratedVideo> generateVideo({
    required AiScenePlan plan,
    required String imageBase64,
  });
}
