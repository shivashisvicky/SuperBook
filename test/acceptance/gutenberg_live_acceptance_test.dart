import 'package:flutter_test/flutter_test.dart';
import 'package:superbook/services/gutenberg_service.dart';

void main() {
  const books = <({int id, String title, String author, int sections, String first})>[
    (id: 1342, title: 'Pride and Prejudice', author: 'Jane Austen', sections: 61, first: 'It is a truth universally acknowledged'),
    (id: 1661, title: 'The Adventures of Sherlock Holmes', author: 'Arthur Conan Doyle', sections: 12, first: 'I had called upon my friend, Mr. Sherlock Holmes'),
    (id: 2701, title: 'Moby Dick; Or, The Whale', author: 'Herman Melville', sections: 135, first: 'Call me Ishmael'),
    (id: 84, title: 'Frankenstein; or, the Modern Prometheus', author: 'Mary Wollstonecraft Shelley', sections: 24, first: 'I am by birth a Genevese'),
    (id: 345, title: 'Dracula', author: 'Bram Stoker', sections: 27, first: '3 May, Bistritz'),
    (id: 1400, title: 'Great Expectations', author: 'Charles Dickens', sections: 59, first: 'My father'),
    (id: 174, title: 'The Picture of Dorian Gray', author: 'Oscar Wilde', sections: 20, first: 'The studio was filled with the rich odour of roses'),
  ];

  test(
    'canonical Gutenberg books load with clean literary structure',
    () async {
      for (final expected in books) {
        final service = GutenbergService();
        final book = await service.loadBook(
          GutenbergBookSummary(
            id: expected.id,
            title: expected.title,
            author: expected.author,
            downloadCount: 0,
            coverUrl: null,
          ),
        );

        expect(book.id, 'gutenberg-${expected.id}');
        expect(book.title, expected.title);
        expect(book.author, expected.author);
        expect(book.chapters, hasLength(expected.sections));
        expect(book.chapters.first.passage.first, contains(expected.first));

        final allText = book.chapters.expand((chapter) => chapter.passage).join(' ');
        expect(allText, isNot(contains('\uFFFD')));
        expect(allText, isNot(contains('*** END OF THE PROJECT GUTENBERG EBOOK')));
        expect(allText, isNot(contains('1.F.2. LIMITED WARRANTY')));
        expect(allText, isNot(contains('PLEASE READ THIS BEFORE YOU DISTRIBUTE')));
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}