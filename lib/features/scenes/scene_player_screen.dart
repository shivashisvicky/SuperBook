import 'dart:convert';

import 'package:flutter/material.dart';

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
  late final AnimationController _motion;
  GeneratedScene? _generated;
  String? _error;
  bool _loading = false;

  Chapter get _chapter =>
      widget.book.chapters.firstWhere((chapter) => chapter.id == widget.beat.chapterId);

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
    final key = _sceneCache.key(
      bookId: widget.book.id,
      chapterId: widget.beat.chapterId,
      passage: _chapter.passage.join('\n'),
    );
    _generated = _sceneCache.get(key);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_loading) return;
    if (_sceneEndpoint.isEmpty) {
      setState(() {
        _error = 'AI scene generation is not configured for this build yet.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final key = _sceneCache.key(
        bookId: widget.book.id,
        chapterId: widget.beat.chapterId,
        passage: _chapter.passage.join('\n'),
      );
      final cached = _sceneCache.get(key);
      if (cached != null) {
        setState(() => _generated = cached);
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
      _sceneCache.put(key, generated);
      if (mounted) setState(() => _generated = generated);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            AnimatedBuilder(
              animation: _motion,
              builder: (context, _) {
                final scale = 1.0 + (_motion.value * 0.045);
                final shift = (_motion.value - 0.5) * 10;
                return ClipRect(
                  child: Transform.translate(
                    offset: Offset(shift, shift * 0.35),
                    child: Transform.scale(
                      scale: scale,
                      child: Image.memory(
                        base64Decode(generated.imageBase64),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text('Generated scene image could not be decoded.'),
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
          else
            const ColoredBox(color: Color(0xFF05070B)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.82),
                  ],
                  stops: const [0, 0.48, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Card(
              color: const Color(0xE610141C),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EXPERIENCE',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 5),
                    Text(
                      generated?.plan.sceneSummary ?? widget.scene.caption,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (generated != null) ...[
                      Text(generated.plan.environment.location),
                      const SizedBox(height: 4),
                      Text(
                        generated.plan.visualStyle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ] else
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Narrative beat · intensity ${widget.beat.intensity}',
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _loading ? null : _generate,
                          icon: _loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  generated == null
                                      ? Icons.auto_awesome
                                      : Icons.refresh,
                                ),
                          label: Text(
                            _loading
                                ? 'Generating…'
                                : generated == null
                                    ? 'Generate scene'
                                    : 'Regenerate',
                          ),
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
