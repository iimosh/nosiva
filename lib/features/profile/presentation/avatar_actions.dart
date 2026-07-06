import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/media/image_editing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbars.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';
import 'current_profile_provider.dart';

final avatarControllerProvider =
    NotifierProvider<AvatarController, bool>(AvatarController.new);

class AvatarController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> change(
    BuildContext context,
    ImageSource source,
    String userId,
  ) async {
    final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = pickedImageExt(file.path);
    if (!context.mounted) return;
    final edited = await cropAvatar(context, bytes, ext);
    if (edited == null || !context.mounted) return;
    await _apply(context, () async {
      final repo = ref.read(profileRepositoryProvider);
      final url = await repo.uploadAvatar(
          userId: userId, bytes: edited.bytes, ext: edited.ext);
      return repo.updateAvatar(id: userId, avatarUrl: url);
    });
  }

  Future<void> remove(BuildContext context, String userId) => _apply(
        context,
        () => ref
            .read(profileRepositoryProvider)
            .updateAvatar(id: userId, avatarUrl: null),
      );

  Future<void> _apply(
    BuildContext context,
    Future<Profile> Function() action,
  ) async {
    state = true;
    try {
      final updated = await action();
      ref.read(currentProfileProvider.notifier).set(updated);
      if (context.mounted) context.showSuccess(context.l10n.photoUpdated);
    } catch (e) {
      if (context.mounted) {
        context.showError(context.l10n.photoUpdateFailed('$e'));
      }
    } finally {
      state = false;
    }
  }
}

/// Gallery / camera / remove options for the current user's avatar.
Future<void> showAvatarOptions(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required bool hasPhoto,
}) {
  final controller = ref.read(avatarControllerProvider.notifier);
  return showModalBottomSheet<void>(
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
              controller.change(context, ImageSource.gallery, userId);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: Text(context.l10n.takePhoto),
            onTap: () {
              Navigator.pop(sheetCtx);
              controller.change(context, ImageSource.camera, userId);
            },
          ),
          if (hasPhoto)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(context.l10n.removePhoto),
              onTap: () {
                Navigator.pop(sheetCtx);
                controller.remove(context, userId);
              },
            ),
        ],
      ),
    ),
  );
}

class EditableAvatar extends ConsumerWidget {
  const EditableAvatar({super.key, required this.profile, this.radius = 52});

  final Profile profile;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploading = ref.watch(avatarControllerProvider);
    final url = profile.avatarUrl;
    final badge = radius * 0.34;

    return GestureDetector(
      onTap: uploading
          ? null
          : () => showAvatarOptions(context, ref,
              userId: profile.id, hasPhoto: url != null),
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.blush,
            backgroundImage: url == null ? null : CachedNetworkImageProvider(url),
            child: url == null && !uploading
                ? Icon(Icons.person_outline_rounded,
                    color: AppColors.hotPink, size: radius * 0.85)
                : null,
          ),
          if (uploading)
            Positioned.fill(
              child: CircleAvatar(
                radius: radius,
                backgroundColor: Colors.black26,
                child: const CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(badge * 0.32),
              decoration: BoxDecoration(
                color: AppColors.hotPink,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Theme.of(context).colorScheme.surface, width: 2),
              ),
              child: Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: badge),
            ),
          ),
        ],
      ),
    );
  }
}
