import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/book.dart';
import 'gutenberg_service.dart';

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
  final GutenbergService _gutenberg = GutenbergService();
  final Map<String, Book> _cache = {};
  final Map<String, String> _rawTextCache = {};
  final Map<String, Future<String>> _rawTextInFlight = {};

  static const _canonicalGutenbergIds = <String, int>{
    'pride and prejudice|jane austen': 1342,
    'the adventures of sherlock holmes|arthur conan doyle': 1661,
    'moby dick or the whale|herman melville': 2701,
    'frankenstein or the modern prometheus|mary wollstonecraft shelley': 84,
    'dracula|bram stoker': 345,
    'great expectations|charles dickens': 1400,
    'the picture of dorian gray|oscar wilde': 174,
  };

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
        '&fields=key,title,author_name,cover_i,ia,ebook_access,editions.docs.language,editions.docs.identifiers.project_gutenberg'
        '&limit=20',
      );
      final results = await _search(uri);
      if (results.isNotEmpty) return results;
    } catch (_) {
      // The local classic set keeps the Library usable during catalog outages.
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
          'fields': 'key,title,author_name,cover_i,ia,ebook_access,editions.docs.language,editions.docs.identifiers.project_gutenberg',
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
    final response = await _client.get(uri).timeout(const Duration(seconds: 5));
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
    final title = map['title'] as String? ?? 'Untitled';
    final author = authors.isEmpty ? 'Unknown author' : authors.first.toString();
    final archiveIds = (map['ia'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();
    final coverId = map['cover_i'] as int?;
    final gutenbergId =
        _canonicalGutenbergId(title, author) ?? _projectGutenbergId(map);

    return LibraryBookSummary(
      id: (map['key'] as String? ?? '').replaceFirst('/works/', 'openlibrary-'),
      title: title,
      author: author,
      downloadCount: 0,
      coverUrl: coverId == null
          ? null
          : 'https://covers.openlibrary.org/b/id/$coverId-M.jpg',
      archiveIds: archiveIds,
      gutenbergId: gutenbergId,
    );
  }

  Future<Book> loadBook(LibraryBookSummary summary) async {
    final cached = _cache[summary.id];
    if (cached != null) return cached;

    if (summary.gutenbergId != null) {
      final book = await _gutenberg.loadBook(
        GutenbergBookSummary(
          id: summary.gutenbergId!,
          title: summary.title,
          author: summary.author,
          downloadCount: summary.downloadCount,
          coverUrl: summary.coverUrl,
        ),
      );
      _cache[summary.id] = book;
      return book;
    }

    if (summary.archiveIds.isEmpty) {
      throw Exception('No trusted public text source is available for ' + summary.title + '.');
    }

    Object? lastError;
    try {
      final text = await _firstSuccessful<String>(
        summary.archiveIds.take(4).map(_loadArchiveTextCached).toList(),
      );
      final book = _parseText(summary, text);
      _cache[summary.id] = book;
      return book;
    } catch (error) {
      lastError = error;
    }

    throw Exception(
      'Could not download ' + summary.title + (lastError == null ? '' : ': ' + lastError.toString()),
    );
  }

  Book _parseText(LibraryBookSummary summary, String text) {
    return _gutenberg.parseText(
      GutenbergBookSummary(
        id: summary.gutenbergId ?? summary.id.hashCode.abs(),
        title: summary.title,
        author: summary.author,
        downloadCount: summary.downloadCount,
        coverUrl: summary.coverUrl,
      ),
      text,
    );
  }

  Future<String> _loadArchiveTextCached(String archiveId) async {
    final cached = _rawTextCache[archiveId];
    if (cached != null) return cached;
    final existing = _rawTextInFlight[archiveId];
    if (existing != null) return existing;
    final future = _loadArchiveText(archiveId);
    _rawTextInFlight[archiveId] = future;
    try {
      final text = await future;
      _rawTextCache[archiveId] = text;
      return text;
    } finally {
      if (identical(_rawTextInFlight[archiveId], future)) {
        _rawTextInFlight.remove(archiveId);
      }
    }
  }

  Future<String> _loadArchiveText(String archiveId) async {
    final metadataResponse = await _client
        .get(Uri.parse('https://archive.org/metadata/' + archiveId))
        .timeout(const Duration(seconds: 6));
    if (metadataResponse.statusCode != 200) {
      throw Exception('Internet Archive metadata returned HTTP ' + metadataResponse.statusCode.toString() + '.');
    }
    final metadata = jsonDecode(metadataResponse.body) as Map<String, dynamic>;
    final files = metadata['files'] as List<dynamic>? ?? const [];
    final textFile = _findTextFile(files);
    if (textFile == null) {
      throw Exception('No plain-text file is available for this edition.');
    }
    final fileName = textFile['name'] as String;
    final uri = Uri.parse(
      'https://archive.org/download/' + archiveId + '/' + Uri.encodeComponent(fileName),
    );
    final response = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Internet Archive text returned HTTP ' + response.statusCode.toString() + '.');
    }
    return _decodeText(response.bodyBytes);
  }

  String _decodeText(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  Future<T> _firstSuccessful<T>(List<Future<T>> attempts) {
    final completer = Completer<T>();
    var remaining = attempts.length;
    Object? lastError;
    for (final attempt in attempts) {
      attempt.then(
        (value) {
          if (!completer.isCompleted) completer.complete(value);
        },
        onError: (Object error, StackTrace stack) {
          lastError = error;
          remaining -= 1;
          if (remaining == 0 && !completer.isCompleted) {
            completer.completeError(lastError!, stack);
          }
        },
      );
    }
    return completer.future;
  }

  int? _canonicalGutenbergId(String title, String author) {
    final key = _normalizeIdentity(title) + '|' + _normalizeIdentity(author);
    return _canonicalGutenbergIds[key];
  }

  int? _projectGutenbergId(Map<String, dynamic> map) {
    final editions = map['editions'];
    if (editions is! Map<String, dynamic>) return null;
    final docs = editions['docs'];
    if (docs is! List) return null;
    for (final doc in docs.whereType<Map<String, dynamic>>()) {
      final direct = doc['project_gutenberg'];
      final identifiers = doc['identifiers'];
      if (direct is List && direct.isNotEmpty) {
        final id = int.tryParse(direct.first.toString());
        if (id != null) return id;
      }
      if (identifiers is Map<String, dynamic>) {
        final ids = identifiers['project_gutenberg'];
        if (ids is List && ids.isNotEmpty) {
          final id = int.tryParse(ids.first.toString());
          if (id != null) return id;
        }
      }
    }
    return null;
  }

  String _normalizeIdentity(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

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
        final response = await _client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 20));
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
}
