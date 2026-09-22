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
  bool _detailsExpanded = false;

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
      duration: const Duration(milliseconds: 5400),
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

    final sectionKind = widget.scene.title.toLowerCase().startsWith('chapter') ? 'Chapter' : 'Section';
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('$sectionKind ${currentIndex + 1}'),
        foregroundColor: Colors.white,
      ),
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
            left: 14,
            right: 14,
            bottom: 14,
            child: SafeArea(
              top: false,
              child: _StoryMomentOverlay(
                expanded: _detailsExpanded,
                title: widget.scene.title,
                summary: generated?.plan.sceneSummary ?? widget.scene.caption,
                location: generated?.plan.environment.location ?? widget.scene.atmosphere,
                motionBeat: _motionFrames.isEmpty ? null : _motionFrames.first.beat,
                currentIndex: currentIndex,
                total: widget.book.chapters.length,
                hasPrevious: hasPrevious,
                hasNext: hasNext,
                loading: _loading,
                onToggle: () => setState(() => _detailsExpanded = !_detailsExpanded),
                onRegenerate: () => _generate(force: generated != null),
                onPrevious: hasPrevious ? () => openChapter(currentIndex - 1) : null,
                onNext: hasNext ? () => openChapter(currentIndex + 1) : null,
              ),
            ),
          ),

        ],
      ),
    );
  }
}

class _StoryMomentOverlay extends StatelessWidget {
  const _StoryMomentOverlay({
    required this.expanded,
    required this.title,
    required this.summary,
    required this.location,
    required this.motionBeat,
    required this.currentIndex,
    required this.total,
    required this.hasPrevious,
    required this.hasNext,
    required this.loading,
    required this.onToggle,
    required this.onRegenerate,
    required this.onPrevious,
    required this.onNext,
  });

  final bool expanded;
  final String title;
  final String summary;
  final String location;
  final String? motionBeat;
  final int currentIndex;
  final int total;
  final bool hasPrevious;
  final bool hasNext;
  final bool loading;
  final VoidCallback onToggle;
  final VoidCallback onRegenerate;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: Material(
        color: const Color(0xD90A0D13),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onToggle,
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, expanded ? 13 : 9, 10, 9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_motion, size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        motionBeat == null ? 'Story moment' : 'Story moment · animated',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (motionBeat != null)
                      const Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: _LiveDot(),
                      ),
                    IconButton(
                      tooltip: expanded ? 'Hide story details' : 'Show story details',
                      visualDensity: VisualDensity.compact,
                      onPressed: onToggle,
                      icon: Icon(expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up),
                    ),
                  ],
                ),
                if (expanded) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      summary,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      location,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous section',
                      visualDensity: VisualDensity.compact,
                      onPressed: onPrevious,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${currentIndex + 1} / $total',
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Regenerate scene',
                      visualDensity: VisualDensity.compact,
                      onPressed: loading ? null : onRegenerate,
                      icon: loading
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                    ),
                    IconButton(
                      tooltip: hasNext ? 'Next section' : 'End',
                      visualDensity: VisualDensity.compact,
                      onPressed: onNext,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: const BoxDecoration(
      color: Color(0xFFB8F2C2),
      shape: BoxShape.circle,
    ),
  );
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
          duration: const Duration(milliseconds: 700),
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
