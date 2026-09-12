import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/booking_balance.dart';
import '../services/api_service.dart';
import '../services/booking_service.dart';

/// Бронирования ЗАЛОГИНЕННОГО КЛИЕНТА (личный кабинет).
///
/// Отдельно от BookingProvider: тот работает с /bookings от имени сотрудника
/// и видит брони всего агентства, а этот — только /bookings/my.
class MyBookingsProvider extends ChangeNotifier {
  final _service = BookingService();

  List<Booking> _bookings = [];
  final Map<int, BookingBalance> _balances = {};
  bool _isLoading = false;
  String? _error;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BookingBalance? balanceOf(int bookingId) => _balances[bookingId];

  /// Сколько клиент должен агентству суммарно — для шапки кабинета.
  double get totalOutstanding => _balances.values
      .fold<double>(0, (sum, balance) => sum + balance.remaining);

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _bookings = await _service.getMy();
      await _loadBalances();
    } catch (e) {
      _error = ApiService.instance.parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Остатки тянем параллельно: последовательный цикл на десяток броней
  /// заметно тормозил бы открытие экрана.
  Future<void> _loadBalances() async {
    final ids = _bookings.map((b) => b.bookingId).whereType<int>().toList();
    final results = await Future.wait(
      ids.map((id) => _service.getBalance(id, asCustomer: true)),
    );
    _balances
      ..clear()
      ..addEntries(
        Iterable.generate(ids.length, (i) => MapEntry(ids[i], results[i])),
      );
  }

  /// Создаёт заявку с витрины. Возвращает текст ошибки или null при успехе.
  Future<String?> book({
    required int tourId,
    required int peopleCount,
    String? notes,
  }) async {
    try {
      await _service.createSelf(tourId: tourId, peopleCount: peopleCount, notes: notes);
      await load();
      return null;
    } catch (e) {
      return ApiService.instance.parseError(e);
    }
  }

  /// Оплата картой через демо-шлюз. Возвращает результат платежа либо
  /// пробрасывает текст ошибки — экран показывает то и другое по-разному.
  Future<CheckoutResult> pay(int bookingId, {
    required String cardLast4,
    String? cardholder,
  }) async {
    final result = await _service.pay(
      bookingId,
      cardLast4: cardLast4,
      cardholder: cardholder,
    );
    await load();
    return result;
  }

  /// «Отменить заявку» — единственный статус, который клиенту доступен.
  Future<String?> setStatus(int bookingId, String status) async {
    try {
      await _service.updateStatus(bookingId, status, asCustomer: true);
      await load();
      return null;
    } catch (e) {
      return ApiService.instance.parseError(e);
    }
  }

  void clear() {
    _bookings = [];
    _balances.clear();
    _error = null;
    notifyListeners();
  }
}
