import 'scene_generation_provider.dart';

class SceneGenerationCache {
  final Map<String, GeneratedScene> _memory = {};

  GeneratedScene? get(String key) => _memory[key];

  void put(String key, GeneratedScene scene) => _memory[key] = scene;

  String key({
    required String bookId,
    required String chapterId,
    required String passage,
  }) {
    return bookId + ':' + chapterId + ':' + _stableHash(passage).toString();
  }

  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
