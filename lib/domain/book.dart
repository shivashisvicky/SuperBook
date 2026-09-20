class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.chapters,
  });

  final String id;
  final String title;
  final String author;
  final String description;
  final List<Chapter> chapters;
}

class Chapter {
  const Chapter({
    required this.id,
    required this.title,
    required this.passage,
  });

  final String id;
  final String title;
  final List<String> passage;
}

const demoBook = Book(
  id: 'the-little-house',
  title: 'The Little House',
  author: 'SuperBook Demo',
  description: 'A deterministic book fixture for the first clean reader slice.',
  chapters: [
    Chapter(
      id: 'chapter-1',
      title: 'The Old House',
      passage: [
        'The wind moved through the trees as the traveler approached the old house.',
        'A single lamp burned behind the window. The path was quiet, but the door stood open.',
        'He paused at the gate, listening to the leaves and the distant sound of rain.',
      ],
    ),
  ],
);
