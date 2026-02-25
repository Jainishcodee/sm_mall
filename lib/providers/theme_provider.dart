import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Key
// ---------------------------------------------------------------------------
const _kThemeKey = 'app_theme_mode';

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ThemeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kThemeKey);
      return _parse(saved);
    } catch (_) {
      // SharedPreferences unavailable (e.g. Flutter Web in some configs)
      return ThemeMode.light;
    }
  }

  ThemeMode _parse(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light; // default = light
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = AsyncData(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeKey, mode.name);
    } catch (_) {
      // Ignore persistence failures on platforms without SharedPreferences support
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final themeProvider = AsyncNotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
