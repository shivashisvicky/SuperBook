import 'package:flutter/material.dart';

import '../../domain/book.dart';

import '../../services/current_book_store.dart';
import '../../services/open_library_service.dart';
import '../reader/reader_screen.dart';

class SuperBookHomeScreen extends StatefulWidget {
  const SuperBookHomeScreen({super.key, required this.onOpenLibrary});

  final VoidCallback onOpenLibrary;

  @override
  State<SuperBookHomeScreen> createState() => _SuperBookHomeScreenState();
}

class _SuperBookHomeScreenState extends State<SuperBookHomeScreen> {
  final _store = CurrentBookStore.instance;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _store.restore();
  }

  Future<void> _openCurrent() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final book = await _store.loadCurrent();
      if (!mounted) return;
      if (book == null) {
        widget.onOpenLibrary();
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReaderScreen(book: book)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<LibraryBookSummary?>(
      valueListenable: _store.currentSummary,
      builder: (context, summary, _) {
        return ValueListenableBuilder<Book?>(
          valueListenable: _store.currentBook,
          builder: (context, book, __) {
            final chapterIndex = _store.currentChapterIndex.value;
            final hasCurrent = summary != null;
            final chapterCount = book?.chapters.length;
            final chapterTitle = book == null || book.chapters.isEmpty
                ? 'Reader ready'
                : book.chapters[
                    chapterIndex.clamp(0, book.chapters.length - 1)
                  ].title;

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              children: [
                Text('SUPERBOOK', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Text(
                  'Read the story.\nSee what the book sees.',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                Text('Continue reading', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                if (!hasCurrent)
                  _EmptyContinueCard(onTap: widget.onOpenLibrary)
                else
                  _ContinueCard(
                    summary: summary,
                    chapterTitle: chapterTitle,
                    loading: _opening,
                    onTap: _openCurrent,
                  ),
                const SizedBox(height: 28),
                Text('Your book', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        value: chapterCount?.toString() ?? '—',
                        label: 'Sections',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        value: book?.beats.length.toString() ?? '—',
                        label: 'Scenes',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasCurrent
                              ? 'Your real book is now the Home source'
                              : 'Open a real book',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasCurrent
                              ? 'SuperBook keeps the selected book as the current reading context. It will remain here after you leave the reader.'
                              : 'Choose a public-domain book from the Library. SuperBook will remember the last book you opened.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: widget.onOpenLibrary,
                          icon: const Icon(Icons.auto_stories_outlined),
                          label: const Text('Open library'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.summary,
    required this.chapterTitle,
    required this.loading,
    required this.onTap,
  });

  final LibraryBookSummary summary;
  final String chapterTitle;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: loading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 88,
                child: summary.coverUrl == null
                    ? const ColoredBox(
                        color: Color(0xFF252536),
                        child: Icon(Icons.auto_stories_outlined),
                      )
                    : Image.network(
                        summary.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Color(0xFF252536),
                          child: Icon(Icons.auto_stories_outlined),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(summary.author),
                    const SizedBox(height: 8),
                    Text(chapterTitle, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 12),
                    loading
                        ? const LinearProgressIndicator()
                        : LinearProgressIndicator(
                            value: chapterTitle == 'Reader ready'
                                ? 0
                                : null,
                          ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyContinueCard extends StatelessWidget {
  const _EmptyContinueCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 88,
                child: ColoredBox(
                  color: Color(0xFF252536),
                  child: Icon(Icons.auto_stories_outlined, size: 30),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'No book is open yet. Pick one from the Library to make it your current story.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_rounded),
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
