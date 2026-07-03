import '../models/staff.dart';
import 'api_service.dart';

/// Управление учётными записями сотрудников. Все эндпоинты /staff на бэкенде
/// закрыты ролью admin — менеджер получит 403.
class StaffService {
  final _dio = ApiService.instance.client;

  Future<List<Staff>> getAll() async {
    final response = await _dio.get('/staff');
    return (response.data as List).map((e) => Staff.fromJson(e)).toList();
  }

  Future<Staff> create(Staff staff, String password) async {
    final response = await _dio.post('/staff', data: staff.toJson(password: password));
    return Staff.fromJson(response.data);
  }

  /// [password] == null означает «пароль не менять».
  Future<Staff> update(int id, Staff staff, {String? password}) async {
    final response = await _dio.put('/staff/$id', data: staff.toJson(password: password));
    return Staff.fromJson(response.data);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/staff/$id');
  }
}
