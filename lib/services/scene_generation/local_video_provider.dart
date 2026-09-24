import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/experience/ai_scene_plan.dart';
import 'scene_generation_provider.dart';
import 'video_generation_provider.dart';

class LocalVideoProvider implements SceneVideoProvider {
  LocalVideoProvider({required this.endpoint, http.Client? client})
      : _client = client ?? http.Client();

  final String endpoint;
  final http.Client _client;

  Uri get _baseUri => Uri.parse(endpoint);

  @override
  Future<GeneratedVideo> generateVideo({
    required AiScenePlan plan,
    required String imageBase64,
  }) async {
    if (endpoint.trim().isEmpty) {
      throw StateError('SuperBook local video endpoint is not configured.');
    }
    if (imageBase64.trim().isEmpty) {
      throw ArgumentError.value(imageBase64, 'imageBase64', 'must not be empty');
    }

    final request = http.MultipartRequest(
      'POST',
      _baseUri.replace(
        path: _baseUri.path.endsWith('/')
            ? _baseUri.path + 'video'
            : _baseUri.path + '/video',
      ),
    )
      ..fields['prompt'] = _promptFor(plan)
      ..fields['num_frames'] = '81'
      ..fields['num_inference_steps'] = '20'
      ..fields['seed'] = '42'
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          base64Decode(imageBase64),
          filename: 'superbook-scene.jpg',
        ),
      );

    final response = await _client
        .send(request)
        .timeout(const Duration(minutes: 8));
    final rawBody = await response.stream.bytesToString();
    dynamic body;
    try {
      body = jsonDecode(rawBody);
    } catch (_) {
      throw StateError('SuperBook local video engine returned invalid JSON.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final map = body is Map
          ? Map<String, dynamic>.from(body)
          : const <String, dynamic>{};
      final message = map['error'] as String? ??
          'SuperBook local video engine failed with HTTP ${response.statusCode}.';
      final detail = map['detail'] as String?;
      throw StateError(
        [
          message,
          if (detail != null && detail.isNotEmpty) detail,
        ].join(' '),
      );
    }

    if (body is! Map) {
      throw StateError('SuperBook local video engine returned invalid JSON.');
    }

    final video = body['video'];
    if (video is! Map) {
      throw StateError(
        body['videoError'] as String? ??
            'SuperBook local video engine returned no video.',
      );
    }

    final url = video['url'];
    final duration = video['durationSeconds'];
    if (url is! String || url.isEmpty || duration is! num) {
      throw StateError('SuperBook local video engine returned an invalid video.');
    }

    return GeneratedVideo(
      url: url,
      durationSeconds: duration.toInt(),
    );
  }

  String _promptFor(AiScenePlan plan) {
    final actions = plan.actions.join(', ');
    final characters = plan.characters
        .map((character) =>
            '${character.description}; action=${character.action}; emotion=${character.emotion}')
        .join(' | ');

    return [
      'Cinematic continuous image-to-video shot.',
      plan.motion,
      'Camera: ${plan.camera.movement}, ${plan.camera.shot}, ${plan.camera.angle}.',
      'Characters: $characters.',
      'Actions: $actions.',
      'Environment: ${plan.environment.description}.',
      'Lighting: ${plan.lighting}.',
      'Keep the same characters, clothing, faces, composition and environment.',
      'Animate only natural physical motion and camera motion. No cuts.',
    ].where((value) => value.trim().isNotEmpty).join(' ');
  }
}
