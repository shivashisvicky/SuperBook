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

  test('Gutenberg parser recognizes Sherlock-style adventure headings', () async {
    const text = '''
*** START OF THE PROJECT GUTENBERG EBOOK TEST ***

CONTENTS
I. A SCANDAL IN BOHEMIA
II. THE RED-HEADED LEAGUE

ADVENTURE I. A SCANDAL IN BOHEMIA
Holmes examined the paper carefully and explained the German origin of the note.
This is substantive story prose with several complete sentences. Watson listened
closely while Holmes continued his reasoning and prepared for the visitor.

ADVENTURE II. THE RED-HEADED LEAGUE
Holmes received another curious case and began to explain the strange circumstances.
The client described what had happened, and Watson followed the investigation.
The room was quiet while Holmes considered the evidence before him.

*** END OF THE PROJECT GUTENBERG EBOOK TEST ***
''';
    final client = MockClient((request) async {
      if (request.url.host == 'gutendex.com') {
        return http.Response(jsonEncode({'formats': {'text/plain': 'https://www.gutenberg.org/cache/epub/1661/pg1661.txt'}}), 200, headers: const {'content-type': 'application/json'});
      }
      if (request.url.host == 'r.jina.ai') return http.Response(text, 200);
      return http.Response('not found', 404);
    });
    final service = GutenbergService(client: client);
    const summary = GutenbergBookSummary(id: 1661, title: 'The Adventures of Sherlock Holmes', author: 'Arthur Conan Doyle', downloadCount: 0, coverUrl: null);
    final book = await service.loadBook(summary);
    expect(book.chapters, hasLength(2));
    expect(book.chapters.first.title, 'A SCANDAL IN BOHEMIA');
    expect(book.chapters.last.title, 'THE RED-HEADED LEAGUE');
  });

  test('Gutenberg parser recognizes standalone Roman numeral sections', () async {
    const text = '''
*** START OF THE PROJECT GUTENBERG EBOOK TEST ***

I
The first substantive section contains enough prose to establish a real section.
Holmes and Watson discuss the case in detail. The investigation continues through
several sentences so the parser can distinguish it from a table of contents.

II
The second substantive section contains enough prose to establish another section.
The characters move forward with the investigation and discuss the evidence at
length before the next part of the story begins.

*** END OF THE PROJECT GUTENBERG EBOOK TEST ***
''';
    final client = MockClient((request) async {
      if (request.url.host == 'gutendex.com') {
        return http.Response(jsonEncode({'formats': {'text/plain': 'https://www.gutenberg.org/cache/epub/1661/pg1661.txt'}}), 200, headers: const {'content-type': 'application/json'});
      }
      if (request.url.host == 'r.jina.ai') return http.Response(text, 200);
      return http.Response('not found', 404);
    });
    final service = GutenbergService(client: client);
    const summary = GutenbergBookSummary(id: 1661, title: 'Sherlock-style test', author: 'Arthur Conan Doyle', downloadCount: 0, coverUrl: null);
    final book = await service.loadBook(summary);
    expect(book.chapters, hasLength(2));
    expect(book.chapters.first.title, 'Chapter I');
    expect(book.chapters.last.title, 'Chapter II');
  });
}
