import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/core/theme/app_theme.dart';
import 'package:nosiva/core/widgets/nosiva_button.dart';

void main() {
  testWidgets('NosivaButton renders its label and fires onPressed',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NosivaButton(
            label: 'Slay',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Slay'), findsOneWidget);
    await tester.tap(find.byType(NosivaButton));
    expect(tapped, isTrue);
  });
}
