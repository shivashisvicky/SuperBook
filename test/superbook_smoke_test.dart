import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superbook/app.dart';
import 'package:superbook/domain/book.dart';
import 'package:superbook/features/reader/reader_screen.dart';
import 'package:superbook/features/scenes/scene_player_screen.dart';

void main() {
  testWidgets('library shows the real-book catalog', (tester) async {
    await tester.pumpWidget(const SuperBookApp());
    await tester.tap(find.text('Library'));
    await tester.pump();

    expect(find.text('LIBRARY'), findsOneWidget);
    expect(find.text('Real books'), findsOneWidget);
    expect(
      find.text(
        'Public-domain stories from Project Gutenberg. '
        'Tap a book to download its original text into the reader.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('reader opens', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReaderScreen(book: demoBook)),
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(demoBook.chapters.first.title),
      ),
      findsOneWidget,
    );
  });

  testWidgets('experience enters the playable scene', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReaderScreen(book: demoBook)),
    );
    await tester.tap(find.byTooltip('Experience'));
    await tester.pump();

    expect(find.text('EXPERIENCE'), findsOneWidget);
    expect(
      find.text('A quiet house waits at the edge of the storm.'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('experience-scene-entry')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('experience-scene-entry')));
    // Include routes during the transition/offstage phase without waiting
    // on the scene's intentionally repeating animation.
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byType(ScenePlayerScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Story moment', skipOffstage: false),
      findsOneWidget,
    );
  });
}
