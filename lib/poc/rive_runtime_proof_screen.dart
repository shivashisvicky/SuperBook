import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

class RiveRuntimeProofScreen extends StatefulWidget {
  const RiveRuntimeProofScreen({super.key});

  @override
  State<RiveRuntimeProofScreen> createState() => _RiveRuntimeProofScreenState();
}

class _RiveRuntimeProofScreenState extends State<RiveRuntimeProofScreen> {
  static const _assetUrl =
      'https://raw.githubusercontent.com/videosdk-live/character-sdk-flutter-rive-example/main/assets/character.riv';

  late final rive.FileLoader _loader;
  rive.RiveWidgetController? _controller;
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
      _status = active ? 'LIVE · State Machine running' : 'PAUSED';
    });
  }

  void _fire(String name) {
    final controller = _controller;
    if (controller == null) return;
    final trigger = controller.stateMachine.trigger(name);
    if (trigger == null) {
      setState(() => _status = 'No "$name" trigger in this asset');
      return;
    }
    trigger.fire();
    setState(() => _status = 'LIVE · fired "$name"');
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
                    child: RiveWidgetBuilder(
                      fileLoader: _loader,
                      stateMachineSelector:
                          const rive.StateMachineNamed('State Machine 1'),
                      onLoaded: (state) {
                        _controller = state.controller;
                        _controller!.active = true;
                        if (mounted) {
                          setState(
                            () => _status = 'LIVE · State Machine 1 running',
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
                      builder: (context, state) => switch (state) {
                        rive.RiveLoading() => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        rive.RiveFailed() => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Rive failed to load.\n\n${state.error}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        rive.RiveLoaded() => rive.RiveWidget(
                            controller: state.controller,
                            fit: rive.Fit.contain,
                          ),
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
                                  _controller!.active = true;
                                  setState(
                                    () => _status =
                                        'LIVE · State Machine restarted',
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
                            : () => _fire('Hit'),
                        child: const Text('Hit'),
                      ),
                      OutlinedButton(
                        onPressed: _controller == null
                            ? null
                            : () => _fire('In'),
                        child: const Text('In'),
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
                    'Rive skeletal runtime · no frame-by-frame image swapping',
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
