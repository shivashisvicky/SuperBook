import 'scene_generation_provider.dart';

class SceneGenerationCache {
  final Map<String, GeneratedScene> _memory = {};
  final Map<String, List<GeneratedMotionFrame>> _motion = {};

  GeneratedScene? get(String key) => _memory[key];

  void put(String key, GeneratedScene scene) => _memory[key] = scene;

  List<GeneratedMotionFrame>? getMotion(String key) => _motion[key];

  void putMotion(String key, List<GeneratedMotionFrame> frames) =>
      _motion[key] = List.unmodifiable(frames);

  void clearMotion(String key) => _motion.remove(key);

  String key({
    required String bookId,
    required String chapterId,
    required String passage,
  }) {
    return '$bookId:$chapterId:${_stableHash(passage)}';
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
