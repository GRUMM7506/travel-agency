import 'package:flutter/foundation.dart';

import '../models/client.dart';
import '../services/client_service.dart';

class ClientProvider extends ChangeNotifier {
  final _service = ClientService();

  List<Client> _clients = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _clients = await _service.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      return load();
    }
    _isLoading = true;
    notifyListeners();
    try {
      _clients = await _service.search(query);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(Client client) async {
    await _service.create(client);
    await load();
  }

  Future<void> edit(int id, Client client) async {
    await _service.update(id, client);
    await load();
  }

  Future<void> remove(int id) async {
    await _service.delete(id);
    await load();
  }
}
