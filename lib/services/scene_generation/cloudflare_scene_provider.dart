import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/experience/ai_scene_plan.dart';
import 'scene_generation_provider.dart';

class CloudflareSceneProvider implements SceneGenerationProvider {
  CloudflareSceneProvider({required this.endpoint, http.Client? client})
      : _client = client ?? http.Client();

  final String endpoint;
  final http.Client _client;

  Uri get _baseUri => Uri.parse(endpoint);

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

    final response = await _client.post(
      _baseUri,
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
    ).timeout(const Duration(seconds: 90));

    final body = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        body['error'] as String? ??
            'SuperBook AI gateway failed with HTTP ${response.statusCode}.',
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

    return GeneratedScene(
      plan: AiScenePlan.fromJson(Map<String, dynamic>.from(planJson)),
      imageBase64: base64,
      mimeType: mimeType,
    );
  }

  @override
  Future<GeneratedVideo> generateVideo({
    required AiScenePlan plan,
    required String imageDataUri,
  }) async {
    if (endpoint.trim().isEmpty) {
      throw StateError('SuperBook AI scene endpoint is not configured.');
    }

    final videoEndpoint = _baseUri.replace(
      path: _baseUri.path.endsWith('/')
          ? '${_baseUri.path}video'
          : '${_baseUri.path}/video',
    );

    final response = await _client.post(
      videoEndpoint,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'scenePlan': plan.toJson(),
        'imageDataUri': imageDataUri,
      }),
    ).timeout(const Duration(seconds: 180));

    final body = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        body['error'] as String? ??
            'SuperBook AI video generation failed with HTTP ${response.statusCode}.',
      );
    }

    final video = body['video'];
    if (video is! Map) {
      throw StateError(
        body['videoError'] as String? ??
            'SuperBook AI video generation returned no video.',
      );
    }

    final url = video['url'];
    final duration = video['durationSeconds'];
    if (url is! String || url.isEmpty || duration is! num) {
      throw StateError('SuperBook AI video generation returned an invalid video.');
    }

    return GeneratedVideo(
      url: url,
      durationSeconds: duration.toInt(),
    );
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw StateError('SuperBook AI gateway returned invalid JSON.');
    }
  }
}
