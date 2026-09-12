import '../models/booking.dart';
import '../models/booking_balance.dart';
import 'api_service.dart';

class BookingService {
  final _dio = ApiService.instance.client;
  // Клиентские эндпоинты требуют токен клиента, а не сотрудника — для них
  // отдельный Dio (см. комментарий в api_service.dart).
  final _customerDio = ApiService.instance.customer;

  // --- Сотрудник ---------------------------------------------------------

  Future<List<Booking>> getAll({int? clientId, String? status}) async {
    final response = await _dio.get('/bookings', queryParameters: {
      if (clientId != null) 'client_id': clientId,
      if (status != null) 'status': status,
    });
    return (response.data as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<Booking> getById(int id) async {
    final response = await _dio.get('/bookings/$id');
    return Booking.fromJson(response.data);
  }

  /// total_cost рассчитывается на бэкенде — сюда не передаётся
  Future<Booking> create(Booking booking) async {
    final response = await _dio.post('/bookings', data: booking.toJson());
    return Booking.fromJson(response.data);
  }

  Future<Booking> update(int id, Booking booking) async {
    final response = await _dio.put('/bookings/$id', data: booking.toJson());
    return Booking.fromJson(response.data);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/bookings/$id');
  }

  // --- Клиент ------------------------------------------------------------

  /// Заявка с витрины. Скидку/комиссию/статус выставляет бэкенд.
  Future<Booking> createSelf({
    required int tourId,
    required int peopleCount,
    String? notes,
  }) async {
    final response = await _customerDio.post('/bookings/self', data: {
      'tour_id': tourId,
      'people_count': peopleCount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return Booking.fromJson(response.data);
  }

  Future<List<Booking>> getMy() async {
    final response = await _customerDio.get('/bookings/my');
    return (response.data as List).map((e) => Booking.fromJson(e)).toList();
  }

  // --- Общее для обоих ---------------------------------------------------

  /// [asCustomer] выбирает, чьим токеном подписать запрос: эндпоинт доступен
  /// и сотруднику (любая бронь), и клиенту (только своя, иначе 403).
  Future<BookingBalance> getBalance(int bookingId, {bool asCustomer = false}) async {
    final dio = asCustomer ? _customerDio : _dio;
    final response = await dio.get('/bookings/$bookingId/balance');
    return BookingBalance.fromJson(response.data);
  }

  /// Сотрудник ставит любой статус; клиент — только «на проверке»/«отменён».
  Future<Booking> updateStatus(int bookingId, String status,
      {bool asCustomer = false}) async {
    final dio = asCustomer ? _customerDio : _dio;
    final response = await dio.patch('/bookings/$bookingId/status', data: {'status': status});
    return Booking.fromJson(response.data);
  }

  /// Оплата картой через демо-шлюз: списывает весь остаток и переводит бронь
  /// в «оплачен». На сервер уходят только последние 4 цифры — полный номер
  /// карты, срок и CVC остаются в форме и никуда не отправляются.
  Future<CheckoutResult> pay(
    int bookingId, {
    required String cardLast4,
    String? cardholder,
    bool asCustomer = true,
  }) async {
    final dio = asCustomer ? _customerDio : _dio;
    final response = await dio.post('/bookings/$bookingId/pay', data: {
      'card_last4': cardLast4,
      if (cardholder != null && cardholder.isNotEmpty) 'cardholder': cardholder,
    });
    return CheckoutResult.fromJson(response.data);
  }
}
