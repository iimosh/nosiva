import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/core/widgets/nosiva_wordmark.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('wordmark loads and keeps its proportions (${brightness.name})',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: const Scaffold(body: Center(child: NosivaWordmark(height: 28))),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final size = tester.getSize(find.byType(NosivaWordmark));
      expect(size.height, 28);
      expect(size.width, closeTo(28 * NosivaWordmark.aspectRatio, 0.5));
      expect(find.bySemanticsLabel('Nosiva'), findsOneWidget);
    });
  }
}
