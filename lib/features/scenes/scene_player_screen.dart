import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
  bool _loading = false;
  VideoPlayerController? _video;
  late final AnimationController _storyController;
  List<GeneratedMotionFrame> _motionFrames = const [];
  bool _motionLoading = false;

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
      duration: const Duration(milliseconds: 7200),
    )..repeat();
    final cached = _sceneCache.get(_cacheKey);
    _generated = cached;
    if (cached?.hasVideo == true) {
      unawaited(_loadVideo(cached!.videoUrl!));
    }
    final cachedMotion = _sceneCache.getMotion(_cacheKey);
    if (cachedMotion != null && cachedMotion.isNotEmpty) {
      _motionFrames = cachedMotion;
    }
    if (cached != null && cachedMotion == null) {
      unawaited(_prepareMotion(cached));
    } else {
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
    }
  }

  Future<void> _prepareMotion(GeneratedScene generated) async {
    if (_motionLoading || _motionFrames.isNotEmpty || _sceneEndpoint.isEmpty) {
      return;
    }
    final cachedMotion = _sceneCache.getMotion(_cacheKey);
    if (cachedMotion != null && cachedMotion.isNotEmpty) {
      setState(() => _motionFrames = cachedMotion);
      return;
    }
    final provider = CloudflareSceneProvider(endpoint: _sceneEndpoint);
    setState(() => _motionLoading = true);
    try {
      final reference = await _resizeReferenceImage(generated.imageBase64);
      final frames = await provider.generateMotionFrames(
        plan: generated.plan,
        imageBase64: reference,
      );
      if (!mounted) return;
      if (frames.isNotEmpty) {
        _sceneCache.putMotion(_cacheKey, frames);
        _motionFrames = frames;
        setState(() {});
      }
    } catch (_) {
      // Keep the generated still as the reliable fallback.
    } finally {
      if (mounted) setState(() => _motionLoading = false);
    }
  }

  Future<String> _resizeReferenceImage(String imageBase64) async {
    final bytes = base64Decode(imageBase64);
    final codec = await ui.instantiateImageCodec(
      Uint8List.fromList(bytes),
      targetWidth: 500,
      allowUpscaling: false,
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    if (data == null) {
      throw StateError('Could not prepare the scene reference image.');
    }
    return base64Encode(data.buffer.asUint8List());
  }

  Future<void> _generate({bool force = false}) async {
    if (_loading) return;
    if (_sceneEndpoint.isEmpty) return;

    if (force) {
      final oldVideo = _video;
      _video = null;
      _sceneCache.clearMotion(_cacheKey);
      _motionFrames = const [];
      await oldVideo?.dispose();
    }

    setState(() {
      _loading = true;
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
          _motionFrames = const [];
          _loading = false;
        });
        unawaited(_prepareMotion(generated));
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
    if (_motionFrames.isEmpty) {
      return SizedBox.expand(
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
    return _MotionFrameVisual(
      frames: _motionFrames,
      controller: _storyController,
    );
  }

  @override
  Widget build(BuildContext context) {
    final generated = _generated;
    final chapterIndex = widget.book.chapters.indexWhere(
      (chapter) => chapter.id == widget.beat.chapterId,
    );
    final currentIndex = chapterIndex < 0 ? 0 : chapterIndex;
    final hasPrevious = currentIndex > 0;
    final hasNext = currentIndex + 1 < widget.book.chapters.length;

    NarrativeBeat beatFor(Chapter chapter) => widget.book.beats.firstWhere(
          (item) => item.chapterId == chapter.id,
          orElse: () => NarrativeBeat(
            title: chapter.title,
            summary: chapter.passage.first,
            chapterId: chapter.id,
            intensity: 1,
          ),
        );

    void openChapter(int index) {
      if (index < 0 || index >= widget.book.chapters.length) return;
      final chapter = widget.book.chapters[index];
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ScenePlayerScreen(
            book: widget.book,
            scene: chapter.scene,
            beat: beatFor(chapter),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: Text(widget.scene.title)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (generated != null) _visual(generated) else const ColoredBox(color: Color(0xFF05070B)),
          if (generated == null && _loading)
            const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
              SizedBox(height: 14),
              Text('Creating your story moment…', style: TextStyle(fontSize: 16)),
            ])),
          if (generated != null && _motionLoading)
            const Positioned(top: 20, right: 18, child: _MotionBuildingPill()),
          Positioned(
            left: 18, right: 18, bottom: 18,
            child: Card(
              color: const Color(0xE610141C),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('EXPERIENCE · STORY MOMENT', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 5),
                  Text(
                    generated?.plan.sceneSummary ?? widget.scene.caption,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 3,
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
                  const SizedBox(height: 9),
                  Row(children: [
                    Expanded(
                      child: generated == null
                          ? Text('Narrative beat · intensity ${widget.beat.intensity}')
                          : AnimatedBuilder(
                              animation: _storyController,
                              builder: (context, _) {
                                final frames = _motionFrames;
                                if (frames.isEmpty) {
                                  return Text('Narrative beat · intensity ${widget.beat.intensity}');
                                }
                                final index = (frames.length * _storyController.value).floor().clamp(0, frames.length - 1);
                                return AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 450),
                                  child: Text(
                                    frames[index].beat,
                                    key: ValueKey<String>(frames[index].beat),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _loading ? null : () => _generate(force: generated != null),
                      icon: _loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh),
                      label: Text(_loading ? 'Creating…' : 'Regenerate'),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: hasPrevious ? () => openChapter(currentIndex - 1) : null,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Previous'),
                      ),
                      const Spacer(),
                      Text(
                        'Chapter ${currentIndex + 1} of ${widget.book.chapters.length}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: hasNext ? () => openChapter(currentIndex + 1) : null,
                        icon: const Icon(Icons.chevron_right),
                        label: Text(hasNext ? 'Next' : 'End'),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MotionBuildingPill extends StatelessWidget {
  const _MotionBuildingPill();
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xCC10141C),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white24),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
        SizedBox(width: 7),
        Text('Bringing the scene to life', style: TextStyle(fontSize: 11)),
      ]),
    ),
  );
}

class _MotionFrameVisual extends StatelessWidget {
  const _MotionFrameVisual({required this.frames, required this.controller});
  final List<GeneratedMotionFrame> frames;
  final Animation<double> controller;
  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final index = (frames.length * controller.value).floor().clamp(0, frames.length - 1);
        final frame = frames[index];
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 900),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            fit: StackFit.expand,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: Image.memory(
            base64Decode(frame.base64),
            key: ValueKey<String>(frame.base64),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        );
      },
    ),
  );
}
