import 'package:flutter/foundation.dart';

import '../models/hotel.dart';
import '../services/hotel_service.dart';

class HotelProvider extends ChangeNotifier {
  final _service = HotelService();

  List<Hotel> _hotels = [];
  bool _isLoading = false;
  String? _error;

  List<Hotel> get hotels => _hotels;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _hotels = await _service.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(Hotel hotel) async {
    await _service.create(hotel);
    await load();
  }

  Future<void> edit(int id, Hotel hotel) async {
    await _service.update(id, hotel);
    await load();
  }

  Future<void> remove(int id) async {
    await _service.delete(id);
    await load();
  }
}
