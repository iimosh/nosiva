import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../domain/listing.dart';

/// Opens the phone's share sheet (WhatsApp, Viber, Instagram, …) with the
/// listing's cover photo and a short message.
///
/// The photo comes from the same cache the listing page displays it from, so
/// it's usually instant. If it can't be fetched, the message is shared alone.
Future<void> shareListing(BuildContext context, Listing listing) async {
  final text = context.l10n.shareListingText(
    listing.title,
    Formatters.price(listing.price),
  );

  // iPads anchor the share popover to the tapped button.
  final box = context.findRenderObject() as RenderBox?;
  final origin =
      box != null && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null;

  final files = <XFile>[];
  final url = listing.coverImageUrl;
  if (url != null && url.isNotEmpty) {
    try {
      final file = await DefaultCacheManager()
          .getSingleFile(url)
          .timeout(const Duration(seconds: 8));
      files.add(XFile(file.path, mimeType: _mimeFor(file.path)));
    } catch (_) {
      // Offline or slow: share the message without the photo.
    }
  }

  await SharePlus.instance.share(ShareParams(
    text: text,
    subject: listing.title,
    files: files.isEmpty ? null : files,
    sharePositionOrigin: origin,
  ));
}

String _mimeFor(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}
