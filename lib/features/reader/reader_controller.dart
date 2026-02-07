import 'dart:typed_data';
import '../../services/image_recognition_service.dart';
import '../../services/audio/audio_scene_controller.dart';
import '../../domain/models/audio_scene.dart';

class ReaderController {
  final ImageRecognitionService vision = ImageRecognitionService();
  final AudioSceneController audio = AudioSceneController();

  String? _currentPage;
  String? _candidate;
  int _count = 0;
  DateTime _lastRun = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> onFrame(Uint8List jpeg) async {
    final now = DateTime.now();
    if (now.difference(_lastRun).inMilliseconds < 500) return;
    _lastRun = now;

    final page = await vision.detectPage(jpeg);
    if (page == null || page == _currentPage) return;

    if (page == _candidate) {
      _count++;
    } else {
      _candidate = page;
      _count = 1;
    }

    if (_count >= 2) {
      _currentPage = page;
      _count = 0;
      audio.playScene(SceneRepository.sceneFor(page));
    }
  }
}

class SceneRepository {
  static AudioScene sceneFor(String pageId) {
    return AudioScene(
      sceneId: pageId,
      background: '/data/audio/ambience.mp3',
      voices: [],
    );
  }
}
