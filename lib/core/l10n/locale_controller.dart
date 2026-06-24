import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends Notifier<Locale> {
  static const _prefsKey = 'selected_locale';
  static const english = Locale('en');
  static const macedonian = Locale('mk');

  @override
  Locale build() {
    _loadSavedLocale();
    return english;
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == null) return;
    state = _localeFromCode(code);
  }

  Future<Locale> getCurrentLocale() async {
    final prefs = await SharedPreferences.getInstance();
    var code = prefs.getString(_prefsKey);
    code ??= 'eng';
    return _localeFromCode(code);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }


  Locale _localeFromCode(String code) {
    return switch (code) {
      'mk' => macedonian,
      _ => english,
    };
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);
