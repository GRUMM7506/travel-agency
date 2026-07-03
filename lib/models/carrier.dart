class Carrier {
  final int? carrierId;
  final String companyName;
  final String transportType;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final double tripCost;
  final String? schedule;
  final String? notes;
  final String? imageUrl;

  Carrier({
    this.carrierId,
    required this.companyName,
    required this.transportType,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    required this.tripCost,
    this.schedule,
    this.notes,
    this.imageUrl,
  });

  factory Carrier.fromJson(Map<String, dynamic> json) => Carrier(
        carrierId: json['carrier_id'] as int?,
        companyName: json['company_name'] as String,
        transportType: json['transport_type'] as String,
        contactPerson: json['contact_person'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        tripCost: double.parse(json['trip_cost'].toString()),
        schedule: json['schedule'] as String?,
        notes: json['notes'] as String?,
        imageUrl: json['image_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'company_name': companyName,
        'transport_type': transportType,
        'contact_person': contactPerson,
        'phone': phone,
        'email': email,
        'address': address,
        'trip_cost': tripCost,
        'schedule': schedule,
        'notes': notes,
        'image_url': imageUrl,
      };
}
