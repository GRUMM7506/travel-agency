import '../models/staff.dart';
import 'api_service.dart';

/// Авторизация СОТРУДНИКА (CRM). Клиентский вход — в client_auth_service.dart.
class AuthService {
  final _dio = ApiService.instance.client;

  /// Возвращает access_token.
  Future<String> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data['access_token'] as String;
  }

  Future<Staff> me() async {
    final response = await _dio.get('/auth/me');
    return Staff.fromJson(response.data);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _dio.post('/auth/password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}
