class AudioScene {
  final String sceneId;
  final String background;
  final List<VoiceTrack> voices;

  AudioScene({
    required this.sceneId,
    required this.background,
    required this.voices,
  });
}

class VoiceTrack {
  final String filePath;
  final Duration startAt;

  VoiceTrack({
    required this.filePath,
    required this.startAt,
  });
}
