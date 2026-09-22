import 'package:flutter/material.dart';
import 'domain/book.dart';
import 'services/current_book_store.dart';
import 'features/explore/explore_screen.dart';
import 'features/home/superbook_home_screen.dart';
import 'features/library/library_screen.dart';
import 'features/reader/reader_screen.dart';
import 'features/scenes/scenes_screen.dart';
import 'features/settings/settings_screen.dart';

class SuperBookApp extends StatelessWidget {
  const SuperBookApp({super.key});

  Book? _currentBook;
  final _store = CurrentBookStore.instance;

  @override
  void initState() {
    super.initState();
    _store.currentBook.addListener(_onCurrentBookChanged);
    _store.restore().then((_) async {
      final book = await _store.loadCurrent();
      if (mounted) setState(() => _currentBook = book);
    });
  }

  void _onCurrentBookChanged() {
    if (mounted) setState(() => _currentBook = _store.currentBook.value);
  }

  @override
  void dispose() {
    _store.currentBook.removeListener(_onCurrentBookChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuperBook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF7C83FD),
      ),
      home: const _SuperBookShell(),
    );
  }
}

class _SuperBookShell extends StatefulWidget {
  const _SuperBookShell();

  @override
  State<_SuperBookShell> createState() => _SuperBookShellState();
}

class _SuperBookShellState extends State<_SuperBookShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      SuperBookHomeScreen(onOpenLibrary: () => setState(() => index = 1)),
      const LibraryScreen(),
      ExploreScreen(book: _currentBook ?? demoBook),
      ScenesScreen(book: _currentBook ?? demoBook),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SuperBook'),
        actions: [
          IconButton(
            tooltip: 'Open current book',
            onPressed: (index == 2 || index == 3) && _currentBook != null
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ReaderScreen(book: _currentBook!)),
                    )
                : null,
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      body: IndexedStack(index: index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.travel_explore_outlined), selectedIcon: Icon(Icons.travel_explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.movie_outlined), selectedIcon: Icon(Icons.movie), label: 'Experience'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
