class Tour {
  final int? tourId;
  final String tourName;
  final String country;
  final String city;
  final DateTime startDate;
  final DateTime endDate;
  final double basePrice;
  final int hotelId;
  final int carrierId;
  final String? notes;
  final int? durationDays;
  final String? imageUrl;

  // Поля из связанных таблиц (backend отдаёт их в TourReadWithRelations).
  // Только для чтения — в toJson не уходят.
  final String? hotelName;
  final int? hotelStars;
  final String? hotelImageUrl;
  final String? carrierName;
  final String? transportType;

  Tour({
    this.tourId,
    required this.tourName,
    required this.country,
    required this.city,
    required this.startDate,
    required this.endDate,
    required this.basePrice,
    required this.hotelId,
    required this.carrierId,
    this.notes,
    this.durationDays,
    this.imageUrl,
    this.hotelName,
    this.hotelStars,
    this.hotelImageUrl,
    this.carrierName,
    this.transportType,
  });

  /// Ночей в туре. duration_days считает PostgreSQL; если его нет — считаем сами.
  int get nights => durationDays ?? endDate.difference(startDate).inDays;

  /// Тур уже прошёл — забронировать его нельзя.
  bool get isPast => endDate.isBefore(DateTime.now());

  /// Отправление в ближайшие две недели — повод показать бейдж «Скоро».
  bool get startsSoon {
    final days = startDate.difference(DateTime.now()).inDays;
    return days >= 0 && days <= 14;
  }

  /// Картинка тура, а если её нет — фото отеля.
  String? get displayImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl;
    if (hotelImageUrl != null && hotelImageUrl!.isNotEmpty) return hotelImageUrl;
    return null;
  }

  factory Tour.fromJson(Map<String, dynamic> json) => Tour(
        tourId: json['tour_id'] as int?,
        tourName: json['tour_name'] as String,
        country: json['country'] as String,
        city: json['city'] as String,
        startDate: DateTime.parse(json['start_date']),
        endDate: DateTime.parse(json['end_date']),
        basePrice: double.parse(json['base_price'].toString()),
        hotelId: json['hotel_id'] as int,
        carrierId: json['carrier_id'] as int,
        notes: json['notes'] as String?,
        durationDays: json['duration_days'] as int?,
        imageUrl: json['image_url'] as String?,
        hotelName: json['hotel_name'] as String?,
        hotelStars: json['hotel_stars'] as int?,
        hotelImageUrl: json['hotel_image_url'] as String?,
        carrierName: json['carrier_name'] as String?,
        transportType: json['transport_type'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'tour_name': tourName,
        'country': country,
        'city': city,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate.toIso8601String().split('T').first,
        'base_price': basePrice,
        'hotel_id': hotelId,
        'carrier_id': carrierId,
        'notes': notes,
        'image_url': imageUrl,
      };
}
