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
      find.text('Public-domain stories from Project Gutenberg.'),
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
        matching: find.text('The Old House'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('experience enters the playable scene', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReaderScreen(book: demoBook)),
    );
    await tester.tap(find.byTooltip('Experience'));
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tap to enter the scene'));
    await tester.pump();

    expect(find.byType(ScenePlayerScreen), findsOneWidget);
    expect(find.text('Narrative beat · intensity 2'), findsOneWidget);
  });
}
