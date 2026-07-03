import '../models/hotel.dart';
import 'api_service.dart';

class HotelService {
  final _dio = ApiService.instance.client;

  Future<List<Hotel>> getAll() async {
    final response = await _dio.get('/hotels');
    return (response.data as List).map((e) => Hotel.fromJson(e)).toList();
  }

  Future<Hotel> getById(int id) async {
    final response = await _dio.get('/hotels/$id');
    return Hotel.fromJson(response.data);
  }

  Future<Hotel> create(Hotel hotel) async {
    final response = await _dio.post('/hotels', data: hotel.toJson());
    return Hotel.fromJson(response.data);
  }

  Future<Hotel> update(int id, Hotel hotel) async {
    final response = await _dio.put('/hotels/$id', data: hotel.toJson());
    return Hotel.fromJson(response.data);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/hotels/$id');
  }
}
