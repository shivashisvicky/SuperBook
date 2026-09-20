import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superbook/app.dart';

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

  testWidgets('experience is deterministic', (tester) async {
    await tester.pumpWidget(const SuperBookApp());
    await tester.tap(find.text('The Little House'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Experience'));
    await tester.pumpAndSettle();
    expect(find.text('EXPERIENCE'), findsOneWidget);
    expect(find.text('The old house waits in the rain.'), findsOneWidget);
  });
}
