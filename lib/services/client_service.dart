import '../models/client.dart';
import 'api_service.dart';

class ClientService {
  final _dio = ApiService.instance.client;

  Future<List<Client>> getAll() async {
    final response = await _dio.get('/clients');
    return (response.data as List).map((e) => Client.fromJson(e)).toList();
  }

  Future<List<Client>> search(String query) async {
    final response = await _dio.get('/clients/search', queryParameters: {'q': query});
    return (response.data as List).map((e) => Client.fromJson(e)).toList();
  }

  Future<Client> getById(int id) async {
    final response = await _dio.get('/clients/$id');
    return Client.fromJson(response.data);
  }

  Future<Client> create(Client client) async {
    final response = await _dio.post('/clients', data: client.toJson());
    return Client.fromJson(response.data);
  }

  Future<Client> update(int id, Client client) async {
    final response = await _dio.put('/clients/$id', data: client.toJson());
    return Client.fromJson(response.data);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/clients/$id');
  }
}
