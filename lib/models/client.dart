class Client {
  final int? clientId;
  final String lastName;
  final String firstName;
  final String? middleName;
  final DateTime? birthDate;
  final String? phone;
  final String? email;
  final String? address;
  final String? passport;
  final String? foreignPassport;
  final String? notes;

  Client({
    this.clientId,
    required this.lastName,
    required this.firstName,
    this.middleName,
    this.birthDate,
    this.phone,
    this.email,
    this.address,
    this.passport,
    this.foreignPassport,
    this.notes,
  });

  String get fullName => '$lastName $firstName ${middleName ?? ''}'.trim();

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        clientId: json['client_id'] as int?,
        lastName: json['last_name'] as String,
        firstName: json['first_name'] as String,
        middleName: json['middle_name'] as String?,
        birthDate: json['birth_date'] != null ? DateTime.parse(json['birth_date']) : null,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        passport: json['passport'] as String?,
        foreignPassport: json['foreign_passport'] as String?,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'last_name': lastName,
        'first_name': firstName,
        'middle_name': middleName,
        'birth_date': birthDate?.toIso8601String().split('T').first,
        'phone': phone,
        'email': email,
        'address': address,
        'passport': passport,
        'foreign_passport': foreignPassport,
        'notes': notes,
      };
}
