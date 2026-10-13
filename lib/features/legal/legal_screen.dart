import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_info.dart';
import '../../core/l10n/l10n_extensions.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import 'legal_content.dart';

/// The privacy policy or terms of use, in the app's language. Open to
/// everyone, signed in or not.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final sections = legalSections(document, locale.languageCode);
    final updated =
        DateFormat.yMMMMd(locale.toLanguageTag()).format(AppInfo.legalUpdated);
    final body = theme.textTheme.bodyMedium?.copyWith(height: 1.5);

    return Scaffold(
      appBar: AppBar(
        title: Text(document == LegalDocument.privacy
            ? l10n.privacyPolicy
            : l10n.termsOfUse),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
          children: [
            Text(
              l10n.legalLastUpdated(updated),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            for (final section in sections) ...[
              if (section.heading.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  child: Text(section.heading,
                      style: theme.textTheme.titleMedium),
                ),
              ],
              for (final line in section.lines)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: line.startsWith('• ')
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('•  ', style: body),
                            Expanded(child: Text(line.substring(2), style: body)),
                          ],
                        )
                      : Text(line, style: body),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "By continuing, you agree to the Terms of use and Privacy policy", with
/// both names opening the documents. Shown where accounts are created.
class LegalConsentText extends StatefulWidget {
  const LegalConsentText({super.key});

  @override
  State<LegalConsentText> createState() => _LegalConsentTextState();
}

class _LegalConsentTextState extends State<LegalConsentText> {
  late final _terms = TapGestureRecognizer()
    ..onTap = () => context.push(AppRoutes.terms);
  late final _privacy = TapGestureRecognizer()
    ..onTap = () => context.push(AppRoutes.privacy);

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final style = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final link = style?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    );

    // The sentence is translated as three pieces around the two links so
    // each language can order its words naturally.
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: l10n.legalConsentStart),
          TextSpan(text: l10n.termsOfUse, style: link, recognizer: _terms),
          TextSpan(text: l10n.legalConsentMiddle),
          TextSpan(text: l10n.privacyPolicy, style: link, recognizer: _privacy),
          TextSpan(text: l10n.legalConsentEnd),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
