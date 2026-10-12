import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';

/// Turns any error into a short message a person can act on, in their
/// language. Raw exception text is never shown: it reads as broken and can
/// reveal internals (table names, security rules). In debug builds the
/// technical details are still printed to the console for developers.
String friendlyError(AppLocalizations l10n, Object? error) {
  if (kDebugMode && error != null) debugPrint('[friendlyError] $error');

  if (error is SocketException ||
      error is TimeoutException ||
      error is HandshakeException ||
      _looksOffline('$error')) {
    return l10n.errorNoInternet;
  }

  if (error is AuthException) {
    final code = error.code ?? '';
    if (code == 'user_already_exists' || code == 'email_exists') {
      return l10n.errorEmailInUse;
    }
    if (code == 'weak_password') return l10n.errorWeakPassword;
    if (code == 'email_address_invalid') return l10n.errorInvalidEmail;
    if (code.startsWith('over_') || error.statusCode == '429') {
      return l10n.errorTooManyAttempts;
    }
    if (code == 'session_expired' ||
        code == 'session_not_found' ||
        code == 'refresh_token_not_found') {
      return l10n.errorSessionExpired;
    }
    return l10n.errorGeneric;
  }

  if (error is PostgrestException) {
    return switch (error.code) {
      '42501' => l10n.errorNotAllowed, // blocked by a security rule
      '23505' => l10n.errorAlreadyExists, // duplicate
      '23514' || '22001' || '23502' => l10n.errorInvalidData, // bad value
      'PGRST116' => l10n.errorNotFound, // row no longer there
      _ => l10n.errorGeneric,
    };
  }

  if (error is StorageException) {
    final text = '${error.statusCode} ${error.message}'.toLowerCase();
    if (text.contains('413') || text.contains('size')) return l10n.errorFileTooLarge;
    if (text.contains('mime') || text.contains('type')) return l10n.errorFileType;
    if (text.contains('403')) return l10n.errorNotAllowed;
    return l10n.errorGeneric;
  }

  return l10n.errorGeneric;
}

/// Network failures often arrive wrapped (e.g. as an http ClientException),
/// so recognise them by their text too.
bool _looksOffline(String text) {
  final t = text.toLowerCase();
  return t.contains('socketexception') ||
      t.contains('failed host lookup') ||
      t.contains('clientexception') ||
      t.contains('network is unreachable') ||
      t.contains('connection refused') ||
      t.contains('connection closed') ||
      t.contains('connection reset') ||
      t.contains('timed out');
}
