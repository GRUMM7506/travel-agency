class Hotel {
  final int? hotelId;
  final String hotelName;
  final String country;
  final String city;
  final String? address;
  final String? category;
  final int? starRating;
  final String? phone;
  final String? email;
  final double nightPrice;
  final String? notes;
  final String? imageUrl;

  Hotel({
    this.hotelId,
    required this.hotelName,
    required this.country,
    required this.city,
    this.address,
    this.category,
    this.starRating,
    this.phone,
    this.email,
    required this.nightPrice,
    this.notes,
    this.imageUrl,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) => Hotel(
        hotelId: json['hotel_id'] as int?,
        hotelName: json['hotel_name'] as String,
        country: json['country'] as String,
        city: json['city'] as String,
        address: json['address'] as String?,
        category: json['category'] as String?,
        starRating: json['star_rating'] as int?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        nightPrice: double.parse(json['night_price'].toString()),
        notes: json['notes'] as String?,
        imageUrl: json['image_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'hotel_name': hotelName,
        'country': country,
        'city': city,
        'address': address,
        'category': category,
        'star_rating': starRating,
        'phone': phone,
        'email': email,
        'night_price': nightPrice,
        'notes': notes,
        'image_url': imageUrl,
      };
}
