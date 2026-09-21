import 'package:flutter/material.dart';
import '../../domain/book.dart';

class ScenesScreen extends StatelessWidget {
  const ScenesScreen({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text('EXPERIENCE', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Text('Story moments', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Cinematic moments stay anchored to narrative beats. They never replace the book.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        for (final beat in book.beats) ...[
          _SceneCard(book: book, beat: beat),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.book, required this.beat});

  final Book book;
  final NarrativeBeat beat;

  @override
  Widget build(BuildContext context) {
    final chapter = book.chapters.firstWhere((c) => c.id == beat.chapterId);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chapter.scene.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text(chapter.scene.caption, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 16),
                Text('Moment: \${chapter.scene.moment}'),
                Text('Atmosphere: \${chapter.scene.atmosphere}'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Enter scene'),
                ),
              ],
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: const Icon(Icons.movie_creation_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(beat.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(chapter.title),
                    const SizedBox(height: 6),
                    Text(beat.summary),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('L\${beat.intensity}', style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
