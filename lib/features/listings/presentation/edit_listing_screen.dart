import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_chip.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../data/listings_repository.dart';
import '../domain/listing.dart';
import '../domain/listing_enums.dart';
import '../domain/listing_l10n.dart';
import 'controllers/feed_controller.dart';
import 'controllers/listing_detail_provider.dart';

class EditListingScreen extends ConsumerWidget {
  const EditListingScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingDetailProvider(listingId));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.editListing)),
      body: listingAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.hotPink),
        ),
        error: (e, _) => ErrorStateView(
          message: '$e',
          onRetry: () => ref.invalidate(listingDetailProvider(listingId)),
        ),
        data: (listing) {
          final uid = ref.watch(currentAuthUserProvider)?.id;
          if (uid != listing.sellerId) {
            return EmptyStateView(
              title: context.l10n.listingNotYours,
              message: context.l10n.onlySellerCanEdit,
            );
          }
          return _EditListingForm(
            key: ValueKey(listing.id),
            listing: listing,
          );
        },
      ),
    );
  }
}

class _EditListingForm extends ConsumerStatefulWidget {
  const _EditListingForm({super.key, required this.listing});

  final Listing listing;

  @override
  ConsumerState<_EditListingForm> createState() => _EditListingFormState();
}

class _EditListingFormState extends ConsumerState<_EditListingForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _brand;
  late final TextEditingController _color;
  late final TextEditingController _location;
  late final TextEditingController _price;

  late ListingCategory _category;
  late ItemCondition _condition;
  late ListingStatus _status;
  String? _size;
  late final Set<String> _styleTags;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final listing = widget.listing;
    _title = TextEditingController(text: listing.title);
    _description = TextEditingController(text: listing.description);
    _brand = TextEditingController(text: listing.brand ?? '');
    _color = TextEditingController(text: listing.color ?? '');
    _location = TextEditingController(text: listing.location ?? '');
    _price = TextEditingController(text: listing.price.toString());
    _category = listing.categoryEnum;
    _condition = listing.conditionEnum;
    _status = listing.statusEnum;
    _size = listing.size;
    _styleTags = {...listing.styleTags};
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _brand.dispose();
    _color.dispose();
    _location.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final listing = widget.listing;
      await ref.read(listingsRepositoryProvider).updateListing(
        listing.id,
        {
          'title': _title.text.trim(),
          'description': _description.text.trim(),
          'category': _category.value,
          'condition': _condition.value,
          'status': _status.value,
          'price': double.parse(_price.text.trim()),
          'brand': _nullable(_brand.text),
          'color': _nullable(_color.text),
          'location': _nullable(_location.text),
          'size': _size,
          'style_tags': _styleTags.toList(),
        },
      );

      ref.invalidate(listingDetailProvider(listing.id));
      ref.invalidate(sellerListingsProvider(listing.sellerId));
      ref.invalidate(similarListingsProvider(listing.categoryEnum));
      ref.invalidate(similarListingsProvider(_category));
      ref.invalidate(feedControllerProvider);

      if (mounted) {
        context.showSuccess(context.l10n.listingUpdated);
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showError(context.l10n.updateListingFailed('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(context.l10n.photos),
              _ExistingPhotos(listing: listing),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(context.l10n.basicInfo),
              NosivaTextField(
                label: context.l10n.title,
                hint: context.l10n.listingTitleHint,
                controller: _title,
                validator: (v) => Validators.minLength(v, 3, field: 'Title'),
              ),
              const SizedBox(height: AppSpacing.md),
              NosivaTextField(
                label: context.l10n.description,
                hint: context.l10n.listingDescriptionHint,
                controller: _description,
                maxLines: 4,
                maxLength: 1000,
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionTitle(context.l10n.itemDetails),
              _Label(context.l10n.category),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final c in ListingCategory.values)
                    NosivaChip(
                      label: c.localizedWithEmoji(context.l10n),
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _Label(context.l10n.condition),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final c in ItemCondition.values)
                    NosivaChip(
                      label: c.localizedLabel(context.l10n),
                      selected: _condition == c,
                      onTap: () => setState(() => _condition = c),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _Label(context.l10n.status),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final status in ListingStatus.values)
                    NosivaChip(
                      label: _statusLabel(status),
                      selected: _status == status,
                      onTap: () => setState(() => _status = status),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _Label(context.l10n.size),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final s in kSizes)
                    NosivaChip(
                      label: s,
                      selected: _size == s,
                      onTap: () =>
                          setState(() => _size = _size == s ? null : s),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: NosivaTextField(
                      label: context.l10n.brand,
                      hint: context.l10n.brandHint,
                      controller: _brand,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: NosivaTextField(
                      label: context.l10n.color,
                      hint: context.l10n.colorHint,
                      controller: _color,
                    ),
                  ),
                ],
              ),
              _Label(context.l10n.styleTags),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final tag in kStyleTags)
                    NosivaChip(
                      label: localizedStyleTag(tag, context.l10n),
                      selected: _styleTags.contains(tag),
                      onTap: () => setState(() {
                        _styleTags.contains(tag)
                            ? _styleTags.remove(tag)
                            : _styleTags.add(tag);
                      }),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionTitle(context.l10n.pricingAndLocation),
              NosivaTextField(
                label: context.l10n.location,
                hint: context.l10n.cityCountry,
                controller: _location,
                prefixIcon: Icons.place_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
              NosivaTextField(
                label: context.l10n.priceUsd,
                hint: context.l10n.priceHint,
                controller: _price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.payments_outlined,
                validator: Validators.price,
              ),
              const SizedBox(height: AppSpacing.xl),
              NosivaButton(
                label: context.l10n.saveChanges,
                loading: _saving,
                variant: NosivaButtonVariant.gradient,
                onPressed: _save,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(ListingStatus status) {
    return switch (status) {
      ListingStatus.active => context.l10n.active,
      ListingStatus.reserved => context.l10n.reserved,
      ListingStatus.sold => context.l10n.sold,
      ListingStatus.hidden => context.l10n.hidden,
    };
  }
}

class _ExistingPhotos extends StatelessWidget {
  const _ExistingPhotos({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    if (listing.images.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: listing.images.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: AppRadii.field,
          child: CachedNetworkImage(
            imageUrl: listing.images[i].imageUrl,
            height: 100,
            width: 100,
            fit: BoxFit.cover,
            placeholder: (_, __) => const ColoredBox(color: AppColors.blush),
            errorWidget: (_, __, ___) => const ColoredBox(
              color: AppColors.blush,
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: theme.textTheme.titleLarge?.copyWith(color: AppColors.berry),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
