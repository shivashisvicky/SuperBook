import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/camera/camera_service.dart';
import '../../core/permissions/permission_service.dart';
import 'reader_controller.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final CameraService camera = CameraService();
  final ReaderController controller = ReaderController();
  bool ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!await PermissionService.requestCamera()) return;
    await camera.initialize(_onFrame);
    setState(() => ready = true);
  }

  void _onFrame(CameraImage image) {
    // Convert YUV → JPEG via native util
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: CameraPreview(camera.controller!),
    );
  }
}
