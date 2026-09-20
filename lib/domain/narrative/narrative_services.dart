import 'narrative_models.dart';
import '../experience/scene_plan.dart';

abstract interface class NarrativeAnalyzer {
  Future<List<NarrativeBeat>> analyze(
    List<Passage> passages, {
    required int spoilerBoundary,
  });
}

abstract interface class EntityResolver {
  Future<List<StoryEntity>> resolve(List<Passage> passages);
}

abstract interface class ScenePlanner {
  Future<ScenePlan> plan(Scene scene, ReaderState readerState);
}

abstract interface class QuestionAnswerer {
  Future<String> answer(
    String question, {
    required ReaderState readerState,
  });
}
