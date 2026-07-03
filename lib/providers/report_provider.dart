import 'package:flutter/foundation.dart';

import '../models/report.dart';
import '../services/api_service.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final _service = ReportService();

  List<SalesReportRow> _salesReport = [];
  List<PopularDestinationRow> _popularDestinations = [];
  List<MonthlyRevenueRow> _monthlyRevenue = [];
  AgencyRevenueRow? _agencyRevenue;
  bool _isLoading = false;
  String? _error;

  List<SalesReportRow> get salesReport => _salesReport;
  List<PopularDestinationRow> get popularDestinations => _popularDestinations;
  List<MonthlyRevenueRow> get monthlyRevenue => _monthlyRevenue;
  AgencyRevenueRow? get agencyRevenue => _agencyRevenue;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Сумма продаж за выбранный период — заголовок вкладки «Продажи».
  double get salesTotal =>
      _salesReport.fold<double>(0, (sum, row) => sum + row.totalCost);

  int get salesPeople =>
      _salesReport.fold<int>(0, (sum, row) => sum + row.peopleCount);

  /// Грузит все четыре отчёта разом.
  ///
  /// Раньше экран вызывал три метода параллельно, и каждый дёргал общий
  /// _isLoading: первый же завершившийся гасил индикатор, пока два других
  /// ещё летели. Теперь загрузка одна, флаг снимается в самом конце.
  Future<void> loadAll(DateTime from, DateTime to) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.salesReport(from, to),
        _service.popularDestinations(),
        _service.agencyRevenue(from, to),
        _service.monthlyRevenue(),
      ]);
      _salesReport = results[0] as List<SalesReportRow>;
      _popularDestinations = results[1] as List<PopularDestinationRow>;
      _agencyRevenue = results[2] as AgencyRevenueRow;
      _monthlyRevenue = results[3] as List<MonthlyRevenueRow>;
    } catch (e) {
      _error = ApiService.instance.parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
