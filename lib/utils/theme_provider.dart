import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
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
      _isDark = prefs.getBool('isDark') ?? false;
      _useSystemTheme = prefs.getBool('useSystemTheme') ?? true;
    }

    notifyListeners();
  }

  /// Check if using system theme
  bool get useSystemTheme => _useSystemTheme;

  /// Set theme directly
  void setDarkMode(bool isDark) {
    _useSystemTheme = false;
    _isDark = isDark;
    _saveTheme(_isDark, _useSystemTheme);
    notifyListeners();
  }

  /// Set to use system theme
  void setUseSystemTheme(bool useSystem) {
    _useSystemTheme = useSystem;
    _saveTheme(_isDark, _useSystemTheme);
    notifyListeners();
  }

  /// Get current theme mode as string
  String get themeModeString {
    if (_useSystemTheme) return 'System';
    return _isDark ? 'Dark' : 'Light';
  }
}