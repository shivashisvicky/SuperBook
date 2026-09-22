import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/book.dart';

class LibraryBookSummary {
  const LibraryBookSummary({
    required this.id,
    required this.title,
    required this.author,
    required this.downloadCount,
    required this.coverUrl,
    this.archiveIds = const [],
    this.gutenbergId,
  });

  final String id;
  final String title;
  final String author;
  final int downloadCount;
  final String? coverUrl;
  final List<String> archiveIds;
  final int? gutenbergId;

  bool get hasTextSource => archiveIds.isNotEmpty || gutenbergId != null;
}

class OpenLibraryService {
  OpenLibraryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, Book> _cache = {};

  static const _fallbackBooks = <LibraryBookSummary>[
    LibraryBookSummary(
      id: 'gutenberg-1342',
      title: 'Pride and Prejudice',
      author: 'Jane Austen',
      downloadCount: 0,
      coverUrl: 'https://www.gutenberg.org/cache/epub/1342/pg1342.cover.medium.jpg',
      gutenbergId: 1342,
    ),
    LibraryBookSummary(
      id: 'gutenberg-1661',
      title: 'The Adventures of Sherlock Holmes',
      author: 'Arthur Conan Doyle',
      downloadCount: 0,
      coverUrl: 'https://www.gutenberg.org/cache/epub/1661/pg1661.cover.medium.jpg',
      gutenbergId: 1661,
    ),
    LibraryBookSummary(
      id: 'gutenberg-2701',
      title: 'Moby Dick; Or, The Whale',
      author: 'Herman Melville',
      downloadCount: 0,
      coverUrl: 'https://www.gutenberg.org/cache/epub/2701/pg2701.cover.medium.jpg',
      gutenbergId: 2701,
    ),
    LibraryBookSummary(
      id: 'gutenberg-84',
      title: 'Frankenstein; or, the Modern Prometheus',
      author: 'Mary Wollstonecraft Shelley',
      downloadCount: 0,
      coverUrl: 'https://www.gutenberg.org/cache/epub/84/pg84.cover.medium.jpg',
      gutenbergId: 84,
    ),
    LibraryBookSummary(
      id: 'gutenberg-11',
      title: 'Alice\'s Adventures in Wonderland',
      author: 'Lewis Carroll',
      downloadCount: 0,
      coverUrl: 'https://www.gutenberg.org/cache/epub/11/pg11.cover.medium.jpg',
      gutenbergId: 11,
    ),
    LibraryBookSummary(
      id: 'gutenberg-345',
      title: 'Dracula',
      author: 'Bram Stoker',
      downloadCount: 0,
      coverUrl: 'https://www.gutenberg.org/cache/epub/345/pg345.cover.medium.jpg',
      gutenbergId: 345,
    ),
    LibraryBookSummary(
      id: 'gutenberg-1400',
      title: 'Great Expectations',
      author: 'Charles Dickens',
      downloadCount: 0,
      coverUrl: 'https://www.gutenberg.org/cache/epub/1400/pg1400.cover.medium.jpg',
      gutenbergId: 1400,
    ),
    LibraryBookSummary(
      id: 'gutenberg-174',
      title: 'The Picture of Dorian Gray',
      author: 'Oscar Wilde',
      downloadCount: 0,
      coverUrl: 'https://www.gutenberg.org/cache/epub/174/pg174.cover.medium.jpg',
      gutenbergId: 174,
    ),
  ];

  Future<List<LibraryBookSummary>> popularBooks() async {
    try {
      final uri = Uri.parse(
        'https://openlibrary.org/search.json'
        '?q=ebook_access:public'
        '&sort=readinglog'
        '&language=eng'
        '&fields=key,title,author_name,cover_i,ia,ebook_access'
        '&limit=20',
      );
      final results = await _search(uri);
      if (results.isNotEmpty) return results;
    } catch (_) {
      // The local Gutenberg set keeps the Library usable during provider outages.
    }
    return _fallbackBooks;
  }

  Future<List<LibraryBookSummary>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return popularBooks();

    try {
      final uri = Uri.https(
        'openlibrary.org',
        '/search.json',
        {
          'q': '$trimmed AND ebook_access:public',
          'language': 'eng',
          'fields': 'key,title,author_name,cover_i,ia,ebook_access',
          'limit': '20',
        },
      );
      final results = await _search(uri);
      if (results.isNotEmpty) return results;
    } catch (_) {
      // Fall through to the local safety net for known classics.
    }

    final lower = trimmed.toLowerCase();
    final fallback = _fallbackBooks.where((book) {
      return book.title.toLowerCase().contains(lower) ||
          book.author.toLowerCase().contains(lower);
    }).toList();
    if (fallback.isNotEmpty) return fallback;
    throw Exception('No public-domain books matched “$trimmed”.');
  }

  Future<List<LibraryBookSummary>> _search(Uri uri) async {
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Open Library returned HTTP ${response.statusCode}.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final docs = data['docs'] as List<dynamic>? ?? const [];
    return docs
        .map(_summaryFromOpenLibrary)
        .where((book) => book.hasTextSource)
        .take(12)
        .toList();
  }

  LibraryBookSummary _summaryFromOpenLibrary(dynamic value) {
    final map = value as Map<String, dynamic>;
    final authors = map['author_name'] as List<dynamic>? ?? const [];
    final archiveIds = (map['ia'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();

    final coverId = map['cover_i'] as int?;
    return LibraryBookSummary(
      id: (map['key'] as String? ?? '').replaceFirst('/works/', 'openlibrary-'),
      title: map['title'] as String? ?? 'Untitled',
      author: authors.isEmpty ? 'Unknown author' : authors.first.toString(),
      downloadCount: 0,
      coverUrl: coverId == null
          ? null
          : 'https://covers.openlibrary.org/b/id/$coverId-M.jpg',
      archiveIds: archiveIds,
    );
  }

  Future<Book> loadBook(LibraryBookSummary summary) async {
    final cached = _cache[summary.id];
    if (cached != null) return cached;

    Object? archiveError;
    for (final archiveId in _orderedArchiveIds(summary.archiveIds)) {
      try {
        final text = await _loadArchiveText(archiveId);
        final book = _parseBook(summary, text);
        _cache[summary.id] = book;
        return book;
      } catch (error) {
        archiveError = error;
      }
    }

    if (summary.gutenbergId != null) {
      try {
        final text = await _loadGutenbergText(summary.gutenbergId!);
        final book = _parseBook(summary, text);
        _cache[summary.id] = book;
        return book;
      } catch (error) {
        archiveError = error;
      }
    }

    throw Exception(
      'Could not download ${summary.title}'
      '${archiveError == null ? '' : ': $archiveError'}',
    );
  }

  List<String> _orderedArchiveIds(List<String> ids) {
    final ordered = [...ids];
    ordered.sort((a, b) {
      final aGutenberg = _looksLikeGutenberg(a) ? 0 : 1;
      final bGutenberg = _looksLikeGutenberg(b) ? 0 : 1;
      return aGutenberg.compareTo(bGutenberg);
    });
    return ordered;
  }

  bool _looksLikeGutenberg(String id) {
    final value = id.toLowerCase();
    return value.contains('gutenberg') || value.endsWith('gut');
  }

  Future<String> _loadArchiveText(String archiveId) async {
    final metadataResponse = await _client
        .get(Uri.parse('https://archive.org/metadata/$archiveId'))
        .timeout(const Duration(seconds: 12));
    if (metadataResponse.statusCode != 200) {
      throw Exception('Internet Archive returned HTTP ${metadataResponse.statusCode}.');
    }

    final metadata = jsonDecode(metadataResponse.body) as Map<String, dynamic>;
    final files = metadata['files'] as List<dynamic>? ?? const [];
    final textFile = _findTextFile(files);
    if (textFile == null) {
      throw Exception('No plain-text file is available for this edition.');
    }

    final fileName = textFile['name'] as String;
    final uri = Uri.parse(
      'https://archive.org/download/$archiveId/${Uri.encodeComponent(fileName)}',
    );
    final response = await _client.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('Internet Archive text returned HTTP ${response.statusCode}.');
    }
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  Map<String, dynamic>? _findTextFile(List<dynamic> files) {
    final maps = files.whereType<Map<String, dynamic>>().toList();
    for (final file in maps) {
      final name = file['name'] as String? ?? '';
      if (name.endsWith('_djvu.txt')) return file;
    }
    for (final file in maps) {
      final name = file['name'] as String? ?? '';
      final format = (file['format'] as String? ?? '').toLowerCase();
      if (name.endsWith('.txt') &&
          !name.endsWith('_files.xml') &&
          !format.contains('metadata')) {
        return file;
      }
    }
    return null;
  }

  Future<String> _loadGutenbergText(int id) async {
    final urls = [
      'https://www.gutenberg.org/cache/epub/$id/pg$id.txt',
      'https://www.gutenberg.org/files/$id/$id-8.txt',
      'https://www.gutenberg.org/files/$id/$id.txt',
    ];
    Object? lastError;
    for (final url in urls) {
      try {
        final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
        if (response.statusCode == 200) {
          return utf8.decode(response.bodyBytes, allowMalformed: true);
        }
        lastError = 'HTTP ${response.statusCode}';
      } catch (error) {
        lastError = error;
      }
    }
    throw Exception('Gutenberg text unavailable: $lastError');
  }

  Book _parseBook(LibraryBookSummary summary, String rawText) {
    final cleaned = _stripGutenbergWrapper(rawText);
    final lines = cleaned
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    final markers = _chapterMarkers(lines);
    final selectedMarkers = _selectSubstantiveMarkers(lines, markers);
    final blocks = _paragraphs(lines);
    final chapters = <Chapter>[];

    if (selectedMarkers.isEmpty) {
      chapters.add(_chapterFromParagraphs('Book', blocks, 0));
    } else {
      for (var i = 0; i < selectedMarkers.length; i++) {
        final marker = selectedMarkers[i];
        final endLine = i + 1 < selectedMarkers.length
            ? selectedMarkers[i + 1].line
            : lines.length;
        final section = _paragraphs(lines.sublist(marker.line + 1, endLine));
        final heading = marker.heading.isEmpty
            ? 'Chapter ${marker.number ?? i + 1}'
            : _normalizeChapterHeading(marker.heading);
        chapters.add(_chapterFromParagraphs(heading, section, i));
      }
    }

    final safeChapters = chapters.isEmpty
        ? [_chapterFromParagraphs('Book', blocks, 0)]
        : chapters;
    final beats = [
      for (var i = 0; i < safeChapters.length; i++)
        NarrativeBeat(
          title: safeChapters[i].title,
          summary: safeChapters[i].passage.first,
          chapterId: safeChapters[i].id,
          intensity: _intensityForTheme(safeChapters[i].scene.visualTheme),
        ),
    ];

    return Book(
      id: summary.id,
      title: summary.title,
      author: summary.author,
      description: 'Public-domain text discovered through Open Library.',
      chapters: safeChapters,
      characters: const [],
      locations: const [],
      objects: const [],
      beats: beats,
    );
  }

  String _normalizeChapterHeading(String heading) {
    var value = heading.trim();
    value = value
        .replaceFirst(RegExp(r'^[\[\]{}()]+'), '')
        .replaceFirst(RegExp(r'[\[\]{}()]+, '')
        .trim();
    while (value.endsWith('.') || value.endsWith('?') || value.endsWith('!')) {
      value = value.substring(0, value.length - 1).trimRight();
    }
    return RegExp(r'[A-Za-z0-9]').hasMatch(value) ? value : '';
  }

  List<_ChapterMarker> _chapterMarkers(List<String> lines) {
    final markers = <_ChapterMarker>[];
    final chapterPattern =
        RegExp(r'^(?:CHAPTER|Chapter)\s+([IVXLCDM]+|\d+)\.?\s*(.*)$');
    final adventurePattern = RegExp(
      r'^(?:ADVENTURE|STORY|PART|BOOK)\s+([IVXLCDM]+|\d+)\.?\s*[-—:.]?\s*(.+)$',
      caseSensitive: false,
    );
    final romanPattern = RegExp(r'^([IVXLCDM]{1,8})\.?\s*$');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final chapterMatch = chapterPattern.firstMatch(line);
      if (chapterMatch != null) {
        final numberText = chapterMatch.group(1)!;
        markers.add(
          _ChapterMarker(
            line: i,
            number: int.tryParse(numberText) ?? _romanToInt(numberText),
            heading: chapterMatch.group(2)!.trim(),
          ),
        );
        continue;
      }

      final adventureMatch = adventurePattern.firstMatch(line);
      if (adventureMatch != null &&
          _looksLikeStructuralHeading(line) &&
          _hasSubstantiveBody(lines, i)) {
        final numberText = adventureMatch.group(1)!;
        markers.add(
          _ChapterMarker(
            line: i,
            number: int.tryParse(numberText) ?? _romanToInt(numberText),
            heading: _cleanStructuralHeading(adventureMatch.group(2)!),
          ),
        );
        continue;
      }

      final romanMatch = romanPattern.firstMatch(line);
      if (romanMatch != null && _hasSubstantiveBody(lines, i)) {
        final roman = romanMatch.group(1)!;
        markers.add(
          _ChapterMarker(
            line: i,
            number: _romanToInt(roman),
            heading: 'Chapter $roman',
          ),
        );
        continue;
      }

      if (_looksLikeStructuralHeading(line) && _hasSubstantiveBody(lines, i)) {
        markers.add(
          _ChapterMarker(
            line: i,
            number: null,
            heading: _cleanStructuralHeading(line),
          ),
        );
      }
    }
    return markers;
  }

  bool _hasSubstantiveBody(List<String> lines, int markerLine) {
    final text = lines
        .sublist(markerLine + 1)
        .take(80)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return _looksLikeChapterBody(text);
  }

  bool _looksLikeStructuralHeading(String line) {
    final value = line.trim();
    if (value.length < 5 ||
        value.length > 120 ||
        !RegExp(r'[A-Za-z]').hasMatch(value)) {
      return false;
    }
    if (RegExp(r'^[IVXLCDM]{1,8}\.?\s+').hasMatch(value)) return false;
    const excluded = {
      'CONTENTS',
      'ILLUSTRATIONS',
      'PREFACE',
      'INTRODUCTION',
      'APPENDIX',
      'NOTES',
      'TRANSCRIBER NOTES',
      'PROJECT GUTENBERG',
    };
    if (excluded.contains(value.toUpperCase())) return false;
    final letters = value.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length < 5) return false;
    final lowerLetters = letters.replaceAll(RegExp(r'[A-Z]'), '');
    return lowerLetters.length / letters.length < 0.35;
  }

  String _cleanStructuralHeading(String value) => value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[|—–:.-]+|[|—–:.-]+$'), '')
      .trim();

  List<_ChapterMarker> _selectSubstantiveMarkers(
    List<String> lines,
    List<_ChapterMarker> markers,
  ) {
    if (markers.isEmpty) return const [];

    final selected = <_ChapterMarker>[];
    for (var i = 0; i < markers.length; i++) {
      final marker = markers[i];
      final endLine = i + 1 < markers.length
          ? markers[i + 1].line
          : lines.length;
      final sectionText = lines
          .sublist(marker.line + 1, endLine)
          .join(' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (_looksLikeChapterBody(sectionText)) selected.add(marker);
    }
    return _removeDuplicateChapterMarkers(selected);
  }

  bool _looksLikeChapterBody(String text) {
    if (text.length < 180) return false;
    final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    if (words.length < 30) return false;
    final sentenceMarks = RegExp(r'[.!?]').allMatches(text).length;
    return sentenceMarks >= 2;
  }

  List<_ChapterMarker> _removeDuplicateChapterMarkers(
    List<_ChapterMarker> markers,
  ) {
    final result = <_ChapterMarker>[];
    final seen = <int>{};
    for (final marker in markers) {
      final number = marker.number;
      if (number != null && seen.contains(number)) continue;
      if (number != null) seen.add(number);
      result.add(marker);
    }
    return result;
  }

  List<String> _paragraphs(List<String> lines) {
    return lines
        .join('\n')
        .split(RegExp(r'\n\s*\n'))
        .map((block) => block.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((block) => block.length > 30)
        .toList();
  }

  int? _romanToInt(String value) {
    const values = <String, int>{
      'I': 1,
      'V': 5,
      'X': 10,
      'L': 50,
      'C': 100,
      'D': 500,
      'M': 1000,
    };
    var total = 0;
    var previous = 0;
    for (final char in value.toUpperCase().split('').reversed) {
      final current = values[char];
      if (current == null) return null;
      if (current < previous) {
        total -= current;
      } else {
        total += current;
        previous = current;
      }
    }
    return total;
  }

  Chapter _chapterFromParagraphs(
    String title,
    List<String> paragraphs,
    int index,
  ) {
    final passage = paragraphs.isEmpty
        ? const ['This section contains no readable text in the downloaded edition.']
        : paragraphs;
    final first = passage.first;
    return Chapter(
      id: 'chapter-${index + 1}',
      title: title,
      passage: passage,
      scene: _sceneForChapter(
        title: title,
        passage: passage,
        caption: first.length > 150 ? '${first.substring(0, 147)}...' : first,
      ),
    );
  }

  int _intensityForTheme(String theme) {
    switch (theme) {
      case 'battle':
        return 3;
      case 'estate':
      case 'sea':
      case 'forest':
      case 'city':
        return 2;
      default:
        return 1;
    }
  }

  Scene _sceneForChapter({
    required String title,
    required List<String> passage,
    required String caption,
  }) {
    final text = passage.join(' ').toLowerCase();
    final theme = _visualThemeFor(text);
    final atmospheres = <String, String>{
      'estate':
          'Warm drawing rooms, a garden beyond the windows, and the quiet after a family turning point.',
      'sea':
          'Open water, wind, shifting clouds, and a vessel moving through a wide horizon.',
      'forest':
          'Deep trees, filtered light, a narrow path, and the sense that something lies beyond it.',
      'city':
          'A living street, distant windows, moving silhouettes, and the pulse of a crowded city.',
      'interior':
          'A quiet interior shaped by lamplight, furniture, and the people gathered inside.',
      'night':
          'A dark landscape under moving clouds, with a small source of light holding the eye.',
      'journey':
          'A road leads forward through a changing landscape, keeping the next destination just out of sight.',
      'battle':
          'Smoke, movement, scattered light, and opposing forces turn the landscape into a place of action.',
      'neutral':
          'The visual world follows the place, people, and action described in this passage.',
    };
    return Scene(
      title: title,
      moment: caption,
      atmosphere: atmospheres[theme]!,
      caption: caption,
      visualTheme: theme,
    );
  }

  String _visualThemeFor(String text) {
    if (RegExp(
      r'\b(?:mrs\.? bennet|bennet|darcy|elizabeth|gardiner|derbyshire|married|marriage|daughter|family|drawing room|garden|parlour|parlor)\b',
    ).hasMatch(text)) {
      return 'estate';
    }
    if (RegExp(
      r'\b(?:ship|ships|whale|ocean|sea|sailor|sailing|harbour|harbor|captain|mast|deck|wave|waves)\b',
    ).hasMatch(text)) {
      return 'sea';
    }
    if (RegExp(r'\b(?:forest|woods|woodland|tree|trees|grove|wilderness)\b').hasMatch(text)) {
      return 'forest';
    }
    if (RegExp(r'\b(?:street|city|town|london|paris|market|shop|shops|crowd|carriage|station)\b').hasMatch(text)) {
      return 'city';
    }
    if (RegExp(r'\b(?:room|house|home|hall|library|study|bedroom|fireplace|table|door|window|lamp|candle)\b').hasMatch(text)) {
      return 'interior';
    }
    if (RegExp(r'\b(?:night|midnight|moon|moonlight|darkness|stars|starry)\b').hasMatch(text)) {
      return 'night';
    }
    if (RegExp(r'\b(?:road|journey|travel|traveler|traveller|horse|horses|coach|roadside|departure)\b').hasMatch(text)) {
      return 'journey';
    }
    if (RegExp(r'\b(?:battle|army|soldier|soldiers|war|weapon|weapons|fight|fought|enemy|cannon)\b').hasMatch(text)) {
      return 'battle';
    }
    return 'neutral';
  }

  String _stripGutenbergWrapper(String text) {
    final start = RegExp(
      r'\*\*\* START OF (?:THE )?PROJECT GUTENBERG EBOOK[^\n]*\*\*\*',
    );
    final end = RegExp(
      r'\*\*\* END OF (?:THE )?PROJECT GUTENBERG EBOOK[^\n]*\*\*\*',
    );
    final startMatch = start.firstMatch(text);
    final endMatch = end.firstMatch(text);
    return text
        .substring(startMatch?.end ?? 0, endMatch?.start ?? text.length)
        .trim();
  }
}

class _ChapterMarker {
  const _ChapterMarker({
    required this.line,
    required this.number,
    required this.heading,
  });

  final int line;
  final int? number;
  final String heading;
}
), '')
        .trim();
    while (value.endsWith('.') || value.endsWith('?') || value.endsWith('!')) {
      value = value.substring(0, value.length - 1).trimRight();
    }
    return RegExp(r'[A-Za-z0-9]').hasMatch(value) ? value : '';
  }

  List<_ChapterMarker> _chapterMarkers(List<String> lines) {
    final markers = <_ChapterMarker>[];
    final chapterPattern =
        RegExp(r'^(?:CHAPTER|Chapter)\s+([IVXLCDM]+|\d+)\.?\s*(.*)$');
    final adventurePattern = RegExp(
      r'^(?:ADVENTURE|STORY|PART|BOOK)\s+([IVXLCDM]+|\d+)\.?\s*[-—:.]?\s*(.+)$',
      caseSensitive: false,
    );
    final romanPattern = RegExp(r'^([IVXLCDM]{1,8})\.?\s*$');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final chapterMatch = chapterPattern.firstMatch(line);
      if (chapterMatch != null) {
        final numberText = chapterMatch.group(1)!;
        markers.add(
          _ChapterMarker(
            line: i,
            number: int.tryParse(numberText) ?? _romanToInt(numberText),
            heading: chapterMatch.group(2)!.trim(),
          ),
        );
        continue;
      }

      final adventureMatch = adventurePattern.firstMatch(line);
      if (adventureMatch != null &&
          _looksLikeStructuralHeading(line) &&
          _hasSubstantiveBody(lines, i)) {
        final numberText = adventureMatch.group(1)!;
        markers.add(
          _ChapterMarker(
            line: i,
            number: int.tryParse(numberText) ?? _romanToInt(numberText),
            heading: _cleanStructuralHeading(adventureMatch.group(2)!),
          ),
        );
        continue;
      }

      final romanMatch = romanPattern.firstMatch(line);
      if (romanMatch != null && _hasSubstantiveBody(lines, i)) {
        final roman = romanMatch.group(1)!;
        markers.add(
          _ChapterMarker(
            line: i,
            number: _romanToInt(roman),
            heading: 'Chapter $roman',
          ),
        );
        continue;
      }

      if (_looksLikeStructuralHeading(line) && _hasSubstantiveBody(lines, i)) {
        markers.add(
          _ChapterMarker(
            line: i,
            number: null,
            heading: _cleanStructuralHeading(line),
          ),
        );
      }
    }
    return markers;
  }

  bool _hasSubstantiveBody(List<String> lines, int markerLine) {
    final text = lines
        .sublist(markerLine + 1)
        .take(80)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return _looksLikeChapterBody(text);
  }

  bool _looksLikeStructuralHeading(String line) {
    final value = line.trim();
    if (value.length < 5 ||
        value.length > 120 ||
        !RegExp(r'[A-Za-z]').hasMatch(value)) {
      return false;
    }
    if (RegExp(r'^[IVXLCDM]{1,8}\.?\s+').hasMatch(value)) return false;
    const excluded = {
      'CONTENTS',
      'ILLUSTRATIONS',
      'PREFACE',
      'INTRODUCTION',
      'APPENDIX',
      'NOTES',
      'TRANSCRIBER NOTES',
      'PROJECT GUTENBERG',
    };
    if (excluded.contains(value.toUpperCase())) return false;
    final letters = value.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length < 5) return false;
    final lowerLetters = letters.replaceAll(RegExp(r'[A-Z]'), '');
    return lowerLetters.length / letters.length < 0.35;
  }

  String _cleanStructuralHeading(String value) => value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[|—–:.-]+|[|—–:.-]+$'), '')
      .trim();

  List<_ChapterMarker> _selectSubstantiveMarkers(
    List<String> lines,
    List<_ChapterMarker> markers,
  ) {
    if (markers.isEmpty) return const [];

    final selected = <_ChapterMarker>[];
    for (var i = 0; i < markers.length; i++) {
      final marker = markers[i];
      final endLine = i + 1 < markers.length
          ? markers[i + 1].line
          : lines.length;
      final sectionText = lines
          .sublist(marker.line + 1, endLine)
          .join(' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (_looksLikeChapterBody(sectionText)) selected.add(marker);
    }
    return _removeDuplicateChapterMarkers(selected);
  }

  bool _looksLikeChapterBody(String text) {
    if (text.length < 180) return false;
    final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    if (words.length < 30) return false;
    final sentenceMarks = RegExp(r'[.!?]').allMatches(text).length;
    return sentenceMarks >= 2;
  }

  List<_ChapterMarker> _removeDuplicateChapterMarkers(
    List<_ChapterMarker> markers,
  ) {
    final result = <_ChapterMarker>[];
    final seen = <int>{};
    for (final marker in markers) {
      final number = marker.number;
      if (number != null && seen.contains(number)) continue;
      if (number != null) seen.add(number);
      result.add(marker);
    }
    return result;
  }

  List<String> _paragraphs(List<String> lines) {
    return lines
        .join('\n')
        .split(RegExp(r'\n\s*\n'))
        .map((block) => block.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((block) => block.length > 30)
        .toList();
  }

  int? _romanToInt(String value) {
    const values = <String, int>{
      'I': 1,
      'V': 5,
      'X': 10,
      'L': 50,
      'C': 100,
      'D': 500,
      'M': 1000,
    };
    var total = 0;
    var previous = 0;
    for (final char in value.toUpperCase().split('').reversed) {
      final current = values[char];
      if (current == null) return null;
      if (current < previous) {
        total -= current;
      } else {
        total += current;
        previous = current;
      }
    }
    return total;
  }

  Chapter _chapterFromParagraphs(
    String title,
    List<String> paragraphs,
    int index,
  ) {
    final passage = paragraphs.isEmpty
        ? const ['This section contains no readable text in the downloaded edition.']
        : paragraphs;
    final first = passage.first;
    return Chapter(
      id: 'chapter-${index + 1}',
      title: title,
      passage: passage,
      scene: _sceneForChapter(
        title: title,
        passage: passage,
        caption: first.length > 150 ? '${first.substring(0, 147)}...' : first,
      ),
    );
  }

  int _intensityForTheme(String theme) {
    switch (theme) {
      case 'battle':
        return 3;
      case 'estate':
      case 'sea':
      case 'forest':
      case 'city':
        return 2;
      default:
        return 1;
    }
  }

  Scene _sceneForChapter({
    required String title,
    required List<String> passage,
    required String caption,
  }) {
    final text = passage.join(' ').toLowerCase();
    final theme = _visualThemeFor(text);
    final atmospheres = <String, String>{
      'estate':
          'Warm drawing rooms, a garden beyond the windows, and the quiet after a family turning point.',
      'sea':
          'Open water, wind, shifting clouds, and a vessel moving through a wide horizon.',
      'forest':
          'Deep trees, filtered light, a narrow path, and the sense that something lies beyond it.',
      'city':
          'A living street, distant windows, moving silhouettes, and the pulse of a crowded city.',
      'interior':
          'A quiet interior shaped by lamplight, furniture, and the people gathered inside.',
      'night':
          'A dark landscape under moving clouds, with a small source of light holding the eye.',
      'journey':
          'A road leads forward through a changing landscape, keeping the next destination just out of sight.',
      'battle':
          'Smoke, movement, scattered light, and opposing forces turn the landscape into a place of action.',
      'neutral':
          'The visual world follows the place, people, and action described in this passage.',
    };
    return Scene(
      title: title,
      moment: caption,
      atmosphere: atmospheres[theme]!,
      caption: caption,
      visualTheme: theme,
    );
  }

  String _visualThemeFor(String text) {
    if (RegExp(
      r'\b(?:mrs\.? bennet|bennet|darcy|elizabeth|gardiner|derbyshire|married|marriage|daughter|family|drawing room|garden|parlour|parlor)\b',
    ).hasMatch(text)) {
      return 'estate';
    }
    if (RegExp(
      r'\b(?:ship|ships|whale|ocean|sea|sailor|sailing|harbour|harbor|captain|mast|deck|wave|waves)\b',
    ).hasMatch(text)) {
      return 'sea';
    }
    if (RegExp(r'\b(?:forest|woods|woodland|tree|trees|grove|wilderness)\b').hasMatch(text)) {
      return 'forest';
    }
    if (RegExp(r'\b(?:street|city|town|london|paris|market|shop|shops|crowd|carriage|station)\b').hasMatch(text)) {
      return 'city';
    }
    if (RegExp(r'\b(?:room|house|home|hall|library|study|bedroom|fireplace|table|door|window|lamp|candle)\b').hasMatch(text)) {
      return 'interior';
    }
    if (RegExp(r'\b(?:night|midnight|moon|moonlight|darkness|stars|starry)\b').hasMatch(text)) {
      return 'night';
    }
    if (RegExp(r'\b(?:road|journey|travel|traveler|traveller|horse|horses|coach|roadside|departure)\b').hasMatch(text)) {
      return 'journey';
    }
    if (RegExp(r'\b(?:battle|army|soldier|soldiers|war|weapon|weapons|fight|fought|enemy|cannon)\b').hasMatch(text)) {
      return 'battle';
    }
    return 'neutral';
  }

  String _stripGutenbergWrapper(String text) {
    final start = RegExp(
      r'\*\*\* START OF (?:THE )?PROJECT GUTENBERG EBOOK[^\n]*\*\*\*',
    );
    final end = RegExp(
      r'\*\*\* END OF (?:THE )?PROJECT GUTENBERG EBOOK[^\n]*\*\*\*',
    );
    final startMatch = start.firstMatch(text);
    final endMatch = end.firstMatch(text);
    return text
        .substring(startMatch?.end ?? 0, endMatch?.start ?? text.length)
        .trim();
  }
}

class _ChapterMarker {
  const _ChapterMarker({
    required this.line,
    required this.number,
    required this.heading,
  });

  final int line;
  final int? number;
  final String heading;
}
