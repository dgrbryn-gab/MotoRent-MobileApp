import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  String _languageCode = 'en';
  static const String _localeKey = 'language';

  // For display purposes only - not used by Flutter's localization system
  Locale get locale => Locale(_languageCode);

  String get languageCode => _languageCode;

  final List<Locale> supportedLocales = const [
    Locale('en'), // English
    Locale('fil'), // Filipino
    Locale('ceb'), // Cebuano
  ];

  LocaleService() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey) ?? 'en';
    _languageCode = languageCode;
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    if (_languageCode == languageCode) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
    _languageCode = languageCode;
    notifyListeners();
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'fil':
        return 'Filipino';
      case 'ceb':
        return 'Cebuano';
      default:
        return 'English';
    }
  }

  String getLanguageNativeName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'fil':
        return 'Filipino';
      case 'ceb':
        return 'Cebuano';
      default:
        return 'English';
    }
  }
}
