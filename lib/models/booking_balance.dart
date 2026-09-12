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

/// Ответ демо-шлюза — POST /bookings/{id}/pay.
class CheckoutResult {
  final BookingBalance balance;
  final String bookingStatus;
  final double amount;
  final String? paymentMethod;

  const CheckoutResult({
    required this.balance,
    required this.bookingStatus,
    required this.amount,
    this.paymentMethod,
  });

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>;
    return CheckoutResult(
      balance: BookingBalance.fromJson(json['balance'] as Map<String, dynamic>),
      bookingStatus: json['booking_status'] as String,
      amount: double.parse(payment['amount'].toString()),
      paymentMethod: payment['payment_method'] as String?,
    );
  }
}
