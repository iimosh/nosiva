import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/location/location_service.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_chip.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../../../shell/main_shell.dart';
import '../data/listings_repository.dart';
import '../domain/listing_enums.dart';
import 'controllers/feed_controller.dart';

typedef PickedImage = ({Uint8List bytes, String ext});

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _brand = TextEditingController();
  final _color = TextEditingController();
  final _location = TextEditingController();
  final _price = TextEditingController();

  final _images = <PickedImage>[];
  ListingCategory? _category;
  ItemCondition _condition = ItemCondition.good;
  String? _size;
  final _styleTags = <String>{};
  bool _submitting = false;
  bool _detectingLocation = false;

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

  Future<void> _pick(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final files = await _picker.pickMultiImage(imageQuality: 80);
        for (final f in files) {
          _images.add((bytes: await f.readAsBytes(), ext: _ext(f.path)));
        }
      } else {
        final f = await _picker.pickImage(source: source, imageQuality: 80);
        if (f != null) {
          _images.add((bytes: await f.readAsBytes(), ext: _ext(f.path)));
        }
      }
      if (mounted) {
        setState(() {});
        _syncDirty();
      }
    } catch (e) {
      if (mounted) context.showError('Couldn’t add photo — $e');
    }
  }

  String _ext(String path) {
    final dot = path.lastIndexOf('.');
    final ext = dot == -1 ? 'jpg' : path.substring(dot + 1).toLowerCase();
    return ext == 'jpeg' ? 'jpg' : ext;
  }

  void _showPickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      context.showError('Pick a category bestie');
      return;
    }
    if (_images.isEmpty) {
      context.showError('Add at least one photo 📸');
      return;
    }

    final uid = ref.read(currentAuthUserProvider)?.id;
    if (uid == null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(listingsRepositoryProvider).createListing(
        sellerId: uid,
        values: {
          'title': _title.text.trim(),
          'description': _description.text.trim(),
          'category': _category!.value,
          'condition': _condition.value,
          'price': double.parse(_price.text.trim()),
          'brand': _brand.text.trim().isEmpty ? null : _brand.text.trim(),
          'color': _color.text.trim().isEmpty ? null : _color.text.trim(),
          'location':
              _location.text.trim().isEmpty ? null : _location.text.trim(),
          'size': _size,
          'style_tags': _styleTags.toList(),
        },
        images: _images,
      );
      ref.read(feedControllerProvider.notifier).refresh();
      if (mounted) {
        context.showSuccess('Listed! Time to make that coin 💸');
        if (context.canPop()) {
          context.pop();
        } else {
          _resetForm();
          context.go(AppRoutes.home);
        }
      }
    } catch (e) {
      if (mounted) context.showError('Couldn’t list — $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForm() {
    _title.clear();
    _description.clear();
    _brand.clear();
    _color.clear();
    _location.clear();
    _price.clear();
    setState(() {
      _images.clear();
      _category = null;
      _condition = ItemCondition.good;
      _size = null;
      _styleTags.clear();
    });
    _syncDirty();
  }

  bool get _isDirty =>
      _title.text.isNotEmpty ||
      _description.text.isNotEmpty ||
      _brand.text.isNotEmpty ||
      _color.text.isNotEmpty ||
      _location.text.isNotEmpty ||
      _price.text.isNotEmpty ||
      _images.isNotEmpty ||
      _category != null ||
      _size != null ||
      _styleTags.isNotEmpty;

  void _syncDirty() {
    ref.read(sellFormDirtyProvider.notifier).state = _isDirty;
  }

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      final loc = await ref.read(locationServiceProvider).currentCity();
      _location.text = loc;
      _syncDirty();
    } catch (e) {
      if (mounted) context.showError('$e');
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sellResetSignalProvider, (_, __) => _resetForm());
    return Scaffold(
      appBar: AppBar(title: const Text('List an item')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PhotoStrip(
                  images: _images,
                  onAdd: _showPickerSheet,
                  onRemove: (i) {
                    setState(() => _images.removeAt(i));
                    _syncDirty();
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                NosivaTextField(
                  label: 'Title',
                  hint: 'e.g. Y2K butterfly baby tee',
                  controller: _title,
                  validator: (v) => Validators.minLength(v, 3, field: 'Title'),
                  onChanged: (_) => _syncDirty(),
                ),
                const SizedBox(height: AppSpacing.md),
                NosivaTextField(
                  label: 'Description',
                  hint: 'Condition details, measurements, fit notes…',
                  controller: _description,
                  maxLines: 4,
                  maxLength: 1000,
                  onChanged: (_) => _syncDirty(),
                ),
                const SizedBox(height: AppSpacing.md),
                _Label('Category'),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final c in ListingCategory.values)
                      NosivaChip(
                        label: '${c.emoji} ${c.label}',
                        selected: _category == c,
                        onTap: () {
                          setState(() => _category = c);
                          _syncDirty();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _Label('Condition'),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final c in ItemCondition.values)
                      NosivaChip(
                        label: c.label,
                        selected: _condition == c,
                        onTap: () => setState(() => _condition = c),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _Label('Size'),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final s in kSizes)
                      NosivaChip(
                        label: s,
                        selected: _size == s,
                        onTap: () {
                          setState(() => _size = _size == s ? null : s);
                          _syncDirty();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: NosivaTextField(
                        label: 'Brand',
                        hint: 'e.g. Brandy Melville',
                        controller: _brand,
                        onChanged: (_) => _syncDirty(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: NosivaTextField(
                        label: 'Color',
                        hint: 'e.g. Pink',
                        controller: _color,
                        onChanged: (_) => _syncDirty(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                NosivaTextField(
                  label: 'Location',
                  hint: 'City, Country',
                  controller: _location,
                  prefixIcon: Icons.place_outlined,
                  onChanged: (_) => _syncDirty(),
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
                          tooltip: 'Use my location',
                          icon: const Icon(Icons.my_location_rounded,
                              color: AppColors.hotPink),
                          onPressed: _detectLocation,
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                _Label('Style tags'),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final tag in kStyleTags)
                      NosivaChip(
                        label: tag,
                        selected: _styleTags.contains(tag),
                        onTap: () {
                          setState(() => _styleTags.contains(tag)
                              ? _styleTags.remove(tag)
                              : _styleTags.add(tag));
                          _syncDirty();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                NosivaTextField(
                  label: 'Price (USD)',
                  hint: '0.00',
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.attach_money_rounded,
                  validator: Validators.price,
                  onChanged: (_) => _syncDirty(),
                ),
                const SizedBox(height: AppSpacing.xl),
                NosivaButton(
                  label: 'List it 💖',
                  loading: _submitting,
                  variant: NosivaButtonVariant.gradient,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
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

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  final List<PickedImage> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _AddTile(onTap: onAdd),
          for (var i = 0; i < images.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: AppRadii.field,
                    child: Image.memory(images[i].bytes,
                        height: 100, width: 100, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
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
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.hotPink),
            SizedBox(height: 4),
            Text('Add', style: TextStyle(color: AppColors.hotPink)),
          ],
        ),
      ),
    );
  }
}
