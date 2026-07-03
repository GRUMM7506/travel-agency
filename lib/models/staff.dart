/// Сотрудник агентства — учётная запись для входа в CRM.
class Staff {
  final int? staffId;
  final String fullName;
  final String email;
  final String role; // "admin" | "manager"
  final bool isActive;

  const Staff({
    this.staffId,
    required this.fullName,
    required this.email,
    this.role = 'manager',
    this.isActive = true,
  });

  bool get isAdmin => role == 'admin';

  String get roleLabel => isAdmin ? 'Администратор' : 'Менеджер';

  /// Инициалы для аватара в шапке.
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  factory Staff.fromJson(Map<String, dynamic> json) => Staff(
        staffId: json['staff_id'] as int?,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        role: json['role'] as String? ?? 'manager',
        isActive: json['is_active'] as bool? ?? true,
      );

  /// password передаётся отдельно — в модели его не держим.
  Map<String, dynamic> toJson({String? password}) => {
        'full_name': fullName,
        'email': email,
        'role': role,
        'is_active': isActive,
        if (password != null && password.isNotEmpty) 'password': password,
      };

  Staff copyWith({String? fullName, String? email, String? role, bool? isActive}) => Staff(
        staffId: staffId,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
      );
}
