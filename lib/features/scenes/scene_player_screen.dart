import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../domain/book.dart';
import '../../services/scene_generation/cloudflare_scene_provider.dart';
import '../../services/scene_generation/scene_generation_cache.dart';
import '../../services/scene_generation/scene_generation_provider.dart';

const _sceneEndpoint = String.fromEnvironment('SUPERBOOK_AI_SCENE_ENDPOINT');
final _sceneCache = SceneGenerationCache();

class ScenePlayerScreen extends StatefulWidget {
  const ScenePlayerScreen({
    super.key,
    required this.book,
    required this.scene,
    required this.beat,
  });

  final Book book;
  final Scene scene;
  final NarrativeBeat beat;

  @override
  State<ScenePlayerScreen> createState() => _ScenePlayerScreenState();
}

class _ScenePlayerScreenState extends State<ScenePlayerScreen>
    with SingleTickerProviderStateMixin {
  GeneratedScene? _generated;
  String? _error;
  bool _loading = false;
  VideoPlayerController? _video;
  late final AnimationController _storyController;

  Chapter get _chapter =>
      widget.book.chapters.firstWhere((chapter) => chapter.id == widget.beat.chapterId);

  String get _cacheKey => _sceneCache.key(
        bookId: widget.book.id,
        chapterId: widget.beat.chapterId,
        passage: _chapter.passage.join('\n'),
      );

  @override
  void initState() {
    super.initState();
    _storyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    final cached = _sceneCache.get(_cacheKey);
    _generated = cached;
    if (cached?.hasVideo == true) {
      unawaited(_loadVideo(cached!.videoUrl!));
    } else if (cached == null) {
      unawaited(_generate());
    }
  }

  @override
  void dispose() {
    _storyController.dispose();
    _video?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo(String url) async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      final old = _video;
      setState(() => _video = controller);
      await old?.dispose();
      await controller.play();
    } catch (error) {
      await controller.dispose();
      if (mounted) {
        setState(() => _error = 'Generated animation could not be loaded: $error');
      }
    }
  }

  Future<void> _generate({bool force = false}) async {
    if (_loading) return;
    if (_sceneEndpoint.isEmpty) {
      setState(() {
        _error = 'AI scene generation is not configured for this build yet.';
      });
      return;
    }

    if (force) {
      final oldVideo = _video;
      _video = null;
      await oldVideo?.dispose();
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cached = _sceneCache.get(_cacheKey);
      if (cached != null && !force) {
        setState(() => _generated = cached);
        if (cached.hasVideo) {
          await _loadVideo(cached.videoUrl!);
        }
        return;
      }

      final provider = CloudflareSceneProvider(endpoint: _sceneEndpoint);
      final generated = await provider.generate(
        bookId: widget.book.id,
        chapterId: widget.beat.chapterId,
        passage: _chapter.passage.join('\n'),
        author: widget.book.author,
        title: widget.book.title,
      );
      _sceneCache.put(_cacheKey, generated);

      if (mounted) {
        setState(() {
          _generated = generated;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    } finally {
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _visual(GeneratedScene generated) {
    final video = _video;
    if (video != null && video.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: video.value.size.width,
          height: video.value.size.height,
          child: VideoPlayer(video),
        ),
      );
    }

    return _LivingSceneVisual(
      generated: generated,
      controller: _storyController,
    );
  }

  @override
  Widget build(BuildContext context) {
    final generated = _generated;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.scene.title),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (generated != null)
            _visual(generated)
          else
            const ColoredBox(color: Color(0xFF05070B)),
          if (generated == null && _loading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Creating your story moment…',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Card(
              color: const Color(0xE610141C),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 15, 18, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'EXPERIENCE · STORY MOMENT',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const Spacer(),
                        if (generated != null) const _PlayingPill(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      generated?.plan.sceneSummary ?? widget.scene.caption,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    if (generated != null)
                      Text(
                        generated.plan.environment.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      Text(widget.scene.atmosphere),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        if (generated != null)
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _storyController,
                              builder: (context, _) {
                                final actions = generated.plan.actions;
                                if (actions.isEmpty) {
                                  return Text(
                                    'Narrative beat · intensity ${widget.beat.intensity}',
                                  );
                                }
                                final index = math.min(
                                  actions.length - 1,
                                  (_storyController.value * actions.length).floor(),
                                );
                                return AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 450),
                                  child: Text(
                                    actions[index],
                                    key: ValueKey<String>(actions[index]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          Expanded(
                            child: Text(
                              'Narrative beat · intensity ${widget.beat.intensity}',
                            ),
                          ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _loading
                              ? null
                              : () => _generate(force: generated != null),
                          icon: _loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(_loading ? 'Creating…' : 'Regenerate'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayingPill extends StatelessWidget {
  const _PlayingPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 13),
            SizedBox(width: 5),
            Text('Story playing', style: TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _LivingSceneVisual extends StatelessWidget {
  const _LivingSceneVisual({
    required this.generated,
    required this.controller,
  });

  final GeneratedScene generated;
  final Animation<double> controller;

  Alignment _characterAlignment(String position) {
    final value = position.toLowerCase();
    final horizontal = value.contains('right')
        ? 0.78
        : value.contains('left')
            ? 0.22
            : 0.50;
    final vertical = value.contains('foreground')
        ? 0.68
        : value.contains('background')
            ? 0.36
            : 0.52;
    return Alignment(
      horizontal * 2 - 1,
      vertical * 2 - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final characters = generated.plan.characters.take(3).toList();
    final actions = generated.plan.actions.take(4).toList();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final phase = controller.value;
        final beatCount = math.max(
          1,
          actions.isNotEmpty ? actions.length : characters.length,
        );
        final beat = (phase * beatCount).floor() % beatCount;
        final beatProgress = (phase * beatCount) % 1.0;
        final focusCharacter = characters.isEmpty
            ? null
            : characters[beat % characters.length];
        final focus = focusCharacter == null
            ? const Alignment(0, 0)
            : _characterAlignment(focusCharacter.position);
        final pulse = math.sin(beatProgress * math.pi).abs();

        return Stack(
          fit: StackFit.expand,
          children: [
            child!,
            if (focusCharacter != null)
              IgnorePointer(
                child: Align(
                  alignment: focus,
                  child: Opacity(
                    opacity: 0.10 + pulse * 0.10,
                    child: Container(
                      width: 210 + pulse * 26,
                      height: 210 + pulse * 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.30),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 24,
              right: 24,
              top: 24,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: 0.82,
                  child: Row(
                    children: [
                      const Icon(Icons.movie_outlined, size: 16),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          focusCharacter?.action.isNotEmpty == true
                              ? focusCharacter!.action
                              : generated.plan.motion,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: Image.memory(
        base64Decode(generated.imageBase64),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const Center(
          child: Text('Generated scene image could not be decoded.'),
        ),
      ),
    );
  }
}
