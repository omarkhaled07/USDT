import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  // دالة لتحميل حالة الثيم من SharedPreferences
  Future<void> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _themeMode = (prefs.getString('theme') ?? 'light') == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  // دالة لتغيير الثيم وحفظ الحالة
  Future<void> toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
      await prefs.setString('theme', 'dark');
    } else {
      _themeMode = ThemeMode.light;
      await prefs.setString('theme', 'light');
    }
    notifyListeners();
  }
}