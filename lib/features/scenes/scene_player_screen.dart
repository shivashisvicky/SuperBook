import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../domain/book.dart';
import '../../core/utils/text_sanitizer.dart';
import '../../domain/experience/ai_scene_plan.dart';
import '../../domain/experience/superbook_scene_graph.dart';
import '../../services/scene_generation/cloudflare_scene_provider.dart';
import '../../services/scene_generation/scene_generation_cache.dart';
import '../../services/scene_generation/scene_generation_provider.dart';
import 'superbook_local_animation_stage.dart';

const _sceneEndpoint = String.fromEnvironment('SUPERBOOK_AI_SCENE_ENDPOINT');
final _sceneCache = SceneGenerationCache();
// Cloudflare scene generation is optional. Once unavailable, chapters use the local renderer.
bool _remoteGenerationDisabled = false;

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

class _ScenePlayerScreenState extends State<ScenePlayerScreen> {
  GeneratedScene? _generated;
  bool _loading = false;
  VideoPlayerController? _video;
  bool _detailsExpanded = false;
  String? _generationError;
  bool _useLocalAnimation = false;

  Chapter get _chapter => widget.book.chapters.firstWhere(
        (chapter) => chapter.id == widget.beat.chapterId,
      );

  String get _cacheKey => _sceneCache.key(
        bookId: widget.book.id,
        chapterId: widget.beat.chapterId,
        passage: _chapter.passage.join('\n'),
        beatTitle: widget.beat.title,
        beatSummary: widget.beat.summary,
      );

  @override
  void initState() {
    super.initState();
    final cached = _sceneCache.get(_cacheKey);
    _generated = cached;
    if (cached?.hasVideo == true) {
      unawaited(_loadVideo(cached!.videoUrl!));
    }
    if (cached != null) {
      unawaited(_prefetchNextChapter());
    } else if (_remoteGenerationDisabled) {
      _useLocalAnimation = true;
      unawaited(_prefetchNextChapter());
    } else {
      unawaited(_generate());
    }
  }

  @override
  void dispose() {
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
    } catch (_) {
      await controller.dispose();
    }
  }

  Future<void> _generate({bool force = false}) async {
    if (_loading) return;

    if (_remoteGenerationDisabled || _sceneEndpoint.isEmpty) {
      if (mounted) setState(() => _useLocalAnimation = true);
      return;
    }

    if (_sceneEndpoint.isEmpty) {
      if (mounted) setState(() => _useLocalAnimation = true);
      return;
    }

    if (force) {
      final oldVideo = _video;
      _video = null;
      await oldVideo?.dispose();
      if (mounted) {
      }
    }

    setState(() {
      _loading = true;
      _generationError = null;
    });

    try {
      final cached = _sceneCache.get(_cacheKey);
      if (cached != null && !force) {
        setState(() => _generated = cached);
        return;
      }

      final provider = CloudflareSceneProvider(endpoint: _sceneEndpoint);
      final generated = await provider.generate(
        bookId: widget.book.id,
        chapterId: widget.beat.chapterId,
        passage: _chapter.passage.take(6).join('\n'),
        author: widget.book.author,
        title: widget.book.title,
        beatTitle: widget.beat.title,
        beatSummary: widget.beat.summary,
      ).timeout(const Duration(milliseconds: 4500));
      _sceneCache.put(_cacheKey, generated);
      if (!mounted) return;
      setState(() {
        _generated = generated;
        _loading = false;
        _generationError = null;
      });
      unawaited(_prefetchNextChapter());

    } catch (error) {
      _remoteGenerationDisabled = true;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _useLocalAnimation = true;
        _generationError = null;
      });
      unawaited(_prefetchNextChapter());
    } finally {
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    }
  }

  AiScenePlan get _emptyScenePlan => const AiScenePlan(
        schemaVersion: '1',
        sceneSummary: '',
        visualStyle: '',
        characters: [],
        environment: AiSceneEnvironment(location: '', time: '', description: ''),
        props: [],
        actions: [],
        camera: AiSceneCamera(shot: 'wide', angle: 'eye level', movement: ''),
        lighting: '',
        motion: '',
        imagePrompt: '',
      );

  Future<void> _prefetchNextChapter() async {
    if (_remoteGenerationDisabled || _sceneEndpoint.isEmpty) return;
    final currentIndex = widget.book.chapters.indexWhere(
      (chapter) => chapter.id == widget.beat.chapterId,
    );
    final nextIndex = currentIndex + 1;
    if (currentIndex < 0 || nextIndex >= widget.book.chapters.length) return;

    final nextChapter = widget.book.chapters[nextIndex];
    final nextBeat = widget.book.beats.firstWhere(
      (beat) => beat.chapterId == nextChapter.id,
      orElse: () => NarrativeBeat(
        title: nextChapter.title,
        summary: nextChapter.passage.isEmpty ? nextChapter.title : nextChapter.passage.first,
        chapterId: nextChapter.id,
        intensity: 1,
      ),
    );
    final key = _sceneCache.key(
      bookId: widget.book.id,
      chapterId: nextChapter.id,
      passage: nextChapter.passage.join('\n'),
      beatTitle: nextBeat.title,
      beatSummary: nextBeat.summary,
    );
    if (_sceneCache.get(key) != null || _remoteGenerationDisabled) return;

    try {
      final generated = await CloudflareSceneProvider(endpoint: _sceneEndpoint)
          .generate(
            bookId: widget.book.id,
            chapterId: nextChapter.id,
            passage: nextChapter.passage.take(6).join('\n'),
            author: widget.book.author,
            title: widget.book.title,
            beatTitle: nextBeat.title,
            beatSummary: nextBeat.summary,
          )
          .timeout(const Duration(seconds: 5));
      if (!_remoteGenerationDisabled) {
        _sceneCache.put(key, generated);
      }
    } catch (_) {
      _remoteGenerationDisabled = true;
    }
  }

  String _resolvedLocation(GeneratedScene? generated) {
    final generatedLocation = generated?.plan.environment.location.trim() ?? '';
    if (generatedLocation.isNotEmpty &&
        !generatedLocation.toLowerCase().contains('current family and social moment')) {
      return generatedLocation;
    }
    final graph = SuperBookSceneGraph.from(
      plan: generated?.plan ?? _emptyScenePlan,
      scene: widget.scene,
      bookCharacters: widget.book.characters,
      passage: _chapter.passage,
      narrativeFocus: widget.beat.summary,
    );
    return graph.environment;
  }

  Widget _visualLocal() => SuperBookLocalAnimationStage(
        scene: widget.scene,
        passage: _chapter.passage,
        characters: widget.book.characters,
        actionHint: '${_generated?.plan.sceneSummary ?? ''} ${_generated?.plan.motion ?? ''} ${_generated?.plan.actions.join(' ') ?? ''} ${_generated?.plan.characters.map((c) => c.action).join(' ') ?? ''}',
        scenePlan: _generated?.plan,
        narrativeFocus: widget.beat.summary,
      );

  Widget _visual(GeneratedScene generated) {
    if (_useLocalAnimation) {
      return SuperBookLocalAnimationStage(
        scene: widget.scene,
        passage: _chapter.passage,
        characters: widget.book.characters,
        actionHint: '${generated.plan.sceneSummary} ${generated.plan.motion} ${generated.plan.actions.join(' ')} ${generated.plan.characters.map((c) => c.action).join(' ')}',
        scenePlan: generated.plan,
        narrativeFocus: widget.beat.summary,
      );
    }

    // The Experience Player is now a unified illustrated stage. The AI still
    // remains available as generation output, but is never composited beneath
    // the articulated actors.
    return SuperBookLocalAnimationStage(
      scene: widget.scene,
      passage: _chapter.passage,
      characters: widget.book.characters,
      actionHint: [
        generated.plan.sceneSummary,
        generated.plan.motion,
        ...generated.plan.actions,
        ...generated.plan.characters.map((c) => c.action),
      ].join(' '),
      scenePlan: generated.plan,
      narrativeFocus: widget.beat.summary,
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

    final sectionKind =
        widget.scene.title.toLowerCase().startsWith('chapter')
            ? 'Chapter'
            : 'Section';

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
          // Render the local scene immediately while AI generation runs.
          if (generated != null)
            _visual(generated)
          else
            _visualLocal(),
          if (generated == null && !_loading && _generationError != null && !_useLocalAnimation)
            Positioned(
              left: 24,
              right: 24,
              top: 110,
              child: _SceneGenerationError(
                message: _generationError!,
                onRetry: () => _generate(force: true),
              ),
            ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: SafeArea(
              top: false,
              child: _StoryMomentOverlay(
                expanded: _detailsExpanded,
                title: 'Story moment',
                summary:
                    generated?.plan.sceneSummary ?? widget.scene.caption,
                location: _resolvedLocation(generated),
                currentIndex: currentIndex,
                total: widget.book.chapters.length,
                hasPrevious: hasPrevious,
                hasNext: hasNext,
                loading: _loading,
                onToggle: () =>
                    setState(() => _detailsExpanded = !_detailsExpanded),
                onRegenerate: () => _generate(force: generated != null),
                onPrevious: hasPrevious
                    ? () => openChapter(currentIndex - 1)
                    : null,
                onNext:
                    hasNext ? () => openChapter(currentIndex + 1) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneGenerationError extends StatelessWidget {
  const _SceneGenerationError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xE60A0D13),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Retry scene generation',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      );
}

class _StoryMomentOverlay extends StatelessWidget {
  const _StoryMomentOverlay({
    required this.expanded,
    required this.title,
    required this.summary,
    required this.location,
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
    final sanitizedSummary = summary.cleanOcr();
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
                        title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: expanded
                          ? 'Hide story details'
                          : 'Show story details',
                      visualDensity: VisualDensity.compact,
                      onPressed: onToggle,
                      icon: Icon(
                        expanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                      ),
                    ),
                  ],
                ),
                if (expanded) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      sanitizedSummary,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (location.trim().isNotEmpty &&
                      location != 'Narrative setting not specified')
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        location,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
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
