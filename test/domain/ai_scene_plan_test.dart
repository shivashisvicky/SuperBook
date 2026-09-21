import 'package:flutter_test/flutter_test.dart';
import 'package:superbook/domain/experience/ai_scene_plan.dart';
import 'package:superbook/services/scene_generation/scene_generation_cache.dart';

void main() {
  test('AI scene plan round-trips through JSON', () {
    const plan = AiScenePlan(
      schemaVersion: '1',
      sceneSummary: 'A traveler enters an inn at night.',
      visualStyle: 'cinematic literary realism',
      characters: [
        AiSceneCharacter(
          id: 'traveler',
          description: 'A weathered young sailor.',
          action: 'entering',
          emotion: 'cautious',
          position: 'foreground left',
        ),
      ],
      environment: AiSceneEnvironment(
        location: 'waterfront inn',
        time: 'night',
        description: 'Old timber interior with a fireplace.',
      ),
      props: ['fireplace', 'harpoon'],
      actions: ['traveler enters', 'fire flickers'],
      camera: AiSceneCamera(
        shot: 'wide',
        angle: 'eye level',
        movement: 'slow push-in',
      ),
      lighting: 'warm firelight and deep shadows',
      motion: 'subtle fire and cloth movement',
      imagePrompt: 'cinematic waterfront inn at night',
    );

    final restored = AiScenePlan.fromJson(plan.toJson());
    expect(restored.sceneSummary, plan.sceneSummary);
    expect(restored.characters.single.id, 'traveler');
    expect(restored.environment.location, 'waterfront inn');
    expect(restored.camera.movement, 'slow push-in');
  });

  test('scene cache key changes when source passage changes', () {
    final cache = SceneGenerationCache();
    final a = cache.key(
      bookId: '2701',
      chapterId: '3',
      passage: 'Queequeg sat by the fire.',
    );
    final b = cache.key(
      bookId: '2701',
      chapterId: '3',
      passage: 'Queequeg stood by the fire.',
    );
    expect(a, isNot(b));
    expect(a, contains('2701:3:'));
  });
}
