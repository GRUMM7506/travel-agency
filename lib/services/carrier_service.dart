import '../models/carrier.dart';
import 'api_service.dart';

class CarrierService {
  final _dio = ApiService.instance.client;

  Future<List<Carrier>> getAll() async {
    final response = await _dio.get('/carriers');
    return (response.data as List).map((e) => Carrier.fromJson(e)).toList();
  }

  Future<Carrier> getById(int id) async {
    final response = await _dio.get('/carriers/$id');
    return Carrier.fromJson(response.data);
  }

  Future<Carrier> create(Carrier carrier) async {
    final response = await _dio.post('/carriers', data: carrier.toJson());
    return Carrier.fromJson(response.data);
  }

  Future<Carrier> update(int id, Carrier carrier) async {
    final response = await _dio.put('/carriers/$id', data: carrier.toJson());
    return Carrier.fromJson(response.data);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/carriers/$id');
  }
}
