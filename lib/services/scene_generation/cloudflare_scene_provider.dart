import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/experience/ai_scene_plan.dart';
import 'scene_generation_provider.dart';

class CloudflareSceneProvider implements SceneGenerationProvider {
  CloudflareSceneProvider({required this.endpoint, http.Client? client})
      : _client = client ?? http.Client();

  final String endpoint;
  final http.Client _client;

  @override
  Future<GeneratedScene> generate({
    required String bookId,
    required String chapterId,
    required String passage,
    String? author,
    String? title,
  }) async {
    if (endpoint.trim().isEmpty) {
      throw StateError('SuperBook AI scene endpoint is not configured.');
    }
    if (passage.trim().isEmpty) {
      throw ArgumentError.value(passage, 'passage', 'must not be empty');
    }

    final res = await _client.post(
      Uri.parse(endpoint),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'bookId': bookId,
        'chapterId': chapterId,
        'title': title,
        'author': author,
        'passage': passage,
      }),
    ).timeout(const Duration(seconds: 180));

    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw StateError('SuperBook AI gateway returned invalid JSON.');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError(
        body['error'] as String? ??
            'SuperBook AI gateway failed with HTTP ${res.statusCode}.',
      );
    }

    final planJson = body['scenePlan'];
    final image = body['image'];
    if (planJson is! Map || image is! Map) {
      throw StateError('SuperBook AI gateway returned an incomplete scene.');
    }

    final base64 = image['base64'];
    final mimeType = image['mimeType'];
    if (base64 is! String || base64.isEmpty || mimeType is! String) {
      throw StateError('SuperBook AI gateway returned an invalid scene image.');
    }

    final video = body['video'];
    String? videoUrl;
    int? videoDurationSeconds;
    if (video is Map) {
      final url = video['url'];
      if (url is String && url.isNotEmpty) {
        videoUrl = url;
      }
      final duration = video['durationSeconds'];
      if (duration is num) {
        videoDurationSeconds = duration.toInt();
      }
    }

    return GeneratedScene(
      plan: AiScenePlan.fromJson(Map<String, dynamic>.from(planJson)),
      imageBase64: base64,
      mimeType: mimeType,
      videoUrl: videoUrl,
      videoDurationSeconds: videoDurationSeconds,
    );
  }
}
