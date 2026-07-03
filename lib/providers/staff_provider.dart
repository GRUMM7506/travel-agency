import 'package:flutter/foundation.dart';

import '../models/staff.dart';
import '../services/api_service.dart';
import '../services/staff_service.dart';

class StaffProvider extends ChangeNotifier {
  final _service = StaffService();

  List<Staff> _staff = [];
  bool _isLoading = false;
  String? _error;

  List<Staff> get staff => _staff;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _staff = await _service.getAll();
    } catch (e) {
      _error = ApiService.instance.parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Возвращает текст ошибки или null при успехе — экрану удобнее показать
  /// её в снек-баре, чем лезть в поле провайдера.
  Future<String?> add(Staff staff, String password) async {
    try {
      await _service.create(staff, password);
      await load();
      return null;
    } catch (e) {
      return ApiService.instance.parseError(e);
    }
  }

  Future<String?> edit(int id, Staff staff, {String? password}) async {
    try {
      await _service.update(id, staff, password: password);
      await load();
      return null;
    } catch (e) {
      return ApiService.instance.parseError(e);
    }
  }

  Future<String?> remove(int id) async {
    try {
      await _service.delete(id);
      await load();
      return null;
    } catch (e) {
      return ApiService.instance.parseError(e);
    }
  }
}
