import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/nosiva_chip.dart';
import '../../domain/listing_enums.dart';

/// Letter sizes as quick picks, plus "Other" for anything else — shoe sizes,
/// jeans W/L, "One size", … Tapping the selected size again clears it.
class SizePicker extends StatelessWidget {
  const SizePicker({super.key, required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  // Letters (incl. Cyrillic), digits, spaces and . / - ( ) only.
  static final _allowed = RegExp(r'^[\p{L}\p{N} ./\-()]+$', unicode: true);

  /// Tidies a typed size; null when it isn't acceptable.
  static String? normalize(String input) {
    final size = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (size.isEmpty || size.length > kMaxCustomSizeLength) return null;
    if (!_allowed.hasMatch(size)) return null;
    // "m" → "M", so typed letter sizes match the quick picks and filters.
    final upper = size.toUpperCase();
    return kSizes.contains(upper) ? upper : size;
  }

  Future<void> _editCustom(BuildContext context, String? current) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _CustomSizeDialog(initial: current),
    );
    if (result == null) return; // cancelled
    onChanged(result.isEmpty ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    final custom = value != null && !kSizes.contains(value) ? value : null;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final s in kSizes)
          NosivaChip(
            label: s,
            selected: value == s,
            onTap: () => onChanged(value == s ? null : s),
          ),
        NosivaChip(
          label: custom ?? context.l10n.otherSize,
          icon: custom == null ? Icons.add_rounded : Icons.edit_outlined,
          selected: custom != null,
          onTap: () => _editCustom(context, custom),
        ),
      ],
    );
  }
}

/// Returns the new size, '' to remove it, or null when cancelled.
class _CustomSizeDialog extends StatefulWidget {
  const _CustomSizeDialog({this.initial});
  final String? initial;

  @override
  State<_CustomSizeDialog> createState() => _CustomSizeDialogState();
}

class _CustomSizeDialogState extends State<_CustomSizeDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final size = SizePicker.normalize(_controller.text);
    if (size == null) {
      setState(() => _error = context.l10n.customSizeInvalid);
      return;
    }
    Navigator.of(context).pop(size);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.customSizeTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: kMaxCustomSizeLength,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        decoration: InputDecoration(
          hintText: l10n.customSizeHint,
          errorText: _error,
          errorMaxLines: 2,
        ),
      ),
      actions: [
        if (widget.initial != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(
              l10n.remove,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
