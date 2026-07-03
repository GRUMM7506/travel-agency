import '../models/report.dart';
import 'api_service.dart';

class ReportService {
  final _dio = ApiService.instance.client;

  Future<List<SalesReportRow>> salesReport(DateTime from, DateTime to) async {
    final response = await _dio.get('/reports/sales', queryParameters: {
      'date_from': from.toIso8601String().split('T').first,
      'date_to': to.toIso8601String().split('T').first,
    });
    return (response.data as List).map((e) => SalesReportRow.fromJson(e)).toList();
  }

  Future<List<PopularDestinationRow>> popularDestinations() async {
    final response = await _dio.get('/reports/popular-destinations');
    return (response.data as List).map((e) => PopularDestinationRow.fromJson(e)).toList();
  }

  Future<AgencyRevenueRow> agencyRevenue(DateTime from, DateTime to) async {
    final response = await _dio.get('/reports/agency-revenue', queryParameters: {
      'date_from': from.toIso8601String().split('T').first,
      'date_to': to.toIso8601String().split('T').first,
    });
    return AgencyRevenueRow.fromJson(response.data);
  }

  Future<DashboardStats> dashboard() async {
    final response = await _dio.get('/reports/dashboard');
    return DashboardStats.fromJson(response.data);
  }

  Future<List<MonthlyRevenueRow>> monthlyRevenue({int months = 12}) async {
    final response = await _dio.get(
      '/reports/monthly-revenue',
      queryParameters: {'months': months},
    );
    return (response.data as List).map((e) => MonthlyRevenueRow.fromJson(e)).toList();
  }
}
