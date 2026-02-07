import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../../domain/models/audio_scene.dart';

class AudioSceneController {
  final AudioPlayer ambience = AudioPlayer();
  final List<AudioPlayer> _voices = [];
  String? _currentScene;

  Future<void> playScene(AudioScene scene) async {
    if (_currentScene == scene.sceneId) return;
    _currentScene = scene.sceneId;

    for (final v in _voices) {
      await v.stop();
      await v.dispose();
    }
    _voices.clear();

    await ambience.setLoopMode(LoopMode.one);
    await ambience.setVolume(0.35);
    await ambience.setFilePath(scene.background);
    await ambience.play();

    for (final voice in scene.voices) {
      Timer(voice.startAt, () async {
        final p = AudioPlayer();
        _voices.add(p);
        await p.setFilePath(voice.filePath);
        await p.play();
      });
    }
  }
}
