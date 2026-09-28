import 'package:flutter_test/flutter_test.dart';

import 'package:superbook/domain/book.dart';
import 'package:superbook/domain/experience/ai_scene_plan.dart';
import 'package:superbook/domain/experience/superbook_scene_graph.dart';

void main() {
  test('AI scene plan becomes an explicit reader timeline', () {
    const plan = AiScenePlan(
      schemaVersion: '1',
      sceneSummary: 'A family waits in a dining room as a carriage arrives outside.',
      visualStyle: 'cinematic literary realism',
      characters: [
        AiSceneCharacter(
          id: 'Elizabeth',
          description: 'Young woman seated with family.',
          action: 'walks toward the window',
          emotion: 'alert',
          position: 'left at the table',
        ),
        AiSceneCharacter(
          id: 'Family member',
          description: 'Family member seated at the table.',
          action: 'looks toward the window',
          emotion: 'curious',
          position: 'right at the table',
        ),
      ],
      environment: AiSceneEnvironment(
        location: 'Bennet family dining room',
        time: 'evening',
        description: 'A dining room with a window looking outside.',
      ),
      props: ['dining table', 'window', 'carriage'],
      actions: [
        'turn toward the window',
        'stand',
        'walk to the window',
        'reach and look outside',
        'carriage arrives outside',
      ],
      camera: AiSceneCamera(
        shot: 'medium wide',
        angle: 'eye level',
        movement: 'slow push-in',
      ),
      lighting: 'warm evening light',
      motion: 'Elizabeth turns, stands, walks to the window and looks outside.',
      imagePrompt: 'A coherent dining room scene.',
    );

    final scene = Scene(
      title: 'Dining room',
      moment: 'A carriage arrives outside.',
      atmosphere: 'Warm evening light.',
      caption: 'A carriage is heard outside.',
    );

    final graph = SuperBookSceneGraph.from(
      plan: plan,
      scene: scene,
      bookCharacters: const [],
      passage: const [
        'The family sat in the dining room.',
        'A carriage was heard outside.',
        'Elizabeth rose and walked to the window.',
      ],
    );

    expect(graph.actors.first.id, 'elizabeth');
    expect(graph.anchors.containsKey('window'), isTrue);
    expect(graph.anchors.containsKey('outside_window'), isTrue);
    expect(graph.props, contains('carriage'));

    final actions = graph.timeline.map((b) => b.action).toList();
    expect(actions.take(5), [
      'look',
      'stand',
      'walk',
      'reach',
      'carriage',
    ]);
    expect(actions.length, 6);
    expect(graph.timeline[5].actorId, 'elizabeth');

    expect(graph.timeline.first.targetAnchor, 'window');
    expect(graph.timeline[2].targetAnchor, 'window');
    expect(graph.timeline[3].targetAnchor, 'outside_window');
    expect(graph.timeline[0].duration.inMilliseconds, greaterThanOrEqualTo(2800));
    expect(graph.timeline[2].duration.inMilliseconds, greaterThanOrEqualTo(4000));
    expect(graph.timeline[4].duration.inMilliseconds, greaterThanOrEqualTo(4000));
  });
}
