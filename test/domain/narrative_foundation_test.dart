import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_book_app/domain/experience/scene_plan.dart';
import 'package:interactive_book_app/domain/narrative/narrative_models.dart';

void main() {
  test('ReaderState preserves the spoiler boundary', () {
    const state = ReaderState(
      bookId: 'fixture-book',
      chapterId: 'chapter-1',
      passageId: 'passage-3',
      progress: 0.25,
      spoilerBoundary: 3,
    );

    expect(state.bookId, 'fixture-book');
    expect(state.passageId, 'passage-3');
    expect(state.spoilerBoundary, 3);
  });

  test('ScenePlan stays provider-neutral', () {
    const plan = ScenePlan(
      id: 'plan-1',
      sceneId: 'scene-1',
      intensity: PresentationIntensity.animated,
      sourcePassageIds: ['passage-3'],
      shots: [
        SceneShot(
          id: 'shot-1',
          duration: Duration(seconds: 4),
          entityIds: ['hero'],
          visualIntent: 'The hero looks toward the distant gate.',
        ),
      ],
    );

    expect(plan.intensity, PresentationIntensity.animated);
    expect(plan.shots.single.duration, const Duration(seconds: 4));
    expect(plan.sourcePassageIds, contains('passage-3'));
  });
}
