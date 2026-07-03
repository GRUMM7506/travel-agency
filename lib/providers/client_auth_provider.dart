import 'package:flutter/foundation.dart';

import '../models/client_account.dart';
import '../services/api_service.dart';
import '../services/client_auth_service.dart';
import '../services/token_storage.dart';

/// Авторизация КЛИЕНТА (личный кабинет).
///
/// Полностью независим от AuthProvider: свой токен под своим ключом, свой Dio.
/// Сотрудник и клиент могут быть залогинены одновременно на одном устройстве.
class ClientAuthProvider extends ChangeNotifier {
  ClientAuthProvider() {
    ApiService.instance.onCustomerUnauthorized = _onUnauthorized;
  }

  final _service = ClientAuthService();

  ClientAccount? _account;
  bool _isLoading = false;
  bool _isBootstrapping = true;
  String? _error;

  ClientAccount? get account => _account;
  bool get isAuthenticated => _account != null;
  bool get isLoading => _isLoading;
  bool get isBootstrapping => _isBootstrapping;
  String? get error => _error;

  Future<void> tryAutoLogin() async {
    await TokenStorage.instance.load();
    final token = TokenStorage.instance.clientToken;
    if (token != null) {
      try {
        _account = await _service.me();
      } catch (_) {
        await TokenStorage.instance.clearClientToken();
        _account = null;
      }
    }
    _isBootstrapping = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    return _run(() async {
      final token = await _service.login(email.trim(), password);
      await TokenStorage.instance.saveClientToken(token);
      _account = await _service.me();
    });
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    return _run(() async {
      final token = await _service.register(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        password: password,
        phone: phone?.trim(),
      );
      await TokenStorage.instance.saveClientToken(token);
      _account = await _service.me();
    });
  }

  Future<bool> updateProfile(ClientAccount updated) async {
    return _run(() async {
      _account = await _service.updateProfile(updated);
    });
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    return _run(() => _service.changePassword(currentPassword, newPassword));
  }

  Future<void> logout() async {
    await TokenStorage.instance.clearClientToken();
    _account = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// Общая обвязка «загрузка → ошибка → notify» для всех сетевых действий.
  Future<bool> _run(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _error = ApiService.instance.parseError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onUnauthorized() {
    if (_account == null) return;
    _account = null;
    _error = 'Сессия истекла — войдите заново';
    notifyListeners();
  }

  @override
  void dispose() {
    ApiService.instance.onCustomerUnauthorized = null;
    super.dispose();
  }
}
