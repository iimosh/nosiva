import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/core/utils/friendly_error.dart';
import 'package:nosiva/l10n/app_localizations.dart';
import 'package:nosiva/core/neon/neon_auth.dart';
import 'package:nosiva/core/neon/neon_functions.dart';
import 'package:supabase/supabase.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final mk = lookupAppLocalizations(const Locale('mk'));

  test('network problems say "no internet"', () {
    expect(friendlyError(en, const SocketException('Failed host lookup')),
        en.errorNoInternet);
    expect(friendlyError(en, TimeoutException('slow')), en.errorNoInternet);
    expect(friendlyError(en, Exception('ClientException: Connection closed')),
        en.errorNoInternet);
  });

  test('database errors never leak table or rule details', () {
    const rls = PostgrestException(
      message: 'new row violates row-level security policy for table "orders"',
      code: '42501',
    );
    final message = friendlyError(en, rls);
    expect(message, en.errorNotAllowed);
    expect(message, isNot(contains('orders')));
    expect(friendlyError(en, const PostgrestException(message: 'dup', code: '23505')),
        en.errorAlreadyExists);
  });

  test('account errors are specific and translated', () {
    expect(friendlyError(en, NeonAuthException('x', code: 'USER_ALREADY_EXISTS')),
        en.errorEmailInUse);
    expect(friendlyError(mk, NeonAuthException('x', status: 429)),
        mk.errorTooManyAttempts);
  });

  test('rate limits say "too many attempts"', () {
    const e = PostgrestException(
        message: 'rate_limited: too many messages in a short time', code: 'P0001');
    expect(friendlyError(en, e), en.errorTooManyAttempts);
  });

  test('photo upload errors', () {
    expect(friendlyError(en, MediaException(413, 'Image too large')),
        en.errorFileTooLarge);
    expect(friendlyError(en, MediaException(415, 'Only images')), en.errorFileType);
  });

  test('anything unknown gets the generic message, never raw text', () {
    expect(friendlyError(mk, StateError('internal detail')), mk.errorGeneric);
    expect(friendlyError(mk, null), mk.errorGeneric);
  });
}
