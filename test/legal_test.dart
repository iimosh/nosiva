import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/core/config/app_info.dart';
import 'package:nosiva/features/legal/legal_content.dart';
import 'package:nosiva/features/legal/legal_screen.dart';
import 'package:nosiva/l10n/app_localizations.dart';

void main() {
  for (final doc in LegalDocument.values) {
    test('${doc.name}: English and Macedonian have the same sections', () {
      final en = legalSections(doc, 'en');
      final mk = legalSections(doc, 'mk');
      expect(mk.length, en.length);
      for (var i = 0; i < en.length; i++) {
        expect(mk[i].lines.length, en[i].lines.length,
            reason: 'section ${en[i].heading}');
      }
      expect(en.expand((s) => s.lines).join(), contains(AppInfo.supportEmail));
      expect(mk.expand((s) => s.lines).join(), contains(AppInfo.supportEmail));
    });
  }

  for (final locale in const [Locale('en'), Locale('mk')]) {
    testWidgets('privacy policy renders in ${locale.languageCode}',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LegalScreen(document: LegalDocument.privacy),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ListView), findsOneWidget);
    });
  }
}
