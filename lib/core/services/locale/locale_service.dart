import 'package:flutter/material.dart';
import 'package:browser_app/core/logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  static const es = Locale('es', 'ES');
  static const en = Locale('en', 'US');

  static const String _key = 'locale';
  Locale? _currentLocale;

  /// Load locale from shared preferences
  Future<Locale?> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      Logger.show('_currentLocale: $code');
      _currentLocale = Locale(code);
    }
    return _currentLocale;
  }

  /// Get current locale
  Locale? get currentLocale => _currentLocale;

  /// Set current locale
  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
    _currentLocale = locale;
  }
}
