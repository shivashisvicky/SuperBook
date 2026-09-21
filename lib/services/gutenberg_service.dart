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
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Gutenberg catalog request failed (${response.statusCode}).');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
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
    final response = await _client.get(Uri.parse('https://gutendex.com/books/${summary.id}'));
    if (response.statusCode != 200) throw Exception('Could not load book ${summary.title}.');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final formats = data['formats'] as Map<String, dynamic>? ?? const {};
    final textUrl = _textUrl(formats);
    if (textUrl == null) throw Exception('No plain-text edition is available for ${summary.title}.');
    final textResponse = await _client.get(Uri.parse(textUrl));
    if (textResponse.statusCode != 200) throw Exception('Could not download ${summary.title}.');
    final text = utf8.decode(textResponse.bodyBytes, allowMalformed: true);
    final book = _toBook(summary, text);
    _cache[summary.id] = book;
    return book;
  }

  String? _textUrl(Map<String, dynamic> formats) {
    for (final entry in formats.entries) {
      if (entry.key.startsWith('text/plain')) return entry.value as String?;
    }
    return null;
  }

  Book _toBook(GutenbergBookSummary summary, String rawText) {
    final cleaned = _stripGutenbergWrapper(rawText);
    final blocks = cleaned
        .replaceAll('\r\n', '\n').replaceAll('\r', '\n')
        .split(RegExp(r'\n\s*\n'))
        .map((block) => block.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((block) => block.length > 30).toList();
    final lines = cleaned.split('\n');
    final markers = <_ChapterMarker>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final match = RegExp(r'^(?:CHAPTER|Chapter)\s+([IVXLCDM]+|\d+)\.?\s*(.*)$').firstMatch(line);
      if (match != null) markers.add(_ChapterMarker(i, match.group(2)!));
    }
    final chapters = <Chapter>[];
    if (markers.isEmpty) {
      chapters.add(_chapterFromParagraphs('Book', blocks, 0));
    } else {
      for (var i = 0; i < markers.length; i++) {
        final start = markers[i].line;
        final end = i + 1 < markers.length ? markers[i + 1].line : lines.length;
        final section = lines.sublist(start + 1, end).join('\n')
            .split(RegExp(r'\n\s*\n'))
            .map((p) => p.replaceAll(RegExp(r'\s+'), ' ').trim())
            .where((p) => p.length > 30).toList();
        final heading = markers[i].heading.isEmpty ? 'Chapter ${i + 1}' : markers[i].heading;
        chapters.add(_chapterFromParagraphs(heading, section, i));
      }
    }
    final safeChapters = chapters.isEmpty ? [_chapterFromParagraphs('Book', blocks, 0)] : chapters;
    final beats = [
      for (var i = 0; i < safeChapters.length; i++) NarrativeBeat(
        title: safeChapters[i].title,
        summary: safeChapters[i].passage.first,
        chapterId: safeChapters[i].id,
        intensity: 1,
      ),
    ];
    return Book(
      id: 'gutenberg-${summary.id}', title: summary.title, author: summary.author,
      description: 'Original public-domain text from Project Gutenberg.', chapters: safeChapters,
      characters: const [], locations: const [], objects: const [], beats: beats,
    );
  }

  Chapter _chapterFromParagraphs(String title, List<String> paragraphs, int index) {
    final passage = paragraphs.isEmpty ? const ['This chapter contains no readable text in the downloaded edition.'] : paragraphs;
    final first = passage.first;
    return Chapter(
      id: 'chapter-${index + 1}', title: title, passage: passage,
      scene: Scene(title: title, moment: 'A scene from the original text.',
        atmosphere: 'A living page waiting to be experienced.',
        caption: first.length > 150 ? '${first.substring(0, 147)}...' : first),
    );
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
  const _ChapterMarker(this.line, this.heading);
  final int line;
    final String heading;
}