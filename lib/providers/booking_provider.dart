import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../services/api_service.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final _service = BookingService();

  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;
  String? _statusFilter;
  String _query = '';

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get statusFilter => _statusFilter;
  String get query => _query;

  /// Список после применения поиска. Фильтр по статусу делает бэкенд
  /// (параметр ?status=), поиск по имени/туру — локально: он идёт по уже
  /// денормализованным полям, лишний запрос ради этого не нужен.
  List<Booking> get visibleBookings {
    if (_query.trim().isEmpty) return _bookings;
    final needle = _query.trim().toLowerCase();
    return _bookings.where((b) {
      final haystack = [
        b.bookingId?.toString(),
        b.clientName,
        b.tourName,
        b.destination,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(needle);
    }).toList();
  }

  /// Сколько броней в каждом статусе — для счётчиков на чипах фильтра.
  Map<String, int> get statusCounts {
    final counts = <String, int>{};
    for (final booking in _bookings) {
      counts[booking.status] = (counts[booking.status] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _bookings = await _service.getAll(status: _statusFilter);
    } catch (e) {
      _error = ApiService.instance.parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setStatusFilter(String? status) async {
    if (_statusFilter == status) return;
    _statusFilter = status;
    await load();
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  Future<Booking?> add(Booking booking) async {
    try {
      final created = await _service.create(booking);
      await load();
      return created;
    } catch (e) {
      _error = ApiService.instance.parseError(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> edit(int id, Booking booking) async {
    await _service.update(id, booking);
    await load();
  }

  /// Смена статуса из админки. Возвращает текст ошибки или null при успехе.
  Future<String?> setStatus(int id, String status) async {
    try {
      await _service.updateStatus(id, status);
      await load();
      return null;
    } catch (e) {
      return ApiService.instance.parseError(e);
    }
  }

  Future<void> remove(int id) async {
    await _service.delete(id);
    await load();
  }
}
