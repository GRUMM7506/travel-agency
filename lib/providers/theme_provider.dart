import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Тема приложения: системная, светлая, темная
enum AppThemeMode { system, light, dark }

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';

  AppThemeMode _mode = AppThemeMode.system;

  AppThemeMode get mode => _mode;

  ThemeMode get themeMode {
    switch (_mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  /// Поднимает сохранённый выбор при старте — иначе тема сбрасывалась
  /// на системную при каждом запуске.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_key);
      if (stored != null) {
        _mode = AppThemeMode.values.firstWhere(
          (m) => m.name == stored,
          orElse: () => AppThemeMode.system,
        );
        notifyListeners();
      }
    } on Exception {
      // Хранилище недоступно — остаёмся на системной теме.
    }
  }

  void setMode(AppThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    _persist();
  }

  void toggleTheme() {
    switch (_mode) {
      case AppThemeMode.system:
      case AppThemeMode.light:
        _mode = AppThemeMode.dark;
        break;
      case AppThemeMode.dark:
        _mode = AppThemeMode.light;
        break;
    }
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, _mode.name);
    } on Exception {
      // не критично — выбор просто не переживёт перезапуск
    }
  }

  IconData get icon {
    switch (_mode) {
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.light:
        return Icons.wb_sunny;
      case AppThemeMode.dark:
        return Icons.nightlight_round;
    }
  }

  String get label {
    switch (_mode) {
      case AppThemeMode.system:
        return 'Системная тема';
      case AppThemeMode.light:
        return 'Светлая тема';
      case AppThemeMode.dark:
        return 'Темная тема';
    }
  }
}
