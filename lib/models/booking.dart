/// Все статусы жизненного цикла брони. Должны совпадать с Literal
/// BookingStatus в backend/app/schemas/booking.py — иначе PATCH вернёт 422.
class BookingStatuses {
  const BookingStatuses._();

  static const request = 'заявка';
  static const awaitingPayment = 'ожидает оплаты';
  static const underReview = 'на проверке';
  static const confirmed = 'оформлен';
  static const paid = 'оплачен';
  static const completed = 'завершён';
  static const cancelled = 'отменён';

  /// Порядок = типичный путь заявки, в этом же порядке рисуем фильтр.
  static const all = <String>[
    request,
    awaitingPayment,
    underReview,
    confirmed,
    paid,
    completed,
    cancelled,
  ];

  /// Что клиент вправе выставить сам (см. CLIENT_ALLOWED_STATUSES на бэкенде).
  static const clientAllowed = <String>[underReview, cancelled];
}

class Booking {
  final int? bookingId;
  final int clientId;
  final int tourId;
  final DateTime? bookingDate;
  final int peopleCount;
  final double discountPercent;
  final double commissionPercent;
  final double? totalCost;
  final String status;
  final String? notes;

  // Денормализация из связанных таблиц — backend отдаёт их в BookingRead,
  // чтобы список не показывал «Клиент #17 · Тур #5». Только для чтения.
  final String? clientName;
  final String? tourName;
  final String? tourCountry;
  final String? tourCity;
  final DateTime? tourStartDate;
  final DateTime? tourEndDate;

  Booking({
    this.bookingId,
    required this.clientId,
    required this.tourId,
    this.bookingDate,
    required this.peopleCount,
    this.discountPercent = 0,
    this.commissionPercent = 10,
    this.totalCost,
    this.status = BookingStatuses.confirmed,
    this.notes,
    this.clientName,
    this.tourName,
    this.tourCountry,
    this.tourCity,
    this.tourStartDate,
    this.tourEndDate,
  });

  /// Комиссия агентства по этой брони.
  double get commissionAmount => (totalCost ?? 0) * commissionPercent / 100;

  /// «Турция, Анталия» или null, если связь не пришла.
  String? get destination {
    if (tourCountry == null) return null;
    return tourCity == null ? tourCountry : '$tourCountry, $tourCity';
  }

  bool get isCancelled => status == BookingStatuses.cancelled;

  /// Клиент ещё может что-то с ней сделать (сообщить об оплате / отменить).
  bool get isOpenForClient =>
      status != BookingStatuses.cancelled && status != BookingStatuses.completed;

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        bookingId: json['booking_id'] as int?,
        clientId: json['client_id'] as int,
        tourId: json['tour_id'] as int,
        bookingDate:
            json['booking_date'] != null ? DateTime.parse(json['booking_date']) : null,
        peopleCount: json['people_count'] as int,
        discountPercent: double.parse((json['discount_percent'] ?? 0).toString()),
        commissionPercent: double.parse((json['commission_percent'] ?? 10).toString()),
        totalCost:
            json['total_cost'] != null ? double.parse(json['total_cost'].toString()) : null,
        status: json['status'] as String? ?? BookingStatuses.confirmed,
        notes: json['notes'] as String?,
        clientName: json['client_name'] as String?,
        tourName: json['tour_name'] as String?,
        tourCountry: json['tour_country'] as String?,
        tourCity: json['tour_city'] as String?,
        tourStartDate: json['tour_start_date'] != null
            ? DateTime.parse(json['tour_start_date'])
            : null,
        tourEndDate:
            json['tour_end_date'] != null ? DateTime.parse(json['tour_end_date']) : null,
      );

  /// total_cost НЕ отправляется на сервер — он вычисляется в
  /// backend/app/services/booking_service.py.
  Map<String, dynamic> toJson() => {
        'client_id': clientId,
        'tour_id': tourId,
        'booking_date': bookingDate?.toIso8601String().split('T').first,
        'people_count': peopleCount,
        'discount_percent': discountPercent,
        'commission_percent': commissionPercent,
        'status': status,
        'notes': notes,
      };
}
