import 'package:flutter/foundation.dart';

import '../models/report.dart';
import '../services/api_service.dart';
import '../services/report_service.dart';

/// Сводка для главного экрана админки. Отдельный провайдер, чтобы главная
/// не тянула на себя все семь CRUD-провайдеров ради трёх цифр.
class DashboardProvider extends ChangeNotifier {
  final _service = ReportService();

  DashboardStats? _stats;
  bool _isLoading = false;
  String? _error;

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _stats = await _service.dashboard();
    } catch (e) {
      _error = ApiService.instance.parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Сбросить при выходе из аккаунта, чтобы следующий сотрудник не увидел
  /// мельком цифры предыдущей сессии.
  void clear() {
    _stats = null;
    _error = null;
    notifyListeners();
  }
}
