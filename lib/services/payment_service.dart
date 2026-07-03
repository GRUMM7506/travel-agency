import '../models/payment.dart';
import 'api_service.dart';

class PaymentService {
  final _dio = ApiService.instance.client;

  Future<List<Payment>> getAll({int? bookingId}) async {
    final response = await _dio.get(
      '/payments',
      queryParameters: bookingId != null ? {'booking_id': bookingId} : null,
    );
    return (response.data as List).map((e) => Payment.fromJson(e)).toList();
  }

  Future<Payment> create(Payment payment) async {
    final response = await _dio.post('/payments', data: payment.toJson());
    return Payment.fromJson(response.data);
  }

  Future<Payment> update(int id, Payment payment) async {
    final response = await _dio.put('/payments/$id', data: payment.toJson());
    return Payment.fromJson(response.data);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/payments/$id');
  }
}
