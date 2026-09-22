import 'package:flutter/material.dart';

import '../../services/current_book_store.dart';
import '../../services/open_library_service.dart';
import '../reader/reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  final _service = OpenLibraryService();
  late Future<List<LibraryBookSummary>> _books;
  String _query = '';
  String? _loadingId;

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

  Future<void> _openBook(LibraryBookSummary summary) async {
    setState(() => _loadingId = summary.id);
    try {
      final book = await _service.loadBook(summary);
      await CurrentBookStore.instance.setCurrent(
        summary: summary,
        book: book,
      );
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
    return FutureBuilder<List<LibraryBookSummary>>(
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
                  tooltip: 'Search books',
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
                      const Text('The book catalog is unavailable right now.'),
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
                child: Center(child: Text('No public-domain books match that search.')),
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
              _query.isEmpty ? 'Popular public-domain books' : 'Search results',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'The catalog comes from Open Library. Public-domain text is loaded from trusted open-book sources, with a local classic-book fallback if a catalog service is unavailable.',
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

  final LibraryBookSummary book;
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
