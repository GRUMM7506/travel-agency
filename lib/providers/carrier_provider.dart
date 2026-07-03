import 'package:flutter/foundation.dart';

import '../models/carrier.dart';
import '../services/carrier_service.dart';

class CarrierProvider extends ChangeNotifier {
  final _service = CarrierService();

  List<Carrier> _carriers = [];
  bool _isLoading = false;
  String? _error;

  List<Carrier> get carriers => _carriers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _carriers = await _service.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(Carrier carrier) async {
    await _service.create(carrier);
    await load();
  }

  Future<void> edit(int id, Carrier carrier) async {
    await _service.update(id, carrier);
    await load();
  }

  Future<void> remove(int id) async {
    await _service.delete(id);
    await load();
  }
}
