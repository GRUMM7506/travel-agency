import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Хранилище JWT-токенов.
///
/// Токены сотрудника и клиента лежат под РАЗНЫМИ ключами: на одном устройстве
/// можно быть одновременно залогиненным и как сотрудник (админка), и как
/// клиент (личный кабинет) — при тестировании это обычная ситуация.
class TokenStorage {
  TokenStorage._internal();

  static final TokenStorage instance = TokenStorage._internal();

  static const _staffKey = 'staff_token';
  static const _clientKey = 'client_token';

  // Дефолты v11 уже безопасны (AES-GCM + RSA-OAEP на Android, Keychain на iOS,
  // libsecret на Linux) — переопределять нечего.
  static const _storage = FlutterSecureStorage();

  /// Кэш в памяти: интерсептор Dio дёргается на каждом запросе, а чтение из
  /// защищённого хранилища асинхронное и заметно медленнее обращения к полю.
  String? _staffToken;
  String? _clientToken;
  bool _loaded = false;

  String? get staffToken => _staffToken;
  String? get clientToken => _clientToken;

  /// Поднимает токены с диска в память. Вызывается один раз при старте.
  Future<void> load() async {
    if (_loaded) return;
    try {
      _staffToken = await _storage.read(key: _staffKey);
      _clientToken = await _storage.read(key: _clientKey);
    } on Exception {
      // Нет keystore/libsecret — работаем без «запомнить меня»: пользователь
      // просто залогинится заново. Ронять приложение из-за этого незачем.
      _staffToken = null;
      _clientToken = null;
    }
    _loaded = true;
  }

  Future<void> saveStaffToken(String token) async {
    _staffToken = token;
    try {
      await _storage.write(key: _staffKey, value: token);
    } on Exception {
      // Токен остаётся в памяти — сессия доживёт до перезапуска.
    }
  }

  Future<void> saveClientToken(String token) async {
    _clientToken = token;
    try {
      await _storage.write(key: _clientKey, value: token);
    } on Exception {
      // см. выше
    }
  }

  Future<void> clearStaffToken() async {
    _staffToken = null;
    try {
      await _storage.delete(key: _staffKey);
    } on Exception {
      // игнорируем — в памяти токен уже стёрт
    }
  }

  Future<void> clearClientToken() async {
    _clientToken = null;
    try {
      await _storage.delete(key: _clientKey);
    } on Exception {
      // игнорируем — в памяти токен уже стёрт
    }
  }
}
