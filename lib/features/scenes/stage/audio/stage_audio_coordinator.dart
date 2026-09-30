import 'package:flutter/material.dart';
import '../models/scene_stage_script.dart';
import '../../../../services/audio/audio_scene_controller.dart';
import '../../../../domain/models/audio_scene.dart';

class StageAudioCoordinator extends StatefulWidget {
  const StageAudioCoordinator({
    super.key,
    required this.script,
    required this.child,
  });

  final SceneStageScript script;
  final Widget child;

  @override
  State<StageAudioCoordinator> createState() => _StageAudioCoordinatorState();
}

class _StageAudioCoordinatorState extends State<StageAudioCoordinator> {
  final AudioSceneController _audio = AudioSceneController();

  @override
  void initState() {
    super.initState();
    _playAmbience();
  }

  @override
  void didUpdateWidget(StageAudioCoordinator old) {
    super.didUpdateWidget(old);
    if (old.script.biome != widget.script.biome ||
        old.script.lighting != widget.script.lighting) {
      _playAmbience();
    }
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  void _playAmbience() {
    final asset = _ambientAssetFor(widget.script.biome, widget.script.lighting);
    final scene = AudioScene(
      sceneId: '${widget.script.biome.name}_${widget.script.lighting.name}',
      background: asset,
      voices: const [],
    );
    _audio.playScene(scene);
  }

  String _ambientAssetFor(EnvironmentBiome biome, LightingMood lighting) {
    if (lighting == LightingMood.overcastRain) return 'assets/audio/rain.mp3';
    if (lighting == LightingMood.warmHearth) return 'assets/audio/hearth.mp3';

    switch (biome) {
      case EnvironmentBiome.forestWoodland:
      case EnvironmentBiome.gardenMeadow:
        return 'assets/audio/nature.mp3';
      case EnvironmentBiome.seaHarbor:
        return 'assets/audio/ocean.mp3';
      case EnvironmentBiome.streetStation:
        return 'assets/audio/town.mp3';
      case EnvironmentBiome.roadCarriage:
        return 'assets/audio/carriage.mp3';
      case EnvironmentBiome.drawingParlor:
      case EnvironmentBiome.libraryStudy:
      case EnvironmentBiome.diningHall:
      case EnvironmentBiome.bedchamber:
      case EnvironmentBiome.corridorHall:
      default:
        return 'assets/audio/room_tone.mp3';
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
