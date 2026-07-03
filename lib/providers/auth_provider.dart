import 'package:flutter/foundation.dart';

import '../models/staff.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';

/// Авторизация СОТРУДНИКА. Служит ещё и refreshListenable для GoRouter:
/// как только isAuthenticated меняется, роутер пересчитывает redirect.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    // Интерсептор Dio дёрнет это, если сервер ответил 401 (токен протух).
    ApiService.instance.onStaffUnauthorized = _onUnauthorized;
  }

  final _service = AuthService();

  Staff? _currentStaff;
  bool _isLoading = false;
  bool _isBootstrapping = true;
  String? _error;

  Staff? get currentStaff => _currentStaff;
  bool get isAuthenticated => _currentStaff != null;
  bool get isAdmin => _currentStaff?.isAdmin ?? false;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// true, пока идёт autologin при старте — роутеру нельзя редиректить
  /// раньше, чем мы узнаем, есть ли сохранённый токен.
  bool get isBootstrapping => _isBootstrapping;

  /// Проверяет сохранённый токен при запуске приложения.
  Future<void> tryAutoLogin() async {
    await TokenStorage.instance.load();
    final token = TokenStorage.instance.staffToken;
    if (token != null) {
      try {
        _currentStaff = await _service.me();
      } catch (_) {
        // Токен протух или сервер недоступен — просто останемся разлогинены.
        await TokenStorage.instance.clearStaffToken();
        _currentStaff = null;
      }
    }
    _isBootstrapping = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final token = await _service.login(email.trim(), password);
      await TokenStorage.instance.saveStaffToken(token);
      _currentStaff = await _service.me();
      return true;
    } catch (e) {
      _error = ApiService.instance.parseError(e);
      await TokenStorage.instance.clearStaffToken();
      _currentStaff = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await TokenStorage.instance.clearStaffToken();
    _currentStaff = null;
    _error = null;
    notifyListeners();
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _error = null;
    try {
      await _service.changePassword(currentPassword, newPassword);
      return true;
    } catch (e) {
      _error = ApiService.instance.parseError(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _onUnauthorized() {
    if (_currentStaff == null) return;
    _currentStaff = null;
    _error = 'Сессия истекла — войдите заново';
    notifyListeners();
  }

  @override
  void dispose() {
    ApiService.instance.onStaffUnauthorized = null;
    super.dispose();
  }
}
