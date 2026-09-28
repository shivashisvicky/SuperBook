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
      bookCharacters: [],
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
    expect(actions, [
      'sit',
      'carriage',
      'stand',
      'walk',
    ]);
    expect(graph.timeline.length, 4);

    expect(graph.timeline[3].actorId, 'family_member');
    expect(graph.timeline[3].targetAnchor, 'window');
    expect(graph.timeline[0].duration.inMilliseconds, greaterThanOrEqualTo(2800));
    expect(graph.timeline[3].duration.inMilliseconds, greaterThanOrEqualTo(4000));
  });

  test('AI cannot replace the book passage with a generic environment', () {
    const plan = AiScenePlan(
      schemaVersion: '1',
      sceneSummary: 'A woman walks alone beneath the trees.',
      visualStyle: 'cinematic literary realism',
      characters: [
        AiSceneCharacter(
          id: 'woman',
          description: 'A woman walking alone.',
          action: 'walks along the path',
          emotion: 'alert',
          position: 'center',
        ),
      ],
      environment: AiSceneEnvironment(
        location: 'Warm drawing room',
        time: 'evening',
        description: 'A comfortable interior with furniture.',
      ),
      props: ['sofa', 'lamp'],
      actions: ['walks along the path'],
      camera: AiSceneCamera(
        shot: 'wide',
        angle: 'eye level',
        movement: 'slow tracking',
      ),
      lighting: 'soft light',
      motion: 'The woman walks beneath the trees.',
      imagePrompt: 'A woman walking in a forest.',
    );

    final graph = SuperBookSceneGraph.from(
      plan: plan,
      scene: const Scene(
        title: 'The Walk',
        moment: 'She follows the narrow path beneath the trees.',
        atmosphere: 'The current woodland moment described in this passage.',
        caption: 'She follows the path.',
      ),
      bookCharacters: [],
      passage: const [
        'She followed a narrow path beneath tall trees.',
        'Leaves moved in the wind around her.',
      ],
      narrativeFocus: 'She walks alone through the woods.',
    );

    expect(graph.environment, 'Forest or woodland');
    expect(graph.anchors.containsKey('window'), isFalse);
  });


  test('literary past tense drives distinct scene actions', () {
    const plan = AiScenePlan(
      schemaVersion: '1',
      sceneSummary: 'A man sat by the fireplace and read a letter.',
      visualStyle: 'cinematic literary realism',
      characters: [
        AiSceneCharacter(
          id: 'man',
          description: 'A man seated by the fire.',
          action: 'sat beside the fireplace and read the letter',
          emotion: 'concerned',
          position: 'center',
        ),
      ],
      environment: AiSceneEnvironment(
        location: 'Warm drawing room',
        time: 'evening',
        description: 'A comfortable interior with a fireplace.',
      ),
      props: ['fireplace', 'letter'],
      actions: ['sat beside the fireplace', 'read the letter'],
      camera: AiSceneCamera(
        shot: 'medium',
        angle: 'eye level',
        movement: 'slow push-in',
      ),
      lighting: 'firelight',
      motion: 'He sat and read.',
      imagePrompt: 'A man reading beside a fireplace.',
    );

    final graph = SuperBookSceneGraph.from(
      plan: plan,
      scene: const Scene(
        title: 'The Letter',
        moment: 'He sat beside the fireplace and read the letter.',
        atmosphere: 'A quiet interior moment.',
        caption: 'He read the letter.',
      ),
      bookCharacters: [],
      passage: const [
        'He sat beside the fireplace and read the letter.',
      ],
    );

    expect(graph.environment, 'Fireplace interior');
    expect(graph.actors.length, 1);
    expect(graph.timeline[0].action, 'sit');
    expect(graph.timeline[1].action, 'read');
    expect(graph.props, contains('letter'));
  });

  test('substring collisions cannot create room anchors', () {
    const plan = AiScenePlan(
      schemaVersion: '1',
      sceneSummary: 'She walked outside.',
      visualStyle: 'cinematic literary realism',
      characters: [
        AiSceneCharacter(
          id: 'woman',
          description: 'A woman walking alone.',
          action: 'walked outside',
          emotion: 'calm',
          position: 'center',
        ),
      ],
      environment: AiSceneEnvironment(
        location: 'Forest',
        time: 'day',
        description: 'Trees and open ground.',
      ),
      props: [],
      actions: ['walked outside'],
      camera: AiSceneCamera(
        shot: 'wide',
        angle: 'eye level',
        movement: 'tracking',
      ),
      lighting: 'daylight',
      motion: 'She walked outside.',
      imagePrompt: 'A woman outdoors.',
    );

    final graph = SuperBookSceneGraph.from(
      plan: plan,
      scene: const Scene(
        title: 'Outside',
        moment: 'She walked outside.',
        atmosphere: 'Open air.',
        caption: 'She walked outside.',
      ),
      bookCharacters: [],
      passage: const ['She walked outside beneath the trees.'],
    );

    expect(graph.environment, 'Forest or woodland');
    expect(graph.anchors.containsKey('door'), isFalse);
    expect(graph.anchors.containsKey('table'), isFalse);
    expect(graph.anchors.containsKey('window'), isFalse);
  });

  test('a solitary passage does not spawn a second fallback actor', () {
    const plan = AiScenePlan(
      schemaVersion: '1',
      sceneSummary: 'A woman walks alone.',
      visualStyle: 'cinematic literary realism',
      characters: [],
      environment: AiSceneEnvironment(
        location: 'Forest',
        time: 'day',
        description: 'Trees and a narrow path.',
      ),
      props: [],
      actions: ['walked alone'],
      camera: AiSceneCamera(
        shot: 'wide',
        angle: 'eye level',
        movement: 'tracking',
      ),
      lighting: 'daylight',
      motion: 'She walked alone.',
      imagePrompt: 'A solitary woman in a forest.',
    );

    final graph = SuperBookSceneGraph.from(
      plan: plan,
      scene: const Scene(
        title: 'Alone',
        moment: 'She walked alone through the forest.',
        atmosphere: 'A solitary woodland moment.',
        caption: 'She walked alone.',
      ),
      bookCharacters: const [
        BookCharacter(name: 'Woman', role: 'protagonist', description: 'A woman.'),
        BookCharacter(name: 'Man', role: 'supporting character', description: 'A man.'),
      ],
      passage: const [
        'She walked alone through the forest.',
      ],
    );

    expect(graph.actors.length, 1);
    expect(graph.timeline.single.action, 'walk');
  });


  test('interior remains authoritative when the passage mentions outside', () {
    const plan = AiScenePlan(
      schemaVersion: '1',
      sceneSummary: 'A woman sits in the dining room and looks outside.',
      visualStyle: 'cinematic literary realism',
      characters: [
        AiSceneCharacter(
          id: 'woman',
          description: 'A woman seated at the table.',
          action: 'looks outside',
          emotion: 'curious',
          position: 'center',
        ),
      ],
      environment: AiSceneEnvironment(
        location: 'Dining room',
        time: 'evening',
        description: 'A room with a window.',
      ),
      props: ['dining table', 'window'],
      actions: ['looks outside'],
      camera: AiSceneCamera(
        shot: 'medium',
        angle: 'eye level',
        movement: 'slow push-in',
      ),
      lighting: 'evening light',
      motion: 'She looks outside.',
      imagePrompt: 'A woman in a dining room looking through a window.',
    );

    final graph = SuperBookSceneGraph.from(
      plan: plan,
      scene: const Scene(
        title: 'The Dining Room',
        moment: 'She sat in the dining room and looked outside.',
        atmosphere: 'An interior moment.',
        caption: 'She looked outside.',
      ),
      bookCharacters: const [],
      passage: const [
        'She sat in the dining room and looked outside through the window.',
      ],
    );

    expect(graph.environment, 'Dining room');
  });

  test('AI drawing-room fallback cannot override prose with no location', () {
    const plan = AiScenePlan(
      schemaVersion: '1',
      sceneSummary: 'People discuss a matter.',
      visualStyle: 'cinematic literary realism',
      characters: [
        AiSceneCharacter(
          id: 'woman',
          description: 'A woman.',
          action: 'stands and listens',
          emotion: 'thoughtful',
          position: 'left',
        ),
      ],
      environment: AiSceneEnvironment(
        location: 'Warm drawing room',
        time: 'evening',
        description: 'A comfortable interior.',
      ),
      props: [],
      actions: ['stands and listens'],
      camera: AiSceneCamera(
        shot: 'medium',
        angle: 'eye level',
        movement: 'static',
      ),
      lighting: 'soft',
      motion: 'She listens.',
      imagePrompt: 'A woman.',
    );

    final graph = SuperBookSceneGraph.from(
      plan: plan,
      scene: const Scene(
        title: 'Chapter V',
        moment: '[Illustration]',
        atmosphere: 'The current family and social moment described in this passage.',
        caption: '[Illustration]',
      ),
      bookCharacters: const [],
      passage: const [
        'Then you would drink a great deal more than you ought, said Mrs. Bennet.',
        'The boy protested that she should not.',
      ],
      narrativeFocus: 'A conversation continues.',
    );

    expect(graph.environment, 'Narrative setting not specified');
    expect(graph.timeline.first.text, contains('drink a great deal more'));
    expect(graph.timeline.length, greaterThanOrEqualTo(2));
  });

}
