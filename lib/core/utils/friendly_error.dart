import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';

import '../../l10n/app_localizations.dart';
import '../neon/neon_auth.dart';
import '../neon/neon_functions.dart';

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

  if (error is NeonAuthException) {
    // Better Auth's error codes (Neon Auth).
    final code = error.code ?? '';
    if (code == 'USER_ALREADY_EXISTS' ||
        code == 'USER_ALREADY_EXISTS_USE_ANOTHER_EMAIL') {
      return l10n.errorEmailInUse;
    }
    if (code == 'PASSWORD_TOO_SHORT' || code == 'PASSWORD_TOO_LONG') {
      return l10n.errorWeakPassword;
    }
    if (code == 'INVALID_EMAIL') return l10n.errorInvalidEmail;
    if (code == 'TOO_MANY_REQUESTS' || error.status == 429) {
      return l10n.errorTooManyAttempts;
    }
    if (error.sessionInvalid) return l10n.errorSessionExpired;
    return l10n.errorGeneric;
  }

  if (error is PostgrestException) {
    // Over a per-account limit (neon/migrations/0033_rate_limits.sql).
    if (error.message.startsWith('rate_limited')) {
      return l10n.errorTooManyAttempts;
    }
    return switch (error.code) {
      '42501' => l10n.errorNotAllowed, // blocked by a security rule
      '23505' => l10n.errorAlreadyExists, // duplicate
      '23514' || '22001' || '23502' => l10n.errorInvalidData, // bad value
      'PGRST116' => l10n.errorNotFound, // row no longer there
      _ => l10n.errorGeneric,
    };
  }

  if (error is MediaException) {
    return switch (error.status) {
      413 => l10n.errorFileTooLarge,
      415 => l10n.errorFileType,
      401 => l10n.errorSessionExpired,
      403 => l10n.errorNotAllowed,
      _ => l10n.errorGeneric,
    };
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
