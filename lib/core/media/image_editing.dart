import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';

import '../l10n/l10n_extensions.dart';
import '../theme/app_colors.dart';

typedef PickedImage = ({Uint8List bytes, String ext});

String pickedImageExt(String path) {
  final dot = path.lastIndexOf('.');
  final ext = dot == -1 ? 'jpg' : path.substring(dot + 1).toLowerCase();
  return ext == 'jpeg' ? 'jpg' : ext;
}

Future<PickedImage> loadImage(String url) async {
  final file = await DefaultCacheManager().getSingleFile(url);
  return (bytes: await file.readAsBytes(), ext: pickedImageExt(file.path));
}

PickedImage? rotateImage(Uint8List bytes, String ext, {required num angle}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final rotated = img.copyRotate(decoded, angle: angle);
  if (ext == 'png') {
    return (bytes: Uint8List.fromList(img.encodePng(rotated)), ext: 'png');
  }
  return (
    bytes: Uint8List.fromList(img.encodeJpg(rotated, quality: 90)),
    ext: 'jpg',
  );
}

List<PlatformUiSettings> _cropUiSettings(BuildContext context) {
  final title = context.l10n.crop;
  return [
    AndroidUiSettings(
      toolbarTitle: title,
      toolbarColor: AppColors.hotPink,
      toolbarWidgetColor: Colors.white,
      activeControlsWidgetColor: AppColors.hotPink,
      lockAspectRatio: false,
      hideBottomControls: true,
    ),
    IOSUiSettings(title: title, aspectRatioLockEnabled: false),
  ];
}

Future<PickedImage?> cropImage(
  BuildContext context,
  Uint8List bytes,
  String ext,
) async {
  final ui = _cropUiSettings(context);
  final tmp = File(
    '${Directory.systemTemp.path}/nosiva_crop_'
    '${DateTime.now().microsecondsSinceEpoch}.$ext',
  );
  await tmp.writeAsBytes(bytes);
  final cropped =
      await ImageCropper().cropImage(sourcePath: tmp.path, uiSettings: ui);
  if (cropped == null) return null;
  return (bytes: await cropped.readAsBytes(), ext: pickedImageExt(cropped.path));
}
