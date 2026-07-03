import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'token_storage.dart';

/// Базовый URL backend.
///
/// Android-эмулятор не видит localhost хост-машины — для него 10.0.2.2.
/// Для физического устройства пропишите реальный IP машины с backend через
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000`.
String get kApiBaseUrl {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) return override;
  if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000';
  return 'http://localhost:8000';
}

/// Кто делает запрос — от этого зависит, какой токен подставит интерсептор.
enum ApiAudience {
  /// CRM: сотрудник агентства.
  staff,

  /// Личный кабинет: клиент.
  customer,
}

/// Единая точка доступа к API.
///
/// Держит ДВА независимых Dio-клиента, потому что backend выдаёт два
/// несовместимых вида токенов (`"type": "staff"` и `"type": "client"`):
/// подставить не тот — гарантированный 401. Сотрудник и клиент могут быть
/// залогинены одновременно на одном устройстве.
class ApiService {
  ApiService._internal() {
    _staffDio = _build(ApiAudience.staff);
    _customerDio = _build(ApiAudience.customer);
  }

  static final ApiService instance = ApiService._internal();

  late final Dio _staffDio;
  late final Dio _customerDio;

  /// Клиент для CRM-запросов сотрудника.
  ///
  /// Исторически называется `client` — это HTTP-клиент, а не клиент агентства;
  /// имя сохранено, чтобы не переписывать все существующие *_service.dart.
  Dio get client => _staffDio;

  /// Клиент для личного кабинета (эндпоинты /auth/client/*, /bookings/self,
  /// /bookings/my).
  Dio get customer => _customerDio;

  Dio dioFor(ApiAudience audience) =>
      audience == ApiAudience.staff ? _staffDio : _customerDio;

  /// Вызывается, когда сервер ответил 401 — токен протух или отозван.
  /// AuthProvider/ClientAuthProvider подписываются сюда, чтобы разлогинить
  /// пользователя и увести его на экран входа.
  void Function()? onStaffUnauthorized;
  void Function()? onCustomerUnauthorized;

  Dio _build(ApiAudience audience) {
    final dio = Dio(
      BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        receiveDataWhenStatusError: true,
        contentType: 'application/json',
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = audience == ApiAudience.staff
              ? TokenStorage.instance.staffToken
              : TokenStorage.instance.clientToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Чистим протухший токен и сигналим провайдеру. Сам редирект
            // делает GoRouter — он слушает провайдер через refreshListenable.
            if (audience == ApiAudience.staff) {
              TokenStorage.instance.clearStaffToken();
              onStaffUnauthorized?.call();
            } else {
              TokenStorage.instance.clearClientToken();
              onCustomerUnauthorized?.call();
            }
          }
          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: false));
    }

    return dio;
  }

  /// Единая обработка ошибок Dio -> человекочитаемое сообщение.
  String parseError(Object error) {
    if (error is! DioException) return error.toString();

    final detail = error.response?.data;
    if (detail is Map && detail['detail'] != null) {
      final value = detail['detail'];
      // 422 от Pydantic приходит списком объектов, а не строкой.
      if (value is List && value.isNotEmpty) {
        final first = value.first;
        if (first is Map && first['msg'] != null) return first['msg'].toString();
      }
      return value.toString();
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Сервер не отвечает. Проверьте, запущен ли backend.';
      case DioExceptionType.connectionError:
        return 'Нет связи с сервером ($kApiBaseUrl).';
      default:
        return error.message ?? 'Неизвестная ошибка сети';
    }
  }
}
