import 'package:flutter/material.dart';

/// Singleton service to manage light/dark theme globally.
class ThemeService {
  ThemeService._();

  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.light);

  static void toggleTheme() {
    themeNotifier.value = themeNotifier.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  static bool get isDark => themeNotifier.value == ThemeMode.dark;
}
