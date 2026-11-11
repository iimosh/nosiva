import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'neon_auth.dart';

/// A photo request the media function refused. [status] is the HTTP status:
/// 413 too large, 415 not an image, 403 not allowed, 401 signed out.
class MediaException implements Exception {
  MediaException(this.status, this.message);
  final int status;
  final String message;
  @override
  String toString() => 'MediaException($status: $message)';
}

enum MediaKind { listing, avatar, chat }

/// The image type to send for a file extension ("jpg" -> "image/jpeg").
String imageContentType(String ext) {
  final e = ext.toLowerCase();
  return 'image/${e == 'jpg' ? 'jpeg' : e}';
}

/// An uploaded photo: [path] is its place in storage; [publicUrl] is set for
/// public photos (listings, avatars). Chat photos are private — open them
/// with [NeonFunctions.chatPhotoUrl].
typedef UploadedPhoto = ({String path, String? publicUrl});

/// Calls Nosiva's Neon Functions (neon/functions): photo uploads, private
/// chat-photo links and push notifications.
class NeonFunctions {
  NeonFunctions({
    required this.auth,
    required this.mediaUrl,
    required this.pushUrl,
    http.Client? client,
  }) : _http = client ?? http.Client();

  final NeonAuth auth;
  final String mediaUrl;
  final String pushUrl;
  final http.Client _http;

  /// Uploads a photo straight to storage using a one-off link from the media
  /// function, which checks the person may put it there.
  Future<UploadedPhoto> uploadPhoto({
    required MediaKind kind,
    required Uint8List bytes,
    required String contentType,
    String? listingId,
    String? conversationId,
  }) async {
    final grant = await _post(mediaUrl, '/upload', {
      'kind': kind.name,
      'contentType': contentType,
      'size': bytes.length,
      if (listingId != null) 'listingId': listingId,
      if (conversationId != null) 'conversationId': conversationId,
    });
    final put = await _http
        .put(
          Uri.parse(grant['uploadUrl'] as String),
          headers: {'content-type': contentType},
          body: bytes,
        )
        .timeout(const Duration(seconds: 60));
    if (put.statusCode >= 300) {
      throw MediaException(put.statusCode, 'Upload rejected by storage');
    }
    return (path: grant['path'] as String, publicUrl: grant['publicUrl'] as String?);
  }

  /// A one-hour link to a private chat photo (participants only).
  Future<String> chatPhotoUrl(String path) async {
    final res = await _post(mediaUrl, '/chat-photo', {'path': path});
    return res['url'] as String;
  }

  /// Deletes every photo the signed-in person uploaded. Run before deleting
  /// the account, while the session still exists.
  Future<void> deleteMyPhotos() => _post(mediaUrl, '/delete-mine', const {});

  /// Asks the push function to send waiting notifications now (otherwise
  /// they go out within a minute). Never throws.
  Future<void> nudgePush() async {
    try {
      await _post(pushUrl, '/flush', const {});
    } catch (e) {
      if (kDebugMode) debugPrint('[push] nudge failed: $e');
    }
  }

  Future<Map<String, dynamic>> _post(
    String base,
    String path,
    Map<String, Object?> body,
  ) async {
    final token = await auth.userToken();
    final res = await _http
        .post(
          Uri.parse('${base.replaceAll(RegExp(r'/+$'), '')}$path'),
          headers: {
            'authorization': 'Bearer $token',
            'content-type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    Map<String, dynamic> decoded;
    try {
      final d = jsonDecode(res.body);
      decoded = d is Map<String, dynamic> ? d : const {};
    } catch (_) {
      decoded = const {};
    }
    if (res.statusCode >= 300) {
      throw MediaException(res.statusCode, (decoded['error'] as String?) ?? 'HTTP ${res.statusCode}');
    }
    return decoded;
  }
}
