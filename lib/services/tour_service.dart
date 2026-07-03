import '../models/tour.dart';
import 'api_service.dart';

class TourFilter {
  final String? country;
  final double? priceMin;
  final double? priceMax;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  /// Витрина показывает только то, что ещё можно купить; админке нужен и архив.
  final bool onlyUpcoming;

  TourFilter({
    this.country,
    this.priceMin,
    this.priceMax,
    this.dateFrom,
    this.dateTo,
    this.onlyUpcoming = false,
  });

  /// Витрина перестраивает фильтр при каждом поиске — этот copyWith нужен,
  /// чтобы флаг onlyUpcoming не терялся вместе со старой страной.
  TourFilter copyWith({
    String? country,
    double? priceMin,
    double? priceMax,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? onlyUpcoming,
  }) =>
      TourFilter(
        country: country ?? this.country,
        priceMin: priceMin ?? this.priceMin,
        priceMax: priceMax ?? this.priceMax,
        dateFrom: dateFrom ?? this.dateFrom,
        dateTo: dateTo ?? this.dateTo,
        onlyUpcoming: onlyUpcoming ?? this.onlyUpcoming,
      );

  Map<String, dynamic> toQueryParams() => {
        if (country != null && country!.isNotEmpty) 'country': country,
        if (priceMin != null) 'price_min': priceMin,
        if (priceMax != null) 'price_max': priceMax,
        if (dateFrom != null) 'date_from': dateFrom!.toIso8601String().split('T').first,
        if (dateTo != null) 'date_to': dateTo!.toIso8601String().split('T').first,
        if (onlyUpcoming) 'only_upcoming': true,
      };
}

class TourService {
  final _dio = ApiService.instance.client;

  Future<List<Tour>> getAll({TourFilter? filter}) async {
    final response = await _dio.get('/tours', queryParameters: filter?.toQueryParams());
    return (response.data as List).map((e) => Tour.fromJson(e)).toList();
  }

  Future<List<Tour>> search(String query) async {
    final response = await _dio.get('/tours/search', queryParameters: {'q': query});
    return (response.data as List).map((e) => Tour.fromJson(e)).toList();
  }

  Future<Tour> getById(int id) async {
    final response = await _dio.get('/tours/$id');
    return Tour.fromJson(response.data);
  }

  Future<Tour> create(Tour tour) async {
    final response = await _dio.post('/tours', data: tour.toJson());
    return Tour.fromJson(response.data);
  }

  Future<Tour> update(int id, Tour tour) async {
    final response = await _dio.put('/tours/$id', data: tour.toJson());
    return Tour.fromJson(response.data);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/tours/$id');
  }
}
