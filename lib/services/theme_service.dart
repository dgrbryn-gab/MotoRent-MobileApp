import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  static const String _themeKey = 'theme_mode';

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Initialize the theme service and load saved preference
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadSavedTheme();
    _isInitialized = true;
  }

  /// Load the saved theme from SharedPreferences
  Future<void> _loadSavedTheme() async {
    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme != null) {
      _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } else {
      // Default to system theme if nothing is saved
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _saveTheme();
    notifyListeners();
  }

  /// Set a specific theme mode
  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    await _saveTheme();
    notifyListeners();
  }

  /// Save the current theme to SharedPreferences
  Future<void> _saveTheme() async {
    final themeString = _themeMode == ThemeMode.dark ? 'dark' : 'light';
    await _prefs.setString(_themeKey, themeString);
  }
}
