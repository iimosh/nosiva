import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/nosiva_button.dart';
import '../../../../core/widgets/nosiva_chip.dart';
import '../../../../core/widgets/nosiva_text_field.dart';
import '../../domain/listing_enums.dart';
import '../../domain/listing_filter.dart';
import '../controllers/feed_controller.dart';

/// The full listing-filter bottom sheet (category, condition, size, style,
/// location, price). Drives [feedFilterProvider]. Shown from Home.
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late ListingFilter _draft = ref.read(feedFilterProvider);
  final _min = TextEditingController();
  final _max = TextEditingController();
  final _location = TextEditingController();

  @override
  void initState() {
    super.initState();
    _min.text = _draft.minPrice?.toStringAsFixed(0) ?? '';
    _max.text = _draft.maxPrice?.toStringAsFixed(0) ?? '';
    _location.text = _draft.location ?? '';
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    _location.dispose();
    super.dispose();
  }

  void _apply() {
    final styles = _draft.styleTags;
    final location = _location.text.trim();
    ref.read(feedFilterProvider.notifier).state = _draft.copyWith(
      minPrice: _min.text.isEmpty ? null : double.tryParse(_min.text),
      maxPrice: _max.text.isEmpty ? null : double.tryParse(_max.text),
      location: location.isEmpty ? null : location,
      clearMinPrice: _min.text.isEmpty,
      clearMaxPrice: _max.text.isEmpty,
      clearLocation: location.isEmpty,
      styleTags: styles,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Filters', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          Text('Category', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in ListingCategory.values)
                NosivaChip(
                  label: '${c.emoji} ${c.label}',
                  selected: _draft.category == c,
                  onTap: () => setState(() => _draft = _draft.category == c
                      ? _draft.copyWith(clearCategory: true)
                      : _draft.copyWith(category: c)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Condition', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in ItemCondition.values)
                NosivaChip(
                  label: c.label,
                  selected: _draft.condition == c,
                  onTap: () =>
                      setState(() => _draft = _draft.copyWith(condition: c)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Size', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final s in kSizes)
                NosivaChip(
                  label: s,
                  selected: _draft.size == s,
                  onTap: () => setState(() => _draft = _draft.copyWith(size: s)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Style', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final tag in kStyleTags)
                NosivaChip(
                  label: tag,
                  selected: _draft.styleTags.contains(tag),
                  onTap: () => setState(() {
                    final next = [..._draft.styleTags];
                    next.contains(tag) ? next.remove(tag) : next.add(tag);
                    _draft = _draft.copyWith(styleTags: next);
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Location', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          NosivaTextField(
            hint: 'City or country',
            controller: _location,
            prefixIcon: Icons.place_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Price range', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: NosivaTextField(
                  hint: 'Min',
                  controller: _min,
                  keyboardType: TextInputType.number,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text('—'),
              ),
              Expanded(
                child: NosivaTextField(
                  hint: 'Max',
                  controller: _max,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          NosivaButton(
            label: 'Show results',
            variant: NosivaButtonVariant.gradient,
            onPressed: _apply,
          ),
        ],
      ),
    );
  }
}
