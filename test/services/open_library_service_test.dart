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

  test('Open Library discovery promotes known Gutenberg identity to first-class source', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'openlibrary.org');
      return http.Response(
        jsonEncode({
          'docs': [
            {
              'key': '/works/OL66554W',
              'title': 'Pride and Prejudice',
              'author_name': ['Jane Austen'],
              'ia': ['prideprejudice_finnish_gut'],
              'cover_i': 1342,
              'ebook_access': 'public',
              'editions': {
                'docs': [
                  {
                    'language': ['fin'],
                    'identifiers': {
                      'project_gutenberg': ['45186'],
                    },
                  },
                ],
              },
            },
          ],
        }),
        200,
        headers: const {'content-type': 'application/json'},
      );
    });

    final service = OpenLibraryService(client: client);
    final books = await service.search('Pride and Prejudice');

    expect(books, hasLength(1));
    expect(books.first.gutenbergId, 1342);
    expect(books.first.archiveIds, contains('prideprejudice_finnish_gut'));
  });

  test('known Gutenberg source wins over an Internet Archive edition', () async {
    const text = '''
*** START OF THE PROJECT GUTENBERG EBOOK PRIDE AND PREJUDICE ***

CONTENTS
Chapter I
Chapter II

Chapter I
It is a truth universally acknowledged that a single man in possession of a good fortune must be in want of a wife. The Bennet family discusses the arrival of a wealthy neighbour, and the chapter continues with several complete sentences of genuine story prose.

Chapter II
Mr. Bennet receives the visitors and continues the story with substantive prose. The family discusses the recent events and the neighbourhood for several complete sentences before the chapter ends. The conversation continues with another complete thought so this remains a substantive chapter boundary rather than a short contents marker.

*** END OF THE PROJECT GUTENBERG EBOOK PRIDE AND PREJUDICE ***
''';

    final client = MockClient((request) async {
      if (request.url.host == 'www.gutenberg.org') {
        expect(request.url.path, '/cache/epub/1342/pg1342.txt');
        return http.Response(text, 200);
      }
      if (request.url.host == 'archive.org') {
        fail('Internet Archive must not be consulted when Gutenberg identity is known.');
      }
      return http.Response('not found', 404);
    });

    final service = OpenLibraryService(client: client);
    const summary = LibraryBookSummary(
      id: 'openlibrary-OL66554W',
      title: 'Pride and Prejudice',
      author: 'Jane Austen',
      downloadCount: 0,
      coverUrl: null,
      archiveIds: ['prideprejudice_finnish_gut'],
      gutenbergId: 1342,
    );

    final book = await service.loadBook(summary);

    expect(book.id, 'gutenberg-1342');
    expect(book.title, 'Pride and Prejudice');
    expect(book.author, 'Jane Austen');
    expect(book.chapters, hasLength(2));
    expect(book.chapters.first.title, 'Chapter I');
    expect(book.chapters.first.passage.first, contains('truth universally acknowledged'));
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
    expect(book.chapters.first.title, 'Chapter I');
    expect(book.chapters.first.passage.first, contains('Holmes examined the note'));
  });

  test('curated classic catalog keeps canonical Gutenberg IDs first-class', () async {
    final client = MockClient((request) async => http.Response('offline', 503));
    final service = OpenLibraryService(client: client);

    final books = await service.popularBooks();
    final ids = {
      for (final book in books)
        if (book.gutenbergId != null) book.title: book.gutenbergId,
    };

    expect(ids['Pride and Prejudice'], 1342);
    expect(ids['The Adventures of Sherlock Holmes'], 1661);
    expect(ids['Moby Dick; Or, The Whale'], 2701);
    expect(ids['Frankenstein; or, the Modern Prometheus'], 84);
    expect(ids['Dracula'], 345);
    expect(ids['Great Expectations'], 1400);
    expect(ids['The Picture of Dorian Gray'], 174);
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
