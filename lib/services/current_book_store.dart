import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/book.dart';
import 'open_library_service.dart';

class CurrentBookStore {
  CurrentBookStore._();

  static final instance = CurrentBookStore._();

  static const _summaryKey = 'superbook.currentBook';
  static const _chapterKey = 'superbook.currentChapter';

  final currentBook = ValueNotifier<Book?>(null);
  final currentSummary = ValueNotifier<LibraryBookSummary?>(null);
  final currentChapterIndex = ValueNotifier<int>(0);

  late final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  Future<void>? _restoreFuture;

  Future<void> restore() {
    return _restoreFuture ??= _restore();
  }

  Future<void> _restore() async {
    try {
      final raw = await _prefs.getString(_summaryKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final archiveIds = (data['archiveIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList();
      currentSummary.value = LibraryBookSummary(
        id: data['id'] as String,
        title: data['title'] as String,
        author: data['author'] as String,
        downloadCount: data['downloadCount'] as int? ?? 0,
        coverUrl: data['coverUrl'] as String?,
        archiveIds: archiveIds,
        gutenbergId: data['gutenbergId'] as int?,
      );
      currentChapterIndex.value = await _prefs.getInt(_chapterKey) ?? 0;
    } catch (_) {
      currentSummary.value = null;
      currentBook.value = null;
      currentChapterIndex.value = 0;
    }
    } catch (_) {
      // Persistence is optional. The reader remains fully usable in hosts
      // where the shared-preferences platform is not initialized.
    }
  }

  Future<void> setCurrent({
    required LibraryBookSummary summary,
    required Book book,
    int chapterIndex = 0,
  }) async {
    currentSummary.value = summary;
    currentBook.value = book;
    currentChapterIndex.value = chapterIndex;

    try {
      await _prefs.setString(
        _summaryKey,
        jsonEncode({
          'id': summary.id,
          'title': summary.title,
          'author': summary.author,
          'downloadCount': summary.downloadCount,
          'coverUrl': summary.coverUrl,
          'archiveIds': summary.archiveIds,
          'gutenbergId': summary.gutenbergId,
        }),
      );
      await _prefs.setInt(_chapterKey, chapterIndex);
    } catch (_) {
      // In-memory current state is still authoritative for the active session.
    }
  }

  Future<Book?> loadCurrent() async {
    await restore();
    final cached = currentBook.value;
    if (cached != null) return cached;

    final summary = currentSummary.value;
    if (summary == null) return null;

    final book = await OpenLibraryService().loadBook(summary);
    currentBook.value = book;
    return book;
  }

  Future<void> setChapter(int index) async {
    currentChapterIndex.value = index;
    try {
      await _prefs.setInt(_chapterKey, index);
    } catch (_) {
      // Ignore storage failures while keeping the active reader position.
    }
  }

  Future<void> clear() async {
    currentBook.value = null;
    currentSummary.value = null;
    currentChapterIndex.value = 0;
    try {
      await _prefs.remove(_summaryKey);
      await _prefs.remove(_chapterKey);
    } catch (_) {
      // Nothing else is required to clear the active in-memory state.
    }
  }

  void dispose() {
    currentBook.dispose();
    currentSummary.dispose();
    currentChapterIndex.dispose();
  }
}
