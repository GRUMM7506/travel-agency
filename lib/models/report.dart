class SalesReportRow {
  final int bookingId;
  final DateTime bookingDate;
  final String clientName;
  final String tourName;
  final int peopleCount;
  final double totalCost;
  final String status;

  SalesReportRow({
    required this.bookingId,
    required this.bookingDate,
    required this.clientName,
    required this.tourName,
    required this.peopleCount,
    required this.totalCost,
    required this.status,
  });

  factory SalesReportRow.fromJson(Map<String, dynamic> json) => SalesReportRow(
        bookingId: json['booking_id'] as int,
        bookingDate: DateTime.parse(json['booking_date']),
        clientName: json['client_name'] as String,
        tourName: json['tour_name'] as String,
        peopleCount: json['people_count'] as int,
        totalCost: double.parse(json['total_cost'].toString()),
        status: json['status'] as String,
      );
}

class PopularDestinationRow {
  final String country;
  final String city;
  final int bookingsCount;
  final int totalPeople;

  PopularDestinationRow({
    required this.country,
    required this.city,
    required this.bookingsCount,
    required this.totalPeople,
  });

  factory PopularDestinationRow.fromJson(Map<String, dynamic> json) => PopularDestinationRow(
        country: json['country'] as String,
        city: json['city'] as String,
        bookingsCount: json['bookings_count'] as int,
        totalPeople: json['total_people'] as int,
      );
}

class AgencyRevenueRow {
  final String period;
  final double totalCommission;
  final int bookingsCount;

  AgencyRevenueRow({
    required this.period,
    required this.totalCommission,
    required this.bookingsCount,
  });

  factory AgencyRevenueRow.fromJson(Map<String, dynamic> json) => AgencyRevenueRow(
        period: json['period'] as String,
        totalCommission: double.parse(json['total_commission'].toString()),
        bookingsCount: json['bookings_count'] as int,
      );
}

/// Комиссия по месяцам — данные для столбчатого графика на экране отчётов.
class MonthlyRevenueRow {
  final String month; // "2026-08"
  final double totalCommission;
  final int bookingsCount;

  MonthlyRevenueRow({
    required this.month,
    required this.totalCommission,
    required this.bookingsCount,
  });

  /// "2026-08" -> "авг 26" для подписи оси.
  String get shortLabel {
    const names = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    final parts = month.split('-');
    if (parts.length != 2) return month;
    final index = int.tryParse(parts[1]);
    if (index == null || index < 1 || index > 12) return month;
    return '${names[index - 1]} ${parts[0].substring(2)}';
  }

  factory MonthlyRevenueRow.fromJson(Map<String, dynamic> json) => MonthlyRevenueRow(
        month: json['month'] as String,
        totalCommission: double.parse(json['total_commission'].toString()),
        bookingsCount: json['bookings_count'] as int,
      );
}

/// Сводка для главного экрана админки — GET /reports/dashboard.
class DashboardStats {
  final int toursCount;
  final int activeToursCount;
  final int clientsCount;
  final int bookingsCount;
  final int hotelsCount;
  final int carriersCount;
  final double totalRevenue;
  final double totalCommission;
  final double paidAmount;
  final double outstandingAmount;
  final Map<String, int> bookingsByStatus;

  DashboardStats({
    required this.toursCount,
    required this.activeToursCount,
    required this.clientsCount,
    required this.bookingsCount,
    required this.hotelsCount,
    required this.carriersCount,
    required this.totalRevenue,
    required this.totalCommission,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.bookingsByStatus,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        toursCount: json['tours_count'] as int,
        activeToursCount: json['active_tours_count'] as int,
        clientsCount: json['clients_count'] as int,
        bookingsCount: json['bookings_count'] as int,
        hotelsCount: json['hotels_count'] as int,
        carriersCount: json['carriers_count'] as int,
        totalRevenue: double.parse(json['total_revenue'].toString()),
        totalCommission: double.parse(json['total_commission'].toString()),
        paidAmount: double.parse(json['paid_amount'].toString()),
        outstandingAmount: double.parse(json['outstanding_amount'].toString()),
        bookingsByStatus: (json['bookings_by_status'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, value as int)),
      );
}
