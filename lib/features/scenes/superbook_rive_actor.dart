import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

/// Runtime adapter for a living illustrated character.
///
/// The scene director supplies semantic intent. This layer owns continuous
/// playback and maps that intent to authored Rive state-machine/animation
/// inputs. It deliberately contains no camera motion or image swapping.
class SuperBookRiveActor extends StatefulWidget {
  const SuperBookRiveActor({
    super.key,
    required this.action,
    this.assetUrl = _defaultAssetUrl,
  });

  final String action;
  final String assetUrl;

  static const _defaultAssetUrl =
      'https://raw.githubusercontent.com/videosdk-live/character-sdk-flutter-rive-example/main/assets/character.riv';

  @override
  State<SuperBookRiveActor> createState() => _SuperBookRiveActorState();
}

class _SuperBookRiveActorState extends State<SuperBookRiveActor> {
  late rive.FileLoader _loader;

  @override
  void initState() {
    super.initState();
    _loader = rive.FileLoader.fromUrl(
      widget.assetUrl,
      riveFactory: rive.Factory.rive,
    );
  }

  @override
  void didUpdateWidget(covariant SuperBookRiveActor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetUrl == widget.assetUrl) return;
    _loader.dispose();
    _loader = rive.FileLoader.fromUrl(
      widget.assetUrl,
      riveFactory: rive.Factory.rive,
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  static const _animationAliases = <String, String>{
    'talk': 'Talking',
    'idle': 'Blinking',
    'listen': 'Blinking',
    'gesture': 'Talking',
    'reach': 'Talking',
    'walk': 'Talking',
    'react': 'Blinking',
  };

  String get _animationName =>
      _animationAliases[widget.action.trim().toLowerCase()] ?? 'Blinking';

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: rive.RiveWidgetBuilder(
        fileLoader: _loader,
        onFailed: (_, __) {},
        builder: (context, state) {
          if (state is rive.RiveLoading) {
            return const SizedBox.shrink();
          }
          if (state is rive.RiveFailed) {
            return const SizedBox.shrink();
          }
          if (state is rive.RiveLoaded) {
            return rive.RiveWidget(
              controller: _InstructionalRiveController(
                state.controller.file,
                animationName: _animationName,
              ),
              fit: rive.Fit.contain,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
