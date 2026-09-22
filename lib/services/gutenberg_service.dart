import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/book.dart';

class GutenbergBookSummary {
  const GutenbergBookSummary({
    required this.id,
    required this.title,
    required this.author,
    required this.downloadCount,
    required this.coverUrl,
  });
  final int id;
  final String title;
  final String author;
  final int downloadCount;
  final String? coverUrl;
}

class GutenbergService {
  GutenbergService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  final Map<int, Book> _cache = {};

  Future<List<GutenbergBookSummary>> popularBooks() =>
      _search('https://gutendex.com/books?languages=en&copyright=false');

  Future<List<GutenbergBookSummary>> search(String query) {
    final encoded = Uri.encodeQueryComponent(query.trim());
    return _search(
      'https://gutendex.com/books?languages=en&copyright=false&search=$encoded',
    );
  }

  Future<List<GutenbergBookSummary>> _search(String url) async {
    final data = await _getJson(url);
    final results = data['results'] as List<dynamic>? ?? const [];
    return results.map((item) {
      final map = item as Map<String, dynamic>;
      final authors = map['authors'] as List<dynamic>? ?? const [];
      final author = authors.isEmpty
          ? 'Unknown author'
          : ((authors.first as Map<String, dynamic>)['name'] as String? ?? 'Unknown author');
      final formats = map['formats'] as Map<String, dynamic>? ?? const {};
      return GutenbergBookSummary(
        id: map['id'] as int,
        title: map['title'] as String? ?? 'Untitled',
        author: author,
        downloadCount: map['download_count'] as int? ?? 0,
        coverUrl: formats['image/jpeg'] as String?,
      );
    }).toList();
  }

  Future<Book> loadBook(GutenbergBookSummary summary) async {
    final cached = _cache[summary.id];
    if (cached != null) return cached;
    final data = await _getJson('https://gutendex.com/books/${summary.id}');
    final formats = data['formats'] as Map<String, dynamic>? ?? const {};
    final textUrls = _textUrls(summary.id, formats);
    if (textUrls.isEmpty) {
      throw Exception('No plain-text edition is available for ${summary.title}.');
    }

    http.Response? textResponse;
    Object? lastError;

    for (final textUrl in textUrls) {
      try {
        final response = await _client
            .get(Uri.parse(textUrl))
            .timeout(const Duration(seconds: 20));
        if (response.statusCode == 200) {
          textResponse = response;
          break;
        }
        lastError = 'HTTP ${response.statusCode}';
      } catch (error) {
        lastError = error;
      }
    }

    if (textResponse == null) {
      throw Exception(
        'Could not download ${summary.title}${lastError == null ? '' : ': $lastError'}.',
      );
    }

    final text = utf8.decode(textResponse.bodyBytes, allowMalformed: true);
    final book = _toBook(summary, text);
    _cache[summary.id] = book;
    return book;
  }

  Book parseText(GutenbergBookSummary summary, String rawText) {
    return _toBook(summary, rawText);
  }

  Future<Map<String, dynamic>> _getJson(String url) async {
    Object? directError;

    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return _decodeJsonObject(response.body);
      }
      directError = 'HTTP ${response.statusCode}';
    } catch (error) {
      directError = error;
    }

    try {
      final response = await _client
          .get(Uri.parse('https://r.jina.ai/http://${Uri.parse(url).host}${Uri.parse(url).path}${Uri.parse(url).query.isEmpty ? '' : '?${Uri.parse(url).query}'}'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return _decodeJsonObject(response.body);
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (error) {
      throw Exception(
        'Could not load Gutenberg data: $directError. '
        'Browser content fallback also failed: $error',
      );
    }
  }

  Map<String, dynamic> _decodeJsonObject(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } on FormatException {
      final start = body.indexOf('{');
      final end = body.lastIndexOf('}');
      if (start < 0 || end <= start) rethrow;
      return jsonDecode(body.substring(start, end + 1)) as Map<String, dynamic>;
    }
  }
  List<String> _textUrls(int bookId, Map<String, dynamic> formats) {
    final sourceUrl =
        'https://www.gutenberg.org/cache/epub/$bookId/pg$bookId.txt';
    return [
      'https://r.jina.ai/http://www.gutenberg.org/cache/epub/$bookId/pg$bookId.txt',
      for (final entry in formats.entries)
        if (entry.key.startsWith('text/plain') &&
            entry.value is String &&
            entry.value != sourceUrl)
          entry.value as String,
    ];
  }

  Book _toBook(GutenbergBookSummary summary, String rawText) {
    final cleaned = _stripGutenbergWrapper(rawText);
    final lines = cleaned.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
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
        final section = _paragraphs(
          lines.sublist(marker.line + 1, endLine),
        );
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
      id: 'gutenberg-${summary.id}',
      title: summary.title,
      author: summary.author,
      description: 'Original public-domain text from Project Gutenberg.',
      chapters: safeChapters,
      characters: const [],
      locations: const [],
      objects: const [],
      beats: beats,
    );
  }

  String _normalizeChapterHeading(String heading) {
    var value = heading.trim();
    value = value.replaceFirst(RegExp(r'^\[\\]{}()]+'), '').replaceFirst(RegExp(r'[\[\\]{}()]+$'), '').trim();
    while (value.endsWith('.') || value.endsWith('?') || value.endsWith('!')) {
      value = value.substring(0, value.length - 1).trimRight();
    }
    return RegExp(r'[A-Za-z0-9]').hasMatch(value) ? value : '';
  }

  List<_ChapterMarker> _chapterMarkers(List<String> lines) {
    final markers = <_ChapterMarker>[];
    final chapterPattern = RegExp(r'^(?:CHAPTER|Chapter)\s+([IVXLCDM]+|\d+)\.?\s*(.*)$');
    final adventurePattern = RegExp(r'^(?:ADVENTURE|STORY|PART|BOOK)\s+([IVXLCDM]+|\d+)\.?\s*[-—:.]?\s*(.+)$', caseSensitive: false);
    final romanPattern = RegExp(r'^([IVXLCDM]{1,8})\.?$');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final chapterMatch = chapterPattern.firstMatch(line);
      if (chapterMatch != null) {
        final numberText = chapterMatch.group(1)!;
        markers.add(_ChapterMarker(line: i, number: int.tryParse(numberText) ?? _romanToInt(numberText), heading: chapterMatch.group(2)!.trim()));
        continue;
      }
      final adventureMatch = adventurePattern.firstMatch(line);
      if (adventureMatch != null && _looksLikeStructuralHeading(line) && _hasSubstantiveBody(lines, i)) {
        final numberText = adventureMatch.group(1)!;
        markers.add(_ChapterMarker(line: i, number: int.tryParse(numberText) ?? _romanToInt(numberText), heading: _cleanStructuralHeading(adventureMatch.group(2)!)));
        continue;
      }
      final romanMatch = romanPattern.firstMatch(line);
      if (romanMatch != null && _hasSubstantiveBody(lines, i)) {
        final roman = romanMatch.group(1)!;
        markers.add(_ChapterMarker(line: i, number: _romanToInt(roman), heading: 'Chapter $roman'));
        continue;
      }
      if (_looksLikeStructuralHeading(line) && _hasSubstantiveBody(lines, i)) {
        markers.add(_ChapterMarker(line: i, number: null, heading: _cleanStructuralHeading(line)));
      }
    }
    return markers;
  }

  bool _hasSubstantiveBody(List<String> lines, int markerLine) {
    final text = lines.sublist(markerLine + 1).take(80).join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return _looksLikeChapterBody(text);
  }

  bool _looksLikeStructuralHeading(String line) {
    final value = line.trim();
    if (value.length < 5 || value.length > 120 || !RegExp(r'[A-Za-z]').hasMatch(value)) return false;
    if (RegExp(r'^[IVXLCDM]{1,8}\.?\s+').hasMatch(value)) return false;
    const excluded = {'CONTENTS', 'ILLUSTRATIONS', 'PREFACE', 'INTRODUCTION', 'APPENDIX', 'NOTES', 'TRANSCRIBER NOTES', 'PROJECT GUTENBERG'};
    if (excluded.contains(value.toUpperCase())) return false;
    final letters = value.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length < 5) return false;
    final lowerLetters = letters.replaceAll(RegExp(r'[A-Z]'), '');
    return lowerLetters.length / letters.length < 0.35;
  }

  String _cleanStructuralHeading(String value) => value.replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'^[|—–:.-]+|[|—–:.-]+$'), '').trim();
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

      if (_looksLikeChapterBody(sectionText)) {
        selected.add(marker);
      }
    }

    final substantive = _removeDuplicateChapterMarkers(selected);
    final firstExplicit = substantive.indexWhere(_isExplicitSectionMarker);
    if (firstExplicit <= 0) return substantive;

    // Gutenberg editions often place all-caps title-page or front-matter
    // headings before the first real CHAPTER/ADVENTURE marker. Once a
    // conventional numbered section is established, those preamble headings
    // must not become reader-visible chapters.
    return substantive.sublist(firstExplicit);
  }

  bool _isExplicitSectionMarker(_ChapterMarker marker) => marker.number != null;
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
    final text = lines.join('\n');
    return text
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

  Chapter _chapterFromParagraphs(String title, List<String> paragraphs, int index) {
    final passage = paragraphs.isEmpty ? const ['This chapter contains no readable text in the downloaded edition.'] : paragraphs;
    final first = passage.first;
    return Chapter(
      id: 'chapter-${index + 1}', title: title, passage: passage,
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
      'estate': 'Warm drawing rooms, a garden beyond the windows, and the quiet after a family turning point.',
      'sea': 'Open water, wind, shifting clouds, and a vessel moving through a wide horizon.',
      'forest': 'Deep trees, filtered light, a narrow path, and the sense that something lies beyond it.',
      'city': 'A living street, distant windows, moving silhouettes, and the pulse of a crowded city.',
      'interior': 'A quiet interior shaped by lamplight, furniture, and the people gathered inside.',
      'night': 'A dark landscape under moving clouds, with a small source of light holding the eye.',
      'journey': 'A road leads forward through a changing landscape, keeping the next destination just out of sight.',
      'battle': 'Smoke, movement, scattered light, and opposing forces turn the landscape into a place of action.',
      'neutral': 'The visual world follows the place, people, and action described in this passage.',
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
    if (RegExp(r'\b(?:mrs\.? bennet|bennet|darcy|elizabeth|gardiner|derbyshire|married|marriage|daughter|family|drawing room|garden|parlour|parlor)\b').hasMatch(text)) return 'estate';
    if (RegExp(r'\b(?:ship|ships|whale|ocean|sea|sailor|sailing|harbour|harbor|captain|mast|deck|wave|waves)\b').hasMatch(text)) return 'sea';
    if (RegExp(r'\b(?:forest|woods|woodland|tree|trees|grove|wilderness)\b').hasMatch(text)) return 'forest';
    if (RegExp(r'\b(?:street|city|town|london|paris|market|shop|shops|crowd|carriage|station)\b').hasMatch(text)) return 'city';
    if (RegExp(r'\b(?:room|house|home|hall|library|study|bedroom|fireplace|table|door|window|lamp|candle)\b').hasMatch(text)) return 'interior';
    if (RegExp(r'\b(?:night|midnight|moon|moonlight|darkness|stars|starry)\b').hasMatch(text)) return 'night';
    if (RegExp(r'\b(?:road|journey|travel|traveler|traveller|horse|horses|coach|roadside|departure)\b').hasMatch(text)) return 'journey';
    if (RegExp(r'\b(?:battle|army|soldier|soldiers|war|weapon|weapons|fight|fought|enemy|cannon)\b').hasMatch(text)) return 'battle';
    return 'neutral';
  }
  String _stripGutenbergWrapper(String text) {
    final start = RegExp(r'\*\*\* START OF (?:THE )?PROJECT GUTENBERG EBOOK[^\n]*\*\*\*');
    final end = RegExp(r'\*\*\* END OF (?:THE )?PROJECT GUTENBERG EBOOK[^\n]*\*\*\*');
    final startMatch = start.firstMatch(text);
    final endMatch = end.firstMatch(text);
    return text.substring(startMatch?.end ?? 0, endMatch?.start ?? text.length).trim();
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
