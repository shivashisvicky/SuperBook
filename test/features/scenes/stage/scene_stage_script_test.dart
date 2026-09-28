import 'package:flutter_test/flutter_test.dart';

import 'package:superbook/domain/book.dart';
import 'package:superbook/domain/experience/superbook_scene_graph.dart';
import 'package:superbook/features/scenes/stage/models/scene_stage_script.dart';

void main() {
  const scene = Scene(
    title: 'The Walk',
    moment: 'She walked alone through the forest.',
    atmosphere: 'Rain over the woodland.',
    caption: 'She walked alone.',
  );

  test('walking beat receives a traversal target when prose has no anchor', () {
    final graph = SuperBookSceneGraph(
      environment: 'Forest or woodland',
      anchors: const {
        'left': SceneAnchor('left', .27, .68),
        'right': SceneAnchor('right', .73, .68),
        'center': SceneAnchor('center', .50, .68),
      },
      actors: const [
        SceneActor(
          id: 'woman',
          name: 'Woman',
          description: 'A woman walking alone.',
          startAnchor: 'left',
        ),
      ],
      props: const [],
      timeline: [
        const SceneActionBeat(
          text: 'She walked alone through the forest.',
          action: 'walk',
          actorId: 'woman',
          duration: Duration(milliseconds: 4200),
        ),
      ],
    );

    final script = SceneStageScript.fromGraph(
      graph: graph,
      bookCharacters: const [
        BookCharacter(
          name: 'Woman',
          role: 'protagonist',
          description: 'A woman walking alone.',
        ),
      ],
      scene: scene,
      passage: const ['She walked alone through the forest.'],
    );

    final track = script.beats.single.tracks.single;
    expect(track.pose, ActorPose.walk);
    expect(track.targetX, closeTo(.72, .0001));
    expect(track.targetY, closeTo(.78, .0001));
  });

  test('drawing room does not inject ungrounded window, table, or door', () {
    final graph = SuperBookSceneGraph(
      environment: 'Drawing room',
      anchors: const {
        'left': SceneAnchor('left', .27, .68),
        'right': SceneAnchor('right', .73, .68),
        'center': SceneAnchor('center', .50, .68),
      },
      actors: const [
        SceneActor(
          id: 'woman',
          name: 'Woman',
          description: 'A woman.',
          startAnchor: 'left',
        ),
      ],
      props: const [],
      timeline: [
        const SceneActionBeat(
          text: 'She listened.',
          action: 'talk',
          actorId: 'woman',
          duration: Duration(milliseconds: 3600),
        ),
      ],
    );

    final script = SceneStageScript.fromGraph(
      graph: graph,
      bookCharacters: const [],
      scene: const Scene(
        title: 'Conversation',
        moment: 'She listened.',
        atmosphere: 'A quiet social moment.',
        caption: 'She listened.',
      ),
      passage: const ['She listened.'],
    );

    final ids = script.setPieces.map((p) => p.id).toSet();
    expect(ids, containsAll(<String>['armchair_left', 'armchair_right']));
    expect(ids, isNot(contains('window')));
    expect(ids, isNot(contains('table')));
    expect(ids, isNot(contains('door')));
  });
}
