import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_chip.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../data/safety_repository.dart';
import '../domain/report.dart';

/// Asks why a user or listing is being reported and submits the report.
Future<void> showReportSheet(
  BuildContext context, {
  required String targetType,
  required String targetId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ReportSheet(targetType: targetType, targetId: targetId),
  );
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.targetType, required this.targetId});
  final String targetType;
  final String targetId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _details = TextEditingController();
  ReportReason? _reason;
  bool _sending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  String _label(ReportReason reason) {
    final l10n = context.l10n;
    return switch (reason) {
      ReportReason.spam => l10n.reasonSpam,
      ReportReason.scam => l10n.reasonScam,
      ReportReason.inappropriate => l10n.reasonInappropriate,
      ReportReason.harassment => l10n.reasonHarassment,
      ReportReason.counterfeit => l10n.reasonCounterfeit,
      ReportReason.other => l10n.reasonOther,
    };
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null) return;
    setState(() => _sending = true);
    final details = _details.text.trim();
    try {
      await ref.read(safetyRepositoryProvider).report(
            targetType: widget.targetType,
            targetId: widget.targetId,
            reason: reason,
            details: details.isEmpty ? null : details,
          );
      if (!mounted) return;
      context.showSuccess(context.l10n.reportSent);
      Navigator.of(context).pop();
    } on AlreadyReportedException {
      if (!mounted) return;
      context.showError(context.l10n.reportAlready);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        context.showError(context.l10n.reportFailed('$e'));
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.reportTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(context.l10n.reportWhy, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final reason in ReportReason.values)
                NosivaChip(
                  label: _label(reason),
                  selected: _reason == reason,
                  onTap: () => setState(() => _reason = reason),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          NosivaTextField(
            hint: context.l10n.reportDetailsHint,
            controller: _details,
            maxLines: 3,
            maxLength: 500,
          ),
          const SizedBox(height: AppSpacing.lg),
          NosivaButton(
            label: context.l10n.sendReportCta,
            loading: _sending,
            variant: NosivaButtonVariant.gradient,
            onPressed: _reason == null ? null : _submit,
          ),
        ],
      ),
    );
  }
}
