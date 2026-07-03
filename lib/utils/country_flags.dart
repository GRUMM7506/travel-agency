// Утилита для отображения флагов стран
class CountryFlags {
  static const Map<String, String> _flags = {
    'Турция': '🇹🇷',
    'Египет': '🇪🇬',
    'ОАЭ': '🇦🇪',
    'Таиланд': '🇹🇭',
    'Италия': '🇮🇹',
    'Швейцария': '🇨🇭',
  };

  static String getFlag(String country) {
    return _flags[country] ?? '🌍';
  }
}