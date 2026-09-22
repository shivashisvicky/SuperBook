import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:superbook/services/open_library_service.dart';

void main() {
  test('Open Library catalog returns readable public books', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'openlibrary.org');
      return http.Response(
        jsonEncode({
          'docs': [
            {
              'key': '/works/OL123W',
              'title': 'The Adventures of Sherlock Holmes',
              'author_name': ['Arthur Conan Doyle'],
              'cover_i': 123,
              'ebook_access': 'public',
              'ia': ['the_adventures_of_sherlock_holmes_gut'],
            },
          ],
        }),
        200,
        headers: const {'content-type': 'application/json'},
      );
    });

    final service = OpenLibraryService(client: client);
    final books = await service.popularBooks();

    expect(books, hasLength(1));
    expect(books.first.title, 'The Adventures of Sherlock Holmes');
    expect(books.first.author, 'Arthur Conan Doyle');
    expect(books.first.archiveIds, contains('the_adventures_of_sherlock_holmes_gut'));
  });

  test('Open Library book loads plain text from Internet Archive', () async {
    const text = '''
*** START OF THE PROJECT GUTENBERG EBOOK TEST ***

CHAPTER I
This is a real chapter with enough prose to establish a readable section.
Holmes examined the note carefully while Watson watched from the window.
The investigation continued through several complete sentences.

*** END OF THE PROJECT GUTENBERG EBOOK TEST ***
''';

    final client = MockClient((request) async {
      if (request.url.host == 'archive.org' &&
          request.url.path == '/metadata/test-gut') {
        return http.Response(
          jsonEncode({
            'files': [
              {'name': 'test-gut_djvu.txt', 'format': 'Text PDF'},
            ],
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }
      if (request.url.host == 'archive.org' &&
          request.url.path == '/download/test-gut/test-gut_djvu.txt') {
        return http.Response(text, 200);
      }
      return http.Response('not found', 404);
    });

    final service = OpenLibraryService(client: client);
    const summary = LibraryBookSummary(
      id: 'openlibrary-OL123W',
      title: 'Test Holmes',
      author: 'Arthur Conan Doyle',
      downloadCount: 0,
      coverUrl: null,
      archiveIds: ['test-gut'],
    );

    final book = await service.loadBook(summary);

    expect(book.title, 'Test Holmes');
    expect(book.chapters, hasLength(1));
    expect(book.chapters.first.title, 'Chapter 1');
    expect(book.chapters.first.passage.first, contains('Holmes examined the note'));
  });

  test('popular books fall back to local classics when catalog is unavailable', () async {
    final client = MockClient((request) async => http.Response('offline', 503));
    final service = OpenLibraryService(client: client);

    final books = await service.popularBooks();

    expect(books.length, greaterThanOrEqualTo(6));
    expect(
      books.map((book) => book.title),
      contains('The Adventures of Sherlock Holmes'),
    );
    expect(books.map((book) => book.title), contains('Pride and Prejudice'));
  });
}
