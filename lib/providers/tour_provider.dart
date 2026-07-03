import 'package:flutter/foundation.dart';

import '../models/tour.dart';
import '../services/tour_service.dart';

class TourProvider extends ChangeNotifier {
  final _service = TourService();

  List<Tour> _tours = [];
  bool _isLoading = false;
  String? _error;
  TourFilter _filter = TourFilter();

  List<Tour> get tours => _tours;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TourFilter get filter => _filter;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _tours = await _service.getAll(filter: _filter);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyFilter(TourFilter filter) async {
    _filter = filter;
    await load();
  }

  /// Сбрасывает поисковые условия, но СОХРАНЯЕТ onlyUpcoming: на витрине
  /// «сбросить фильтр» не должно внезапно вываливать прошлогодние туры.
  Future<void> clearFilter() async {
    _filter = TourFilter(onlyUpcoming: _filter.onlyUpcoming);
    await load();
  }

  Future<void> add(Tour tour) async {
    await _service.create(tour);
    await load();
  }

  Future<void> edit(int id, Tour tour) async {
    await _service.update(id, tour);
    await load();
  }

  Future<void> remove(int id) async {
    await _service.delete(id);
    await load();
  }
}
