import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/nosiva_button.dart';
import '../../../../core/widgets/nosiva_chip.dart';
import '../../../../core/widgets/nosiva_text_field.dart';
import '../../domain/listing_enums.dart';
import '../../domain/listing_filter.dart';
import '../../domain/listing_l10n.dart';
import '../controllers/feed_controller.dart';

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
  bool _detectingLocation = false;

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

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      _location.text = await ref.read(locationServiceProvider).currentCity();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  void _apply() {
    final location = _location.text.trim();
    ref.read(feedFilterProvider.notifier).state = _draft.copyWith(
      minPrice: _min.text.isEmpty ? null : double.tryParse(_min.text),
      maxPrice: _max.text.isEmpty ? null : double.tryParse(_max.text),
      location: location.isEmpty ? null : location,
      clearMinPrice: _min.text.isEmpty,
      clearMaxPrice: _max.text.isEmpty,
      clearLocation: location.isEmpty,
      styleTags: _draft.styleTags,
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
          Text(context.l10n.filters, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          Text(context.l10n.category, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in ListingCategory.values)
                NosivaChip(
                  label: c.localizedWithEmoji(context.l10n),
                  selected: _draft.category == c,
                  onTap: () => setState(() => _draft = _draft.category == c
                      ? _draft.copyWith(clearCategory: true)
                      : _draft.copyWith(category: c)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(context.l10n.condition, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in ItemCondition.values)
                NosivaChip(
                  label: c.localizedLabel(context.l10n),
                  selected: _draft.condition == c,
                  onTap: () =>
                      setState(() => _draft = _draft.copyWith(condition: c)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(context.l10n.size, style: theme.textTheme.titleMedium),
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
          Text(context.l10n.style, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final tag in kStyleTags)
                NosivaChip(
                  label: localizedStyleTag(tag, context.l10n),
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
          Text(context.l10n.location, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          NosivaTextField(
            hint: context.l10n.cityOrCountry,
            controller: _location,
            prefixIcon: Icons.place_outlined,
            suffixIcon: _detectingLocation
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.hotPink),
                    ),
                  )
                : IconButton(
                    tooltip: context.l10n.useMyLocation,
                    icon: const Icon(Icons.my_location_rounded,
                        color: AppColors.hotPink),
                    onPressed: _detectLocation,
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(context.l10n.priceRange, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: NosivaTextField(
                  hint: context.l10n.min,
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
                  hint: context.l10n.max,
                  controller: _max,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          NosivaButton(
            label: context.l10n.showResults,
            variant: NosivaButtonVariant.gradient,
            onPressed: _apply,
          ),
        ],
      ),
    );
  }
}
