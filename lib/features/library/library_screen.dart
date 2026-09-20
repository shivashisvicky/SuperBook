import 'package:flutter/material.dart';
import '../../domain/book.dart';
import '../reader/reader_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(28),
              children: [
                Text('SUPERBOOK', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 12),
                Text(
                  'Read the story.\nSee what the book sees.',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 12),
                Text('Your library', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    leading: const Icon(Icons.auto_stories_outlined, size: 40),
                    title: Text(demoBook.title),
                    subtitle: Text(demoBook.author),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ReaderScreen(book: demoBook)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
