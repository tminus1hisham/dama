import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;
  bool _useSystemTheme = true;

  bool get isDark {
    if (kIsWeb) {
      return false;
    }

    return _useSystemTheme
        ? WidgetsBinding.instance.window.platformBrightness ==
            Brightness.dark
        : _isDark;
  }

  ThemeProvider() {
    loadTheme();
  }

  /// Toggle manual theme
  toggleTheme() {
    _useSystemTheme = false;
    _isDark = !_isDark;
    _saveTheme(_isDark, _useSystemTheme);
    notifyListeners();
  }

  /// Toggle system theme usage
  toggleSystemTheme(bool useSystemTheme) {
    _useSystemTheme = useSystemTheme;
    _saveTheme(_isDark, _useSystemTheme);
    notifyListeners();
  }

  /// Save theme state
  _saveTheme(bool isDark, bool useSystemTheme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDark', isDark);
    prefs.setBool('useSystemTheme', useSystemTheme);
  }

  /// Load saved theme
  loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      _isDark = false;
      _useSystemTheme = false;
    } else {
      _isDark = prefs.getBool('isDark') ?? true;
      _useSystemTheme = prefs.getBool('useSystemTheme') ?? false;
    }

    notifyListeners();
  }
}