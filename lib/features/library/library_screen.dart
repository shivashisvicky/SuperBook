import 'package:flutter/material.dart';
import '../../domain/book.dart';
import '../reader/reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final controller = TextEditingController();

  bool get matches {
    final query = controller.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return demoBook.title.toLowerCase().contains(query) ||
        demoBook.author.toLowerCase().contains(query);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text('LIBRARY', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Text('Your books', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search your library',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        if (matches)
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReaderScreen(book: demoBook)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 76,
                          height: 104,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF4A5568), Color(0xFF1A202C)],
                            ),
                          ),
                          child: const Icon(Icons.auto_stories, size: 34),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(demoBook.title, style: theme.textTheme.headlineSmall),
                              const SizedBox(height: 4),
                              Text(demoBook.author),
                              const SizedBox(height: 12),
                              Text(demoBook.description),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const LinearProgressIndicator(value: 0.34),
                    const SizedBox(height: 8),
                    Text(
                      '34% · ${demoBook.chapters.first.title}',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No books match that search.')),
          ),
        const SizedBox(height: 28),
        Text('Inside this book', style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text('${demoBook.chapters.length} chapters'),
                subtitle: const Text('Read and resume from the narrative boundary.'),
              ),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: Text('${demoBook.characters.length} characters'),
                subtitle: const Text('Explore who is present in the story.'),
              ),
              ListTile(
                leading: const Icon(Icons.movie_outlined),
                title: Text('${demoBook.beats.length} narrative moments'),
                subtitle: const Text('Experience scenes tied to meaningful beats.'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
