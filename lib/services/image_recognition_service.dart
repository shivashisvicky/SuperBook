import 'dart:typed_data';
import 'package:flutter/services.dart';

class ImageRecognitionService {
  static const MethodChannel _channel =
      MethodChannel('interactive_book/vision');

  Future<String?> detectPage(Uint8List frame) async {
    return await _channel.invokeMethod<String>(
      'detectPage',
      {'frame': frame},
    );
  }
}
