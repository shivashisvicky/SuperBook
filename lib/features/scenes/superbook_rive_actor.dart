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

  rive.StateMachineSelector get _selector =>
      const rive.StateMachineNamed('State Machine 1');

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RiveWidgetBuilder(
        fileLoader: _loader,
        stateMachineSelector: _selector,
        onFailed: (_, __) {},
        builder: (context, state) => switch (state) {
          rive.RiveLoading() => const SizedBox.shrink(),
          rive.RiveFailed() => const SizedBox.shrink(),
          rive.RiveLoaded() => rive.RiveWidget(
              controller: state.controller,
              fit: rive.Fit.contain,
            ),
        },
      ),
    );
  }
}
