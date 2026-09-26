import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
      final message = body['error'] as String? ??
          'SuperBook AI gateway failed with HTTP ${response.statusCode}.';
      final detail = body['detail'] as String?;
      final code = body['code'];
      final upstreamStatus = body['upstreamStatus'];
      final diagnostics = <String>[
        message,
        if (detail != null && detail.isNotEmpty) detail,
        if (code != null) 'code=$code',
        if (upstreamStatus != null) 'upstreamStatus=$upstreamStatus',
      ];
      throw StateError(diagnostics.join(' '));
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
  Future<List<GeneratedMotionFrame>> generateMotionFrames({
    required AiScenePlan plan,
    required String imageBase64,
  }) async {
    if (endpoint.trim().isEmpty) {
      throw StateError('SuperBook AI scene endpoint is not configured.');
    }
    if (imageBase64.trim().isEmpty) {
      throw ArgumentError.value(imageBase64, 'imageBase64', 'must not be empty');
    }

    final motionPath = _baseUri.path.endsWith('/')
        ? '${_baseUri.path}motion'
        : '${_baseUri.path}/motion';
    final motionEndpoint = _baseUri.replace(path: motionPath);

    // FLUX.2 [klein] accepts reference images only below 512x512. The
    // canonical scene can be larger, so resize it locally before sending the
    // motion request. This keeps the animation path independent of paid T2V.
    final motionImageBase64 = await _prepareMotionReference(imageBase64);

    final response = await _client.post(
      motionEndpoint,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'scenePlan': plan.toJson(),
        'imageBase64': motionImageBase64,
      }),
    ).timeout(const Duration(seconds: 150));

    final body = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body['error'] as String? ??
          'SuperBook AI motion generation failed with HTTP ${response.statusCode}.';
      final detail = body['detail'] as String?;
      throw StateError(
        [
          message,
          if (detail != null && detail.isNotEmpty) detail,
        ].join(' '),
      );
    }

    final frames = body['frames'];
    if (frames is! List) {
      throw StateError('SuperBook AI motion generation returned no frames.');
    }

    return frames.whereType<Map>().map((frame) {
      final base64 = frame['base64'];
      final mimeType = frame['mimeType'];
      final beat = frame['beat'];
      if (base64 is! String ||
          base64.isEmpty ||
          mimeType is! String ||
          beat is! String) {
        throw StateError('SuperBook AI motion generation returned an invalid frame.');
      }
      return GeneratedMotionFrame(
        base64: base64,
        mimeType: mimeType,
        beat: beat,
      );
    }).toList();
  }

  @override
  Future<GeneratedVideo> generateVideo({
    required AiScenePlan plan,
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
      }),
    ).timeout(const Duration(seconds: 180));

    final body = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body['error'] as String? ??
          'SuperBook AI video generation failed with HTTP ${response.statusCode}.';
      final detail = body['detail'] as String?;
      final code = body['code'];
      final upstreamStatus = body['upstreamStatus'];

      final diagnostics = <String>[
        message,
        if (detail != null && detail.isNotEmpty) detail,
        if (code != null) 'code=$code',
        if (upstreamStatus != null) 'upstreamStatus=$upstreamStatus',
      ];

      throw StateError(diagnostics.join(' '));
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

  Future<String> _prepareMotionReference(String base64Image) async {
    final source = base64Decode(base64Image);
    final codec = await ui.instantiateImageCodec(
      Uint8List.fromList(source),
      targetWidth: 512,
      targetHeight: 384,
    );
    final frame = await codec.getNextFrame();
    final bytes = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    if (bytes == null) {
      throw StateError('Unable to prepare the scene image for motion generation.');
    }
    return base64Encode(bytes.buffer.asUint8List());
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw StateError('SuperBook AI gateway returned invalid JSON.');
    }
  }
}
