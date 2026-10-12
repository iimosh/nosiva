import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/core/utils/friendly_error.dart';
import 'package:nosiva/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    expect(friendlyError(en, const AuthException('x', code: 'user_already_exists')),
        en.errorEmailInUse);
    expect(friendlyError(mk, const AuthException('x', code: 'over_email_send_rate_limit')),
        mk.errorTooManyAttempts);
  });

  test('photo upload errors', () {
    expect(friendlyError(en, StorageException('Payload too large', statusCode: '413')),
        en.errorFileTooLarge);
    expect(friendlyError(en, StorageException('invalid_mime_type')), en.errorFileType);
  });

  test('anything unknown gets the generic message, never raw text', () {
    expect(friendlyError(mk, StateError('internal detail')), mk.errorGeneric);
    expect(friendlyError(mk, null), mk.errorGeneric);
  });
}
