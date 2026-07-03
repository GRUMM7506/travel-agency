import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:travel_agency_app/providers/auth_provider.dart';
import 'package:travel_agency_app/providers/booking_provider.dart';
import 'package:travel_agency_app/providers/client_auth_provider.dart';
import 'package:travel_agency_app/providers/dashboard_provider.dart';
import 'package:travel_agency_app/providers/favorites_provider.dart';
import 'package:travel_agency_app/providers/my_bookings_provider.dart';
import 'package:travel_agency_app/providers/theme_provider.dart';
import 'package:travel_agency_app/providers/tour_provider.dart';
import 'package:travel_agency_app/screens/auth/login_screen.dart';
import 'package:travel_agency_app/screens/client/client_bookings_screen.dart';
import 'package:travel_agency_app/screens/client/tour_detail_screen.dart';
import 'package:travel_agency_app/screens/client_mode_screen.dart';
import 'package:travel_agency_app/screens/home_screen.dart';
import 'package:travel_agency_app/theme/app_theme.dart';

import 'support/fake_api.dart';

/// Снимки ключевых экранов. Гоняются на замоканном API, поэтому проверяют
/// именно вёрстку: переполнения RenderFlex тест валит сам, а голдены дают
/// увидеть результат редизайна, не запуская приложение.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
    FakeApi.install();
    // SharedPreferences в тестах недоступен — провайдеры это переживают,
    // но пусть не шумят в логах.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Widget wrap(Widget child, {required Brightness brightness}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => child),
        // Заглушки для маршрутов, на которые ведут кнопки экрана.
        GoRoute(path: '/login', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/client/login', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/client/bookings', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/client/profile', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/tour/:id', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/admin', builder: (_, __) => const SizedBox()),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ClientAuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => TourProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => MyBookingsProvider()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        routerConfig: router,
      ),
    );
  }

  Future<void> shoot(
    WidgetTester tester,
    Widget screen,
    String name, {
    Size size = const Size(1280, 900),
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(screen, brightness: brightness));
    // Ждём postFrameCallback (загрузка данных), затем анимации появления
    // карточек: они заводятся через Future.delayed, поэтому нужен именно
    // pumpAndSettle — иначе тест падает на «timersPending».
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('витрина — светлая, десктоп', (tester) async {
    await shoot(tester, const ClientModeScreen(), 'storefront_light');
  });

  testWidgets('витрина — тёмная, десктоп', (tester) async {
    await shoot(tester, const ClientModeScreen(), 'storefront_dark',
        brightness: Brightness.dark);
  });

  testWidgets('витрина — телефон', (tester) async {
    await shoot(tester, const ClientModeScreen(), 'storefront_phone',
        size: const Size(430, 932));
  });

  testWidgets('вход сотрудника', (tester) async {
    await shoot(tester, const LoginScreen(), 'login_light', size: const Size(900, 800));
  });

  testWidgets('кабинет клиента', (tester) async {
    await shoot(tester, const ClientBookingsScreen(), 'client_bookings',
        size: const Size(900, 1000));
  });

  testWidgets('страница тура', (tester) async {
    await shoot(tester, const TourDetailScreen(tourId: 1), 'tour_detail',
        size: const Size(900, 1000));
  });

  testWidgets('главная админки', (tester) async {
    await shoot(tester, const HomeScreen(), 'admin_home', size: const Size(1280, 1000));
  });
}
