import 'package:flutter/foundation.dart';

import '../models/booking_balance.dart';
import '../models/payment.dart';
import '../services/api_service.dart';
import '../services/booking_service.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final _service = PaymentService();
  final _bookingService = BookingService();

  List<Payment> _payments = [];
  BookingBalance? _balance;
  bool _isLoading = false;
  String? _error;

  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Остаток к оплате приходит с бэкенда (GET /bookings/{id}/balance), а не
  /// считается на клиенте: сумма платежей и total_cost — источник правды в БД.
  BookingBalance? get balance => _balance;

  double get totalPaid => _balance?.paidAmount ?? _payments.fold(0.0, (sum, p) => sum + p.amount);

  Future<void> load({int? bookingId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _payments = await _service.getAll(bookingId: bookingId);
      _balance = bookingId != null ? await _bookingService.getBalance(bookingId) : null;
    } catch (e) {
      _error = ApiService.instance.parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Возвращает текст ошибки или null при успехе.
  Future<String?> add(Payment payment) async {
    try {
      await _service.create(payment);
      await load(bookingId: payment.bookingId);
      return null;
    } catch (e) {
      return ApiService.instance.parseError(e);
    }
  }

  Future<String?> remove(int id, {int? bookingId}) async {
    try {
      await _service.delete(id);
      await load(bookingId: bookingId);
      return null;
    } catch (e) {
      return ApiService.instance.parseError(e);
    }
  }
}
