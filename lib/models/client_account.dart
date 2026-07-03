/// Залогиненный клиент — та же карточка Client, что видит сотрудник в админке,
/// но без служебных полей.
class ClientAccount {
  final int clientId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? email;
  final String? phone;
  final String? address;
  final String? passport;
  final String? foreignPassport;

  const ClientAccount({
    required this.clientId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.email,
    this.phone,
    this.address,
    this.passport,
    this.foreignPassport,
  });

  String get fullName => '$lastName $firstName'.trim();

  String get initials {
    final l = lastName.trim();
    final f = firstName.trim();
    if (l.isEmpty && f.isEmpty) return '?';
    if (l.isEmpty) return f.substring(0, 1).toUpperCase();
    if (f.isEmpty) return l.substring(0, 1).toUpperCase();
    return (l.substring(0, 1) + f.substring(0, 1)).toUpperCase();
  }

  factory ClientAccount.fromJson(Map<String, dynamic> json) => ClientAccount(
        clientId: json['client_id'] as int,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        middleName: json['middle_name'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        passport: json['passport'] as String?,
        foreignPassport: json['foreign_passport'] as String?,
      );

  /// Тело для PUT /auth/client/me — email не отправляем, он же логин.
  Map<String, dynamic> toProfileJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName,
        'phone': phone,
        'address': address,
        'passport': passport,
        'foreign_passport': foreignPassport,
      };

  ClientAccount copyWith({
    String? firstName,
    String? lastName,
    String? middleName,
    String? phone,
    String? address,
    String? passport,
    String? foreignPassport,
  }) =>
      ClientAccount(
        clientId: clientId,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        middleName: middleName ?? this.middleName,
        email: email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        passport: passport ?? this.passport,
        foreignPassport: foreignPassport ?? this.foreignPassport,
      );
}
