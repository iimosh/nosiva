import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/features/auth/presentation/verify_email_screen.dart';
import 'package:nosiva/l10n/app_localizations.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const VerifyEmailScreen(email: 'ana@example.com'),
      ),
    ));
    await tester.pump();
  }

  testWidgets('says where the code went and checks it is 6 digits',
      (tester) async {
    await pumpScreen(tester);
    expect(find.textContaining('ana@example.com'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '12a4');
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(find.text('Enter the 6-digit code'), findsOneWidget);

    // Leave no countdown running behind the test.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('"send a new code" waits 30 seconds between tries',
      (tester) async {
    await pumpScreen(tester);
    expect(find.text('Send a new code in 30 s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Send a new code in 20 s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Send a new code'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
