import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

/// Renders a character from the scene director's semantic animation intent.
///
/// The director says what the character is doing. The authored Rive asset
/// decides how that intent looks. There is deliberately no homemade IK,
/// camera motion, or image swapping here.
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
    _loader = _createLoader();
  }

  rive.FileLoader _createLoader() => rive.FileLoader.fromUrl(
        widget.assetUrl,
        riveFactory: rive.Factory.rive,
      );

  @override
  void didUpdateWidget(covariant SuperBookRiveActor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetUrl == widget.assetUrl) return;
    _loader.dispose();
    _loader = _createLoader();
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  String get _runtimeAnimation {
    switch (widget.action.trim().toLowerCase()) {
      case 'talk':
        return 'Talking';
      case 'idle':
      case 'listen':
      case 'react':
        return 'Blinking';
      case 'gesture':
      case 'reach':
      case 'walk':
        return 'Talking';
      default:
        return 'Blinking';
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: rive.RiveWidgetBuilder(
        fileLoader: _loader,
        onFailed: (_, __) {},
        controller: (file) => _InstructionalRiveController(
          file,
          animationName: _runtimeAnimation,
        ),
        builder: (context, state) {
          if (state is rive.RiveLoading) {
            return const SizedBox.shrink();
          }
          if (state is rive.RiveFailed) {
            return const SizedBox.shrink();
          }
          if (state is rive.RiveLoaded) {
            return rive.RiveWidget(
              controller: state.controller,
              fit: rive.Fit.contain,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

final class _InstructionalRiveController extends rive.RiveWidgetController {
  _InstructionalRiveController(
    super.file, {
    required this.animationName,
  });

  final String animationName;
  rive.LinearAnimationInstance? _animation;

  @override
  void artboardChanged(rive.Artboard artboard) {
    super.artboardChanged(artboard);
    _selectAnimation();
  }

  void _selectAnimation() {
    final previous = _animation;
    previous?.dispose();
    _animation = artboard.animationNamed(animationName);
    _animation?.time = 0;
  }

  @override
  bool advance(double elapsedSeconds) {
    final changed = super.advance(elapsedSeconds);
    final animation = _animation;
    if (animation == null) return changed;
    final animationChanged = animation.advance(elapsedSeconds);
    animation.apply();
    return changed || animationChanged;
  }

  @override
  void dispose() {
    _animation?.dispose();
    _animation = null;
    super.dispose();
  }
}
