/// Остаток к оплате по бронированию — ответ GET /bookings/{id}/balance.
class BookingBalance {
  final int bookingId;
  final double totalCost;
  final double paidAmount;
  final double remaining;
  final bool isPaid;

  const BookingBalance({
    required this.bookingId,
    required this.totalCost,
    required this.paidAmount,
    required this.remaining,
    required this.isPaid,
  });

  /// Доля оплаченного, 0..1 — для полосы прогресса.
  double get progress {
    if (totalCost <= 0) return 1;
    final value = paidAmount / totalCost;
    return value.clamp(0, 1).toDouble();
  }

  factory BookingBalance.fromJson(Map<String, dynamic> json) => BookingBalance(
        bookingId: json['booking_id'] as int,
        totalCost: double.parse(json['total_cost'].toString()),
        paidAmount: double.parse(json['paid_amount'].toString()),
        remaining: double.parse(json['remaining'].toString()),
        isPaid: json['is_paid'] as bool? ?? false,
      );
}

/// Реквизиты для перевода — ответ GET /bookings/requisites.
class PaymentRequisites {
  final String recipient;
  final String cardNumber;
  final String bankName;
  final String comment;

  const PaymentRequisites({
    required this.recipient,
    required this.cardNumber,
    required this.bankName,
    required this.comment,
  });

  factory PaymentRequisites.fromJson(Map<String, dynamic> json) => PaymentRequisites(
        recipient: json['recipient'] as String,
        cardNumber: json['card_number'] as String,
        bankName: json['bank_name'] as String,
        comment: json['comment'] as String,
      );
}
