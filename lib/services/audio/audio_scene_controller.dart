import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../domain/models/audio_scene.dart';

class AudioSceneController {
  final AudioPlayer ambience = AudioPlayer();
  final List<AudioPlayer> _voices = [];
  String? _currentScene;

  Future<void> playScene(AudioScene scene) async {
    if (_currentScene == scene.sceneId) return;
    _currentScene = scene.sceneId;

    await stopAll();

    try {
      await ambience.setLoopMode(LoopMode.one);
      await ambience.setVolume(0.35);

      if (scene.background.startsWith('assets/')) {
        await ambience.setAsset(scene.background);
      } else if (scene.background.isNotEmpty) {
        await ambience.setFilePath(scene.background);
      }

      if (scene.background.isNotEmpty) {
        ambience.play();
      }
    } catch (e) {
      debugPrint('Audio missing or failed: $e');
    }

    for (final voice in scene.voices) {
      Timer(voice.startAt, () async {
        if (_currentScene != scene.sceneId) return;
        try {
          final p = AudioPlayer();
          _voices.add(p);
          if (voice.filePath.startsWith('assets/')) {
            await p.setAsset(voice.filePath);
          } else {
            await p.setFilePath(voice.filePath);
          }
          await p.play();
        } catch (e) {
          debugPrint('Voice audio missing: $e');
        }
      });
    }
  }

  Future<void> stopAll() async {
    await ambience.stop();
    for (final v in _voices) {
      await v.stop();
      await v.dispose();
    }
    _voices.clear();
  }

  void dispose() {
    stopAll();
    ambience.dispose();
  }
}
