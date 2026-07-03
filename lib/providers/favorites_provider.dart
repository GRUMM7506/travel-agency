import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Избранные туры на витрине.
///
/// Раньше жили в памяти экрана и терялись при любом переходе. Теперь лежат в
/// SharedPreferences — это локальная закладка, привязывать её к аккаунту
/// избыточно: избранное работает и без регистрации.
class FavoritesProvider extends ChangeNotifier {
  static const _key = 'favorite_tour_ids';

  final Set<int> _ids = <int>{};
  bool _loaded = false;

  Set<int> get ids => Set.unmodifiable(_ids);
  int get count => _ids.length;
  bool get isLoaded => _loaded;

  bool contains(int tourId) => _ids.contains(tourId);

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_key) ?? const [];
      _ids
        ..clear()
        ..addAll(stored.map(int.tryParse).whereType<int>());
    } on Exception {
      // Хранилище недоступно — избранное просто не переживёт перезапуск.
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(int tourId) async {
    if (!_ids.remove(tourId)) _ids.add(tourId);
    notifyListeners();
    await _persist();
  }

  Future<void> clearAll() async {
    _ids.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _ids.map((id) => id.toString()).toList());
    } on Exception {
      // см. выше — в памяти состояние уже верное
    }
  }
}
