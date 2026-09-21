import 'package:flutter/material.dart';

import '../../services/gutenberg_service.dart';
import '../reader/reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  final _service = GutenbergService();
  late Future<List<GutenbergBookSummary>> _books;
  String _query = '';
  int? _loadingId;

  @override
  void initState() {
    super.initState();
    _books = _service.popularBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text.trim();
    setState(() {
      _query = query;
      _books = query.isEmpty ? _service.popularBooks() : _service.search(query);
    });
  }

  Future<void> _openBook(GutenbergBookSummary summary) async {
    setState(() => _loadingId = summary.id);
    try {
      final book = await _service.loadBook(summary);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReaderScreen(book: book)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<GutenbergBookSummary>>(
      future: _books,
      builder: (context, snapshot) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text('LIBRARY', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Text('Real books', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Public-domain stories from Project Gutenberg. Tap a book to download its original text into the reader.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search authors or titles',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Search Gutenberg',
                  onPressed: _search,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (snapshot.hasError)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 36),
                      const SizedBox(height: 12),
                      const Text('Gutenberg is unavailable right now.'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _search,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              )
            else if (snapshot.data?.isEmpty ?? true)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No Gutenberg books match that search.')),
              )
            else
              ...snapshot.data!.take(12).map(
                    (book) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BookCard(
                        book: book,
                        loading: _loadingId == book.id,
                        onTap: () => _openBook(book),
                      ),
                    ),
                  ),
            const SizedBox(height: 12),
            Text(
              _query.isEmpty ? 'Popular on Gutenberg' : 'Search results',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'The catalog is real. The text is the original Gutenberg edition. SuperBook’s narrative and scene layers will be built on top of it.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.loading,
    required this.onTap,
  });

  final GutenbergBookSummary book;
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 88,
                child: book.coverUrl == null
                    ? const ColoredBox(
                        color: Color(0xFF252536),
                        child: Icon(Icons.auto_stories_outlined),
                      )
                    : Image.network(
                        book.coverUrl!,
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
                    Text(book.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(book.author),
                    const SizedBox(height: 8),
                    Text(
                      '${book.downloadCount} recent downloads',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
            ],
          ),
        ),
      ),
    );
  }
}
