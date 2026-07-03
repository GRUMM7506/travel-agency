import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/carrier_provider.dart';
import 'providers/client_auth_provider.dart';
import 'providers/client_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/hotel_provider.dart';
import 'providers/my_bookings_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/report_provider.dart';
import 'providers/staff_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/tour_provider.dart';
import 'router.dart';
import 'services/token_storage.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Русские названия месяцев в DateFormat('d MMMM yyyy', 'ru') — без этого
  // intl бросает LocaleDataException на первом же форматировании.
  await initializeDateFormatting('ru');

  // Токены поднимаем ДО первого кадра: интерсептор Dio читает их синхронно,
  // и без предзагрузки самый первый запрос ушёл бы без Authorization.
  await TokenStorage.instance.load();

  runApp(const TravelAgencyApp());
}

class TravelAgencyApp extends StatefulWidget {
  const TravelAgencyApp({super.key});

  @override
  State<TravelAgencyApp> createState() => _TravelAgencyAppState();
}

class _TravelAgencyAppState extends State<TravelAgencyApp> {
  // Провайдеры авторизации и роутер создаются здесь, а не в MultiProvider:
  // роутеру они нужны как refreshListenable ещё до построения дерева.
  final _authProvider = AuthProvider();
  final _clientAuthProvider = ClientAuthProvider();
  final _themeProvider = ThemeProvider();
  final _favoritesProvider = FavoritesProvider();
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(_authProvider, _clientAuthProvider);

    // Autologin обеих ролей и настройки — параллельно, чтобы не задерживать
    // первый кадр на две последовательные сетевые проверки.
    _authProvider.tryAutoLogin();
    _clientAuthProvider.tryAutoLogin();
    _themeProvider.load();
    _favoritesProvider.load();
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _clientAuthProvider.dispose();
    _themeProvider.dispose();
    _favoritesProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _clientAuthProvider),
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider.value(value: _favoritesProvider),
        ChangeNotifierProvider(create: (_) => HotelProvider()),
        ChangeNotifierProvider(create: (_) => CarrierProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => TourProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
        ChangeNotifierProvider(create: (_) => MyBookingsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'Туристическое агентство',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
