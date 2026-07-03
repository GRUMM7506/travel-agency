import '../models/client_account.dart';
import 'api_service.dart';

/// Авторизация КЛИЕНТА (личный кабинет). Ходит через ApiService.instance.customer,
/// т.к. токен клиента и токен сотрудника не взаимозаменяемы.
class ClientAuthService {
  final _dio = ApiService.instance.customer;

  /// Регистрация сразу возвращает токен — отдельный вход после неё не нужен.
  Future<String> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await _dio.post('/auth/client/register', data: {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return response.data['access_token'] as String;
  }

  Future<String> login(String email, String password) async {
    final response = await _dio.post('/auth/client/login', data: {
      'email': email,
      'password': password,
    });
    return response.data['access_token'] as String;
  }

  Future<ClientAccount> me() async {
    final response = await _dio.get('/auth/client/me');
    return ClientAccount.fromJson(response.data);
  }

  Future<ClientAccount> updateProfile(ClientAccount account) async {
    final response = await _dio.put('/auth/client/me', data: account.toProfileJson());
    return ClientAccount.fromJson(response.data);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _dio.post('/auth/client/password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}
