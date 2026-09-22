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

  test('Gutenberg parser drops front-matter headings before the first real chapter', () {
    const text = '''
*** START OF THE PROJECT GUTENBERG EBOOK PRIDE AND PREJUDICE ***

PRIDE AND PREJUDICE
JANE AUSTEN

CONTENTS
CHAPTER I. An introductory contents entry.
CHAPTER II. Another contents entry.

TITLE PAGE

PRIDE AND PREJUDICE
BY JANE AUSTEN

CHAPTER I.
It is a truth universally acknowledged that a single man in possession of a good
fortune must be in want of a wife. However little known the feelings or views of
such a man may be on his first entering a neighbourhood, this truth is so well fixed.

CHAPTER II.
Mr. Bennet was among the earliest of those who waited on Mr. Bingley. He had
always intended to visit him, although he had assured his wife that he would not.
The family discussed the matter at length in the drawing room.

*** END OF THE PROJECT GUTENBERG EBOOK PRIDE AND PREJUDICE ***
''';
    const summary = GutenbergBookSummary(
      id: 1342,
      title: 'Pride and Prejudice',
      author: 'Jane Austen',
      downloadCount: 0,
      coverUrl: null,
    );

    final service = GutenbergService();
    final book = service.parseText(summary, text);

    expect(book.chapters, hasLength(2));
    expect(book.chapters.first.title, 'Chapter I');
    expect(book.chapters.first.passage.first, contains('truth universally acknowledged'));
    expect(book.chapters[1].title, 'Chapter II');
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
  test('Gutenberg parser rejects OCR references as chapter headings', () async {
    const text = '''
*** START OF THE PROJECT GUTENBERG EBOOK TEST ***

CHAPTER V.
Sun Tzu explains the chapter with enough substantive prose to establish a real
section. The discussion continues with several complete sentences and remains
part of the same chapter. The narrative continues with a further complete
description of the commander and the army, giving this section more than enough
substantive prose for the parser to recognize the chapter boundary correctly.

* X 2JBJI ff IH S 1
31. This is OCR noise from the scanned page and must remain inside the chapter.
It contains enough prose to make sure the parser cannot mistake the line itself
for a section boundary.

Cf. III. § 13 (i)
32. This is another reference embedded in the page and is not a chapter heading.
The surrounding text continues with more complete sentences and commentary.

CHAPTER VI.
The next chapter begins here with enough substantive prose to establish a real
section. The discussion continues with several complete sentences and remains
part of the next chapter. The soldiers prepare their positions while the
commander studies the ground and considers the changing circumstances. The
argument continues through another complete thought, giving the parser ample
story text before the end of the downloaded section.

*** END OF THE PROJECT GUTENBERG EBOOK TEST ***
''';
    const summary = GutenbergBookSummary(
      id: 17405,
      title: 'The Art of War',
      author: 'Sunzi',
      downloadCount: 0,
      coverUrl: null,
    );

    final service = GutenbergService();
    final book = service.parseText(summary, text);

    expect(book.chapters, hasLength(2));
    expect(book.chapters.first.title, 'Chapter V');
    expect(book.chapters.last.title, 'Chapter VI');
    expect(book.chapters.first.passage.join(' '), contains('2JBJI'));
    expect(book.chapters.first.passage.join(' '), contains('Cf. III.'));
  });

  test('Gutenberg parser recognizes Roman-numbered titled chapters', () {
    const text = '''
*** START OF THE PROJECT GUTENBERG EBOOK TEST ***

CONTENTS
I. LAYING PLANS
II. WAGING WAR
III. ATTACK BY STRATAGEM

I. LAYING PLANS.
Sun Tzu begins the first chapter with enough substantive prose to establish a
real section. The discussion continues with several complete sentences about
the state, the army, and the five constant factors of warfare. The chapter continues with additional explanatory detail so the parser has enough substantive prose to distinguish the section from front matter and OCR references.

II. WAGING WAR.
Sun Tzu begins the second chapter with enough substantive prose to establish
another real section. The discussion continues with several complete sentences
about the costs and conduct of warfare. The chapter continues with additional explanatory detail so the parser has enough substantive prose to distinguish the section from front matter and OCR references.

III. ATTACK BY STRATAGEM.
Sun Tzu begins the third chapter with enough substantive prose to establish a
third real section. The discussion continues with several complete sentences
about taking the enemy whole and avoiding unnecessary siege operations. The chapter continues with additional explanatory detail so the parser has enough substantive prose to distinguish the section from front matter and OCR references.

* X 2JBJI ff IH S 1
This OCR line must remain inside the third chapter rather than becoming a new
section.

Cf. III. § 13 (i)
This reference marker must also remain ordinary chapter text.

*** END OF THE PROJECT GUTENBERG EBOOK TEST ***
''';
    const summary = GutenbergBookSummary(
      id: 17405,
      title: 'The Art of War',
      author: 'Sunzi',
      downloadCount: 0,
      coverUrl: null,
    );

    final service = GutenbergService();
    final book = service.parseText(summary, text);

    expect(book.chapters, hasLength(3));
    expect(book.chapters.map((chapter) => chapter.title), [
      'Chapter I',
      'Chapter II',
      'Chapter III',
    ]);
    expect(book.chapters.last.passage.join(' '), contains('2JBJI'));
    expect(book.chapters.last.passage.join(' '), contains('Cf. III.'));
  });


  test('Gutenberg parser keeps all 13 titled Art of War chapters', () {
    const text = '''
*** START OF THE PROJECT GUTENBERG EBOOK TEST ***

CONTENTS
I. LAYING PLANS
II. WAGING WAR
III. ATTACK BY STRATAGEM
IV. TACTICAL DISPOSITIONS
V. ENERGY
VI. WEAK POINTS AND STRONG
VII. MANŒUVERING
VIII. VARIATION OF TACTICS
IX. THE ARMY ON THE MARCH
X. TERRAIN
XI. THE NINE SITUATIONS
XII. THE ATTACK BY FIRE
XIII. THE USE OF SPIES

I. LAYING PLANS.
This is substantive chapter prose with enough sentences to establish a real chapter boundary. The chapter continues with additional explanatory detail so the parser has enough substantive prose to distinguish the section from front matter and OCR references. Sun Tzu explains the five constant factors of warfare and the importance of calculation.

II. WAGING WAR.
This is substantive chapter prose with enough sentences to establish a real chapter boundary. The chapter continues with additional explanatory detail so the parser has enough substantive prose to distinguish the section from front matter and OCR references. The army considers the costs and conduct of a prolonged campaign.

III. ATTACK BY STRATAGEM.
This is substantive chapter prose with enough sentences to establish a real chapter boundary. The chapter continues with additional explanatory detail so the parser has enough substantive prose to distinguish the section from front matter and OCR references. The commander considers how to take the enemy whole and avoid needless siege operations.

IV. TACTICAL DISPOSITIONS.
This is substantive chapter prose with enough sentences to establish a real chapter boundary. The chapter continues with additional explanatory detail so the parser has enough substantive prose to distinguish the section from front matter and OCR references. The army arranges its position before engaging the enemy.

V. ENERGY.
This is substantive chapter prose with enough sentences to establish a real chapter boundary. The chapter continues with additional explanatory detail so the parser has enough substantive prose to distinguish the section from front matter and OCR references. The commander organizes direct and indirect methods and controls the force.

VI. WEAK POINTS AND STRONG.
This is substantive chapter prose with enough sentences to establish a real chapter boundary. The chapter continues with additional explanatory detail so the parser has enough substantive prose to distinguish the section from front matter and OCR references. The army moves toward weakness and avoids strength when choosing its point of attack.

VII. MANŒUVERING.
This is substantive chapter prose with enough sentences to establish a real chapter boundary. The chapter continues with additional explanatory detail so the parser has enough substantive prose to distinguish the section from front matter and OCR references. The army moves carefully and maintains communication while maneuvering.

VIII. VARIATION OF TACTICS.
This is substantive chapter prose with enough sentences to establish a real chapter boundary. The chapter continues with additional explanatory detail so the parser has enough substantive prose to distinguish the section from front matter and OCR references. The commander changes methods according to circumstances and terrain.

IX. THE ARMY ON THE MARCH.
This is substantive chapter prose with enough sentences to establish a real chapter boundary. The chapter continues with additional explanatory detail so the parser has enough substantive prose to distinguish the section from front matter and OCR references. The soldiers observe signs on the march and interpret the condition of the enemy.

X. TERRAIN.
This is substantive chapter prose with enough sentences to establish a real chapter boundary. The chapter continues with additional explanatory detail so the parser has enough substantive prose to distinguish the section from front matter and OCR references. The commander studies the ground and understands the different kinds of terrain.

XI. THE NINE SITUATIONS.
This is substantive chapter prose with enough sentences to establish a real chapter boundary. The chapter continues with additional explanatory detail so the parser has enough substantive prose to distinguish the section from front matter and OCR references. The army responds differently to dispersed, difficult, and desperate situations.

XII. THE ATTACK BY FIRE.
This is substantive chapter prose with enough sentences to establish a real chapter boundary. The chapter continues with additional explanatory detail so the parser has enough substantive prose to distinguish the section from front matter and OCR references. Fire is used according to conditions, weather, and the position of the enemy.

XIII. THE USE OF SPIES.
This is substantive chapter prose with enough sentences to establish a real chapter boundary. The chapter continues with additional explanatory detail so the parser has enough substantive prose to distinguish the section from front matter and OCR references. Intelligence is gathered through different kinds of spies and used to understand the enemy.

C
This OCR artifact looks like a Roman numeral but is not a chapter heading.
Cf. III. § 13 (i)
This reference must remain ordinary chapter text.

*** END OF THE PROJECT GUTENBERG EBOOK TEST ***
''';
    const summary = GutenbergBookSummary(
      id: 17405,
      title: 'The Art of War',
      author: 'Sunzi',
      downloadCount: 0,
      coverUrl: null,
    );

    final service = GutenbergService();
    final book = service.parseText(summary, text);

    expect(book.chapters, hasLength(13));
    expect(
      book.chapters.map((chapter) => chapter.title),
      [
        'Chapter I',
        'Chapter II',
        'Chapter III',
        'Chapter IV',
        'Chapter V',
        'Chapter VI',
        'Chapter VII',
        'Chapter VIII',
        'Chapter IX',
        'Chapter X',
        'Chapter XI',
        'Chapter XII',
        'Chapter XIII',
      ],
    );
    expect(book.chapters.last.passage.join(' '), contains('Cf. III.'));
  });

  test('Gutenberg parser preserves conventional chapter order after contents', () async {
    const text = '''
*** START OF THE PROJECT GUTENBERG EBOOK TEST ***

CONTENTS
Chapter XX.
Chapter XXI.
Chapter XXII.
Chapter XXIII.

Chapter I.
Elizabeth begins the story with enough substantive prose to establish the first real chapter. The family discusses a new neighbour and the implications of his arrival in the neighbourhood with several complete sentences.

Chapter II.
Mr. Bennet continues the story with enough substantive prose to establish the second real chapter. The family discusses the recent visit and the social expectations surrounding the new acquaintance with several complete sentences.

Chapter XX.
The story reaches a later chapter with enough substantive prose to establish a real chapter boundary. Mr. Collins was not left long to the silent contemplation of his successful love, and the family continues the discussion with several complete sentences. The next chapter continues with additional narrative detail so the parser can distinguish a genuine chapter from front matter and reference material. The following passage adds more complete sentences about the characters, their conversation, and the events that follow. Several further sentences keep this chapter substantive and make its boundary unambiguous for the reader.

Chapter XXI.
The next chapter contains enough substantive prose to establish a real chapter boundary. The characters continue their conversation and consider what should happen next with several complete sentences. The next chapter continues with additional narrative detail so the parser can distinguish a genuine chapter from front matter and reference material. The following passage adds more complete sentences about the characters, their conversation, and the events that follow. Several further sentences keep this chapter substantive and make its boundary unambiguous for the reader.

Chapter XXII.
The next chapter contains enough substantive prose to establish a real chapter boundary. The household discusses the social situation and the consequences of recent events with several complete sentences. The next chapter continues with additional narrative detail so the parser can distinguish a genuine chapter from front matter and reference material. The following passage adds more complete sentences about the characters, their conversation, and the events that follow. Several further sentences keep this chapter substantive and make its boundary unambiguous for the reader.

Chapter XXIII.
The next chapter contains enough substantive prose to establish a real chapter boundary. The characters continue the story and prepare for the following developments with several complete sentences. The next chapter continues with additional narrative detail so the parser can distinguish a genuine chapter from front matter and reference material. The following passage adds more complete sentences about the characters, their conversation, and the events that follow. Several further sentences keep this chapter substantive and make its boundary unambiguous for the reader.

*** END OF THE PROJECT GUTENBERG EBOOK TEST ***
''';
    const summary = GutenbergBookSummary(id: 1342, title: 'Pride and Prejudice', author: 'Jane Austen', downloadCount: 0, coverUrl: null);
    final book = GutenbergService().parseText(summary, text);
    expect(book.chapters.map((chapter) => chapter.title), [
      'Chapter I',
      'Chapter II',
      'Chapter XX',
      'Chapter XXI',
      'Chapter XXII',
      'Chapter XXIII',
    ]);
  });

}
