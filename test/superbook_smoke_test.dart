import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superbook/app.dart';
import 'package:superbook/features/scenes/scene_player_screen.dart';

void main() {
  testWidgets('library opens', (tester) async {
    await tester.pumpWidget(const SuperBookApp());
    expect(find.text('SUPERBOOK'), findsOneWidget);
    expect(find.text('The Little House'), findsOneWidget);
  });

  testWidgets('reader opens', (tester) async {
    await tester.pumpWidget(const SuperBookApp());
    await tester.tap(find.text('The Little House'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('The Old House'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('experience enters the playable scene', (tester) async {
    await tester.pumpWidget(const SuperBookApp());
    await tester.tap(find.text('The Little House'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Experience'));
    await tester.pumpAndSettle();

    expect(find.text('EXPERIENCE'), findsOneWidget);
    expect(find.text('A quiet house waits at the edge of the storm.'), findsOneWidget);

    await tester.ensureVisible(find.text('Tap to enter the scene'));
    await tester.tap(find.text('Tap to enter the scene'));
    await tester.pumpAndSettle();

    expect(find.byType(ScenePlayerScreen), findsOneWidget);
    expect(find.text('Narrative beat · intensity 2'), findsOneWidget);
  });
}
