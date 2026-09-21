import '../../domain/experience/ai_scene_plan.dart';

class GeneratedVideo {
  const GeneratedVideo({
    required this.url,
    required this.durationSeconds,
  });

  final String url;
  final int durationSeconds;
}

class GeneratedScene {
  const GeneratedScene({
    required this.plan,
    required this.imageBase64,
    required this.mimeType,
    this.videoUrl,
    this.videoDurationSeconds,
  });

  final AiScenePlan plan;
  final String imageBase64;
  final String mimeType;
  final String? videoUrl;
  final int? videoDurationSeconds;

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  String get imageDataUri => 'data:$mimeType;base64,$imageBase64';
  String get dataUri => imageDataUri;
}

abstract interface class SceneGenerationProvider {
  Future<GeneratedScene> generate({
    required String bookId,
    required String chapterId,
    required String passage,
    String? author,
    String? title,
  });

  Future<GeneratedVideo> generateVideo({
    required AiScenePlan plan,
  });
}
