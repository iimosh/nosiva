import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/media/image_editing.dart';
import '../../../core/media/photo_editor_screen.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/fullscreen_image.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_chip.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../profile/presentation/profile_screen.dart';
import '../data/listings_repository.dart';
import '../domain/listing.dart';
import '../domain/listing_enums.dart';
import '../domain/listing_image.dart';
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

  final _picker = ImagePicker();
  late final List<_Photo> _photos;

  int get _photoCount => _photos.length;

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
    _photos = ([...listing.images]
          ..sort((a, b) => a.position.compareTo(b.position)))
        .map<_Photo>(_ExistingPhoto.new)
        .toList();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final files = await _picker.pickMultiImage(imageQuality: 80);
        for (final f in files) {
          _photos.add(_NewPhoto(
              (bytes: await f.readAsBytes(), ext: pickedImageExt(f.path))));
        }
      } else {
        final f = await _picker.pickImage(source: source, imageQuality: 80);
        if (f != null) {
          _photos.add(_NewPhoto(
              (bytes: await f.readAsBytes(), ext: pickedImageExt(f.path))));
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) context.showError(context.l10n.photoAddFailed('$e'));
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.chooseFromGallery),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(context.l10n.takePhoto),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pick(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _photoOptions(int i) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: Text(context.l10n.viewPhoto),
              onTap: () {
                Navigator.pop(sheetCtx);
                _view(_photos[i]);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune_rounded),
              title: Text(context.l10n.editPhoto),
              onTap: () {
                Navigator.pop(sheetCtx);
                _editAt(i);
              },
            ),
            if (i > 0)
              ListTile(
                leading: const Icon(Icons.arrow_back_rounded),
                title: Text(context.l10n.moveLeft),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _move(i, i - 1);
                },
              ),
            if (i < _photos.length - 1)
              ListTile(
                leading: const Icon(Icons.arrow_forward_rounded),
                title: Text(context.l10n.moveRight),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _move(i, i + 1);
                },
              ),
            ListTile(
              enabled: _photoCount > 1,
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(context.l10n.delete),
              subtitle: _photoCount > 1 ? null : Text(context.l10n.keepOnePhoto),
              onTap: _photoCount > 1
                  ? () {
                      Navigator.pop(sheetCtx);
                      setState(() => _photos.removeAt(i));
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _view(_Photo photo) {
    final ImageProvider provider = switch (photo) {
      _ExistingPhoto(:final image) => CachedNetworkImageProvider(image.imageUrl),
      _NewPhoto(:final picked) => MemoryImage(picked.bytes),
    };
    FullscreenImage.show(context, provider);
  }

  Future<void> _editAt(int i) async {
    try {
      // Load current bytes (existing images are downloaded on demand).
      final current = switch (_photos[i]) {
        _NewPhoto(:final picked) => picked,
        _ExistingPhoto(:final image) => await loadImage(image.imageUrl),
      };
      if (!mounted) return;
      final edited = await PhotoEditorScreen.open(context, current);
      if (edited == null || !mounted) return;
      // Editing an existing image turns it into a new upload (the old one is
      // detected as removed on save and deleted).
      setState(() => _photos[i] = _NewPhoto(edited));
    } catch (e) {
      if (mounted) context.showError(context.l10n.photoEditFailed('$e'));
    }
  }

  void _move(int from, int to) {
    setState(() {
      final p = _photos.removeAt(from);
      _photos.insert(to, p);
    });
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
    if (_photoCount == 0) {
      context.showError(context.l10n.keepOnePhoto);
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(listingsRepositoryProvider);
      final listing = widget.listing;
      await repo.updateListing(
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

      final keptIds =
          _photos.whereType<_ExistingPhoto>().map((p) => p.image.id).toSet();
      final newImages = <({Uint8List bytes, String ext, int position})>[];
      for (var i = 0; i < _photos.length; i++) {
        final p = _photos[i];
        if (p is _ExistingPhoto) {
          if (p.image.position != i) {
            await repo.updateImagePosition(p.image.id, i);
          }
        } else if (p is _NewPhoto) {
          newImages.add(
              (bytes: p.picked.bytes, ext: p.picked.ext, position: i));
        }
      }
      for (final image in listing.images) {
        if (!keptIds.contains(image.id)) await repo.deleteImage(image.id);
      }
      if (newImages.isNotEmpty) {
        await repo.addImagesAt(
          sellerId: listing.sellerId,
          listingId: listing.id,
          images: newImages,
        );
      }

      ref.invalidate(listingDetailProvider(listing.id));
      ref.invalidate(sellerListingsProvider(listing.sellerId));
      ref.invalidate(similarListingsProvider(listing.categoryEnum));
      ref.invalidate(similarListingsProvider(_category));
      ref.invalidate(feedControllerProvider);
      ref.invalidate(myListingsProvider);

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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(context.l10n.photos),
              _EditPhotoStrip(
                photos: _photos,
                onAdd: _showPickerSheet,
                onTap: _photoOptions,
              ),
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
      ListingStatus.sold => context.l10n.sold,
      ListingStatus.hidden => context.l10n.hidden,
    };
  }
}

sealed class _Photo {
  const _Photo();
}

class _ExistingPhoto extends _Photo {
  const _ExistingPhoto(this.image);
  final ListingImage image;
}

class _NewPhoto extends _Photo {
  const _NewPhoto(this.picked);
  final PickedImage picked;
}

class _EditPhotoStrip extends StatelessWidget {
  const _EditPhotoStrip({
    required this.photos,
    required this.onAdd,
    required this.onTap,
  });

  final List<_Photo> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _AddTile(onTap: onAdd),
          for (var i = 0; i < photos.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: _Thumb(
                onTap: () => onTap(i),
                child: switch (photos[i]) {
                  _ExistingPhoto(:final image) => CachedNetworkImage(
                      imageUrl: image.imageUrl,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const ColoredBox(color: AppColors.blush),
                      errorWidget: (_, __, ___) => const ColoredBox(
                        color: AppColors.blush,
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  _NewPhoto(:final picked) => Image.memory(picked.bytes,
                      height: 100, width: 100, fit: BoxFit.cover),
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(borderRadius: AppRadii.field, child: child),
          const Positioned(
            top: 4,
            right: 4,
            child: CircleAvatar(
              radius: 11,
              backgroundColor: Colors.black45,
              child: Icon(Icons.more_horiz, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          color: AppColors.blush,
          borderRadius: AppRadii.field,
          border: Border.all(color: AppColors.hotPinkSoft),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined, color: AppColors.hotPink),
            const SizedBox(height: 4),
            Text(context.l10n.add, style: const TextStyle(color: AppColors.hotPink)),
          ],
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
