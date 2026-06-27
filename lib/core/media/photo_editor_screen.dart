import 'package:flutter/material.dart';

import '../l10n/l10n_extensions.dart';
import '../theme/app_colors.dart';
import '../utils/snackbars.dart';
import 'image_editing.dart';

class PhotoEditorScreen extends StatefulWidget {
  const PhotoEditorScreen({super.key, required this.image});

  final PickedImage image;

  static Future<PickedImage?> open(BuildContext context, PickedImage image) {
    return Navigator.of(context).push<PickedImage>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoEditorScreen(image: image),
      ),
    );
  }

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  late PickedImage _image = widget.image;
  bool _busy = false;

  void _rotate(num angle) {
    final rotated = rotateImage(_image.bytes, _image.ext, angle: angle);
    if (rotated != null) setState(() => _image = rotated);
  }

  Future<void> _crop() async {
    setState(() => _busy = true);
    try {
      final cropped = await cropImage(context, _image.bytes, _image.ext);
      if (cropped != null && mounted) setState(() => _image = cropped);
    } catch (e) {
      if (mounted) context.showError(context.l10n.photoEditFailed('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(context.l10n.editPhoto),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(_image),
            child: Text(
              context.l10n.done,
              style: const TextStyle(
                  color: AppColors.hotPink, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.memory(_image.bytes, fit: BoxFit.contain),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _EditorAction(
                icon: Icons.rotate_left_rounded,
                label: context.l10n.rotateLeft,
                onTap: _busy ? null : () => _rotate(-90),
              ),
              _EditorAction(
                icon: Icons.rotate_right_rounded,
                label: context.l10n.rotateRight,
                onTap: _busy ? null : () => _rotate(90),
              ),
              _EditorAction(
                icon: Icons.crop_rounded,
                label: context.l10n.crop,
                onTap: _busy ? null : _crop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorAction extends StatelessWidget {
  const _EditorAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? Colors.white38 : Colors.white;
    return TextButton(
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
