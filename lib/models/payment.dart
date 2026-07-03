class Payment {
  final int? paymentId;
  final int bookingId;
  final DateTime? paymentDate;
  final double amount;
  final String? paymentMethod;
  final String? notes;

  Payment({
    this.paymentId,
    required this.bookingId,
    this.paymentDate,
    required this.amount,
    this.paymentMethod,
    this.notes,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        paymentId: json['payment_id'] as int?,
        bookingId: json['booking_id'] as int,
        paymentDate: json['payment_date'] != null ? DateTime.parse(json['payment_date']) : null,
        amount: double.parse(json['amount'].toString()),
        paymentMethod: json['payment_method'] as String?,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'booking_id': bookingId,
        'payment_date': paymentDate?.toIso8601String().split('T').first,
        'amount': amount,
        'payment_method': paymentMethod,
        'notes': notes,
      };
}
