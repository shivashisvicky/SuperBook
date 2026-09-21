import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:superbook/services/gutenberg_service.dart';

void main() {
  test('Gutenberg parser ignores table-of-contents chapter markers', () async {
    const text = '''
*** START OF THE PROJECT GUTENBERG EBOOK TEST ***

TITLE

CONTENTS
CHAPTER 1. First.
CHAPTER 2. Second.
CHAPTER 3. The Spouter-Inn.

Front matter.

CHAPTER 1. First.
This is the actual first chapter. It contains enough prose to prove that
the marker is a real chapter boundary and not merely a contents entry.
The prose continues here with another complete sentence.

CHAPTER 2. Second.
This is the actual second chapter. It contains enough prose to prove that
the marker is a real chapter boundary and not merely a contents entry.
The prose continues here with another complete sentence.

CHAPTER 3. The Spouter-Inn.
Entering that gable-ended Spouter-Inn, you found yourself in a wide,
low, straggling entry with old-fashioned wainscots. On one side hung
a very large oilpainting so thoroughly besmoked and every way defaced.
The public room was dark and crowded, and the sailors gathered around
the table while the landlord prepared their supper.

*** END OF THE PROJECT GUTENBERG EBOOK TEST ***
''';

    final client = MockClient((request) async {
      if (request.url.host == 'gutendex.com') {
        return http.Response(
          jsonEncode({
            'formats': {
              'text/plain':
                  'https://www.gutenberg.org/cache/epub/2701/pg2701.txt',
            },
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }
      if (request.url.host == 'r.jina.ai') {
        return http.Response(text, 200);
      }
      return http.Response('not found', 404);
    });

    final service = GutenbergService(client: client);
    const summary = GutenbergBookSummary(
      id: 2701,
      title: 'Moby Dick; Or, The Whale',
      author: 'Herman Melville',
      downloadCount: 0,
      coverUrl: null,
    );

    final book = await service.loadBook(summary);

    expect(book.chapters, hasLength(3));
    expect(book.chapters[2].title, 'The Spouter-Inn');
    expect(
      book.chapters[2].passage.first,
      contains('Entering that gable-ended Spouter-Inn'),
    );
    expect(
      book.chapters[2].passage.first,
      isNot(contains('This chapter contains no readable text')),
    );
  });
}
