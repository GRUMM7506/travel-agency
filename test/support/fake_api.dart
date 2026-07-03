import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:travel_agency_app/services/api_service.dart';

/// Подменяет транспорт Dio, чтобы тесты рисовали экраны на заранее заданных
/// данных и не ходили в сеть. Ставится на оба клиента ApiService.
class FakeApi implements HttpClientAdapter {
  FakeApi._();

  /// Вешает мок на staff- и customer-клиентов. Вызывать в setUpAll.
  static void install() {
    final adapter = FakeApi._();
    ApiService.instance.client.httpClientAdapter = adapter;
    ApiService.instance.customer.httpClientAdapter = adapter;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    final body = _routes[path] ?? _matchPrefix(path);
    if (body == null) {
      return ResponseBody.fromString('{"detail":"нет мока для $path"}', 404,
          headers: _jsonHeaders);
    }
    return ResponseBody.fromString(jsonEncode(body), 200, headers: _jsonHeaders);
  }

  @override
  void close({bool force = false}) {}

  static const _jsonHeaders = {
    Headers.contentTypeHeader: ['application/json; charset=utf-8'],
  };

  Object? _matchPrefix(String path) {
    if (RegExp(r'^/tours/\d+$').hasMatch(path)) return _tours.first;
    if (RegExp(r'^/bookings/\d+/balance$').hasMatch(path)) {
      return {
        'booking_id': 1,
        'total_cost': '1740.00',
        'paid_amount': '870.00',
        'remaining': '870.00',
        'is_paid': false,
      };
    }
    return null;
  }

  static Map<String, Object> get _routes => {
        '/tours': _tours,
        '/bookings/my': _myBookings,
        '/bookings': _myBookings,
        '/auth/client/me': {
          'client_id': 1,
          'first_name': 'Нигора',
          'last_name': 'Каримова',
          'middle_name': 'Абдуллоевна',
          'email': 'nigora.k@mail.tj',
          'phone': '+992-93-2223344',
          'address': 'Душанбе, ул. Айни, 12',
          'passport': 'A2345678',
          'foreign_passport': 'AB2345678',
        },
        '/bookings/requisites': {
          'recipient': 'ООО «Турагентство Мечта»',
          'card_number': '8600 1234 5678 9012',
          'bank_name': 'Народный банк',
          'comment': 'Укажите номер бронирования в комментарии к переводу.',
        },
        '/reports/dashboard': {
          'tours_count': 60,
          'active_tours_count': 48,
          'clients_count': 40,
          'bookings_count': 90,
          'hotels_count': 30,
          'carriers_count': 15,
          'total_revenue': '265153.00',
          'total_commission': '27050.01',
          'paid_amount': '139890.10',
          'outstanding_amount': '125262.90',
          'bookings_by_status': {
            'заявка': 7,
            'ожидает оплаты': 10,
            'на проверке': 11,
            'оформлен': 14,
            'оплачен': 25,
            'завершён': 14,
            'отменён': 9,
          },
        },
      };

  static List<Map<String, Object?>> get _tours => [
        _tour(1, 'Анталья люкс', 'Турция', 'Анталья', 1290, 12, 5, 'Rixos Downtown'),
        _tour(2, 'Мале всё включено', 'Мальдивы', 'Мале', 3640, 34, 7, 'Safari Island Resort'),
        _tour(3, 'Церматт для двоих', 'Швейцария', 'Церматт', 2410, 61, 10, 'Alpine Lodge'),
        _tour(4, 'Пхукет семейный', 'Таиланд', 'Пхукет', 1105, 88, 8, 'Movenpick Resort'),
        _tour(5, 'Самарканд экскурсионный', 'Узбекистан', 'Самарканд', 690, 21, 5,
            'Registan Plaza'),
        _tour(6, 'Дубай премиум', 'ОАЭ', 'Дубай', 1980, 45, 7, 'Grand Palladium'),
        _tour(7, 'Хургада эконом', 'Египет', 'Хургада', 745, 9, 7, 'Hilton Hurghada'),
        _tour(8, 'Венеция тур выходного дня', 'Италия', 'Венеция', 980, 130, 5,
            'Ca\' del Canale'),
      ];

  static Map<String, Object?> _tour(int id, String name, String country, String city,
      int price, int startsIn, int nights, String hotel) {
    final start = DateTime.now().add(Duration(days: startsIn));
    final end = start.add(Duration(days: nights));
    String d(DateTime x) => x.toIso8601String().split('T').first;
    return {
      'tour_id': id,
      'tour_name': name,
      'country': country,
      'city': city,
      'start_date': d(start),
      'end_date': d(end),
      'base_price': '$price.00',
      'hotel_id': id,
      'carrier_id': id,
      'notes': 'Перелёт, трансфер и страховка включены в стоимость.',
      'image_url': null,
      'duration_days': nights,
      'hotel_name': hotel,
      'hotel_stars': 4 + (id % 2),
      'hotel_image_url': null,
      'carrier_name': 'Turkish Airlines',
      'transport_type': 'авиа',
    };
  }

  static List<Map<String, Object?>> get _myBookings => [
        {
          'booking_id': 1,
          'client_id': 1,
          'tour_id': 1,
          'booking_date': '2026-08-14',
          'people_count': 2,
          'discount_percent': '0',
          'commission_percent': '10',
          'total_cost': '1740.00',
          'status': 'ожидает оплаты',
          'notes': 'Номер с видом на море',
          'client_name': 'Каримова Нигора',
          'tour_name': 'Анталья люкс',
          'tour_country': 'Турция',
          'tour_city': 'Анталья',
          'tour_start_date': '2026-09-11',
          'tour_end_date': '2026-09-16',
        },
        {
          'booking_id': 2,
          'client_id': 1,
          'tour_id': 5,
          'booking_date': '2026-07-02',
          'people_count': 1,
          'discount_percent': '10',
          'commission_percent': '10',
          'total_cost': '621.00',
          'status': 'оплачен',
          'notes': null,
          'client_name': 'Каримова Нигора',
          'tour_name': 'Самарканд экскурсионный',
          'tour_country': 'Узбекистан',
          'tour_city': 'Самарканд',
          'tour_start_date': '2026-09-20',
          'tour_end_date': '2026-09-25',
        },
      ];
}
