import 'package:camera/camera.dart';

class CameraService {
  CameraController? controller;

  Future<void> initialize(Function(CameraImage) onFrame) async {
    final cameras = await availableCameras();
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );

    controller = CameraController(
      back,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await controller!.initialize();
    await controller!.startImageStream(onFrame);
  }
}
