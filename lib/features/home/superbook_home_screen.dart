import 'package:flutter/material.dart';
import '../../domain/book.dart';
import '../reader/reader_screen.dart';

class SuperBookHomeScreen extends StatelessWidget {
  const SuperBookHomeScreen({super.key, required this.onOpenLibrary});

  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        Text('SUPERBOOK', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(
          'Read the story.\nSee what the book sees.',
          style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 28),
        Text('Continue reading', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        _ContinueCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReaderScreen(book: demoBook)),
          ),
        ),
        const SizedBox(height: 28),
        Text('Your world', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MetricCard(value: demoBook.chapters.length.toString(), label: 'Chapters')),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(value: demoBook.characters.length.toString(), label: 'Characters')),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(value: demoBook.beats.length.toString(), label: 'Scenes')),
          ],
        ),
        const SizedBox(height: 28),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A story, not a file', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'SuperBook keeps the book, its narrative structure, and its experience layer connected.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: onOpenLibrary,
                  icon: const Icon(Icons.auto_stories_outlined),
                  label: const Text('Open library'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4A5568), Color(0xFF1A202C)],
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.auto_stories, size: 30),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('The Little House', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    Text('The Old House · Chapter 1'),
                    SizedBox(height: 12),
                    LinearProgressIndicator(value: 0.34),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.play_arrow_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
