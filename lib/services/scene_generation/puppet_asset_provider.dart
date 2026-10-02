import 'dart:convert';

import 'package:http/http.dart' as http;

class GeneratedPuppetSheet {
  const GeneratedPuppetSheet({
    required this.base64,
    required this.mimeType,
  });

  final String base64;
  final String mimeType;

  String get dataUri => 'data:$mimeType;base64,$base64';
}

class PuppetAssetProvider {
  PuppetAssetProvider({required this.endpoint, http.Client? client})
      : _client = client ?? http.Client();

  final String endpoint;
  final http.Client _client;

  Future<GeneratedPuppetSheet> generate({
    required String character,
  }) async {
    if (endpoint.trim().isEmpty) {
      throw StateError('SuperBook AI scene endpoint is not configured.');
    }
    if (character.trim().isEmpty) {
      throw ArgumentError.value(character, 'character', 'must not be empty');
    }

    final base = Uri.parse(endpoint);
    final path = base.path.endsWith('/')
        ? '${base.path}puppet-sheet'
        : '${base.path}/puppet-sheet';
    final uri = base.replace(path: path);

    final response = await _client.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'character': character}),
    ).timeout(const Duration(seconds: 90));

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw StateError('Puppet asset service returned invalid JSON.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body['error'] as String? ?? 'Puppet asset generation failed.';
      final detail = body['detail'] as String?;
      throw StateError(
        [error, if (detail != null && detail.isNotEmpty) detail].join(' '),
      );
    }

    final base64 = body['base64'];
    final mimeType = body['mimeType'];
    if (base64 is! String || base64.isEmpty || mimeType is! String) {
      throw StateError('Puppet asset service returned an invalid sprite sheet.');
    }

    return GeneratedPuppetSheet(base64: base64, mimeType: mimeType);
  }
}
