import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

class RiveRuntimeProofScreen extends StatefulWidget {
  const RiveRuntimeProofScreen({super.key});

  @override
  State<RiveRuntimeProofScreen> createState() => _RiveRuntimeProofScreenState();
}

class _RiveRuntimeProofScreenState extends State<RiveRuntimeProofScreen> {
  // This is a runtime validation asset with authored full-body Walk/Hit
  // animations. It is deliberately separate from the eventual SuperBook art.
  static const _assetUrl =
      'https://raw.githubusercontent.com/followthemoney1/nemesis/27934810c1101996fe935bac3ed82e42a73896a2/assets/animations/zombie_character.riv';

  late final rive.FileLoader _loader;
  _ProofCharacterController? _controller;
  String _status = 'Loading Rive asset…';

  @override
  void initState() {
    super.initState();
    _loader = rive.FileLoader.fromUrl(
      _assetUrl,
      riveFactory: rive.Factory.rive,
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  void _setActive(bool active) {
    final controller = _controller;
    if (controller == null) return;
    controller.active = active;
    setState(() {
      _status = active ? 'LIVE · Animation runtime running' : 'PAUSED';
    });
  }

  void _play(String name) {
    final controller = _controller;
    if (controller == null) return;
    controller.play(name);
    setState(() => _status = 'LIVE · playing "$name"');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D12),
      appBar: AppBar(
        title: const Text('Rive Runtime Proof'),
        backgroundColor: const Color(0xFF0B0D12),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF151923),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFF303746)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: rive.RiveWidgetBuilder(
                      fileLoader: _loader,
                      controller: (file) => _ProofCharacterController(file),
                      onLoaded: (state) {
                        _controller =
                            state.controller as _ProofCharacterController;
                        _controller!.active = true;
                        if (mounted) {
                          setState(
                            () => _status = 'LIVE · Animation runtime running',
                          );
                        }
                      },
                      onFailed: (error, stack) {
                        if (mounted) {
                          setState(
                            () => _status = 'Rive load failed: $error',
                          );
                        }
                      },
                      builder: (context, state) {
                        if (state is rive.RiveLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state is rive.RiveFailed) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Rive failed to load.\\n\\n${state.error}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
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
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: _controller == null
                              ? null
                              : () => _setActive(!_controller!.active),
                          child: Text(
                            _controller?.active == false ? 'Resume' : 'Pause',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: _controller == null
                              ? null
                              : () {
                                  _controller!.restart();
                                  setState(
                                    () => _status =
                                        'LIVE · animation restarted',
                                  );
                                },
                          child: const Text('Restart'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      OutlinedButton(
                        onPressed: _controller == null
                            ? null
                            : () => _play('Walk'),
                        child: const Text('Walk'),
                      ),
                      OutlinedButton(
                        onPressed: _controller == null
                            ? null
                            : () => _play('Hit'),
                        child: const Text('Hit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rive skeletal runtime · authored full-body animation · no image swapping',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ProofCharacterController extends rive.RiveWidgetController {
  _ProofCharacterController(super.file);

  rive.Animation? _animation;
  String _animationName = 'Walk';

  void play(String name) {
    _animationName = name;
    final candidate = artboard.animationNamed(name);
    if (candidate == null) return;

    _animation?.dispose();
    _animation = candidate;
    _animation!.time = 0;
    active = true;
  }

  void restart() {
    _animation?.time = 0;
    active = true;
  }

  @override
  void artboardChanged(rive.Artboard artboard) {
    super.artboardChanged(artboard);
    _animation?.dispose();
    _animation = artboard.animationNamed(_animationName);
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
