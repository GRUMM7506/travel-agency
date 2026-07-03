import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'providers/client_auth_provider.dart';
import 'screens/auth/client_login_screen.dart';
import 'screens/auth/client_register_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/bookings/booking_form_screen.dart';
import 'screens/bookings/booking_list_screen.dart';
import 'screens/carriers/carrier_form_screen.dart';
import 'screens/carriers/carrier_list_screen.dart';
import 'screens/client/client_bookings_screen.dart';
import 'screens/client/client_profile_screen.dart';
import 'screens/client/tour_detail_screen.dart';
import 'screens/client_mode_screen.dart';
import 'screens/clients/client_form_screen.dart';
import 'screens/clients/client_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/hotels/hotel_form_screen.dart';
import 'screens/hotels/hotel_list_screen.dart';
import 'screens/payments/payment_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/staff/staff_list_screen.dart';
import 'screens/tours/tour_form_screen.dart';
import 'screens/tours/tour_list_screen.dart';

/// Пути CRM — доступны только залогиненному сотруднику.
const _staffPaths = <String>[
  '/admin',
  '/tours',
  '/clients',
  '/bookings',
  '/hotels',
  '/carriers',
  '/reports',
  '/staff',
  '/settings',
];

/// Пути личного кабинета — доступны только залогиненному клиенту.
/// '/client/login' и '/client/register' сюда НЕ входят: на них как раз и
/// редиректим незалогиненного.
const _clientPaths = <String>[
  '/client/bookings',
  '/client/profile',
];

bool _matches(String location, List<String> paths) =>
    paths.any((p) => location == p || location.startsWith('$p/'));

/// Склеивает два ChangeNotifier в один слушатель для GoRouter: redirect
/// зависит и от авторизации сотрудника, и от авторизации клиента.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._staff, this._client) {
    _staff.addListener(notifyListeners);
    _client.addListener(notifyListeners);
  }

  final AuthProvider _staff;
  final ClientAuthProvider _client;

  @override
  void dispose() {
    _staff.removeListener(notifyListeners);
    _client.removeListener(notifyListeners);
    super.dispose();
  }
}

GoRouter createRouter(AuthProvider auth, ClientAuthProvider clientAuth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthListenable(auth, clientAuth),
    redirect: (context, state) {
      // Пока идёт autologin, мы ещё не знаем, залогинен ли пользователь.
      // Редиректить сейчас — значит выкинуть его с защищённого экрана,
      // на который он через секунду имел бы полное право.
      if (auth.isBootstrapping || clientAuth.isBootstrapping) return null;

      final location = state.matchedLocation;

      if (_matches(location, _staffPaths) && !auth.isAuthenticated) {
        // ?from= — чтобы после входа вернуть человека туда, куда он шёл.
        return '/login?from=${Uri.encodeComponent(location)}';
      }
      if (_matches(location, _clientPaths) && !clientAuth.isAuthenticated) {
        return '/client/login';
      }

      // Залогиненного не держим на экране входа.
      if (location == '/login' && auth.isAuthenticated) return '/admin';
      if ((location == '/client/login' || location == '/client/register') &&
          clientAuth.isAuthenticated) {
        return '/client/bookings';
      }

      return null;
    },
    routes: [
      // --- Публичная витрина ---------------------------------------------
      GoRoute(path: '/', builder: (context, state) => const ClientModeScreen()),
      GoRoute(
        path: '/tour/:id',
        builder: (context, state) => TourDetailScreen(
          tourId: int.parse(state.pathParameters['id']!),
        ),
      ),

      // --- Вход ------------------------------------------------------------
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/client/login',
        builder: (context, state) => const ClientLoginScreen(),
      ),
      GoRoute(
        path: '/client/register',
        builder: (context, state) => const ClientRegisterScreen(),
      ),

      // --- Личный кабинет клиента ------------------------------------------
      GoRoute(
        path: '/client/bookings',
        builder: (context, state) => const ClientBookingsScreen(),
      ),
      GoRoute(
        path: '/client/profile',
        builder: (context, state) => const ClientProfileScreen(),
      ),

      // --- Админка ---------------------------------------------------------
      GoRoute(path: '/admin', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/tours', builder: (context, state) => const TourListScreen()),
      GoRoute(path: '/tours/new', builder: (context, state) => const TourFormScreen()),
      GoRoute(
        path: '/tours/:id/edit',
        builder: (context, state) => TourFormScreen(
          tourId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/clients', builder: (context, state) => const ClientListScreen()),
      GoRoute(
        path: '/clients/new',
        builder: (context, state) => const ClientFormScreen(),
      ),
      GoRoute(
        path: '/clients/:id/edit',
        builder: (context, state) => ClientFormScreen(
          clientId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/bookings', builder: (context, state) => const BookingListScreen()),
      GoRoute(path: '/bookings/new', builder: (context, state) => const BookingFormScreen()),
      GoRoute(
        path: '/bookings/:id/edit',
        builder: (context, state) => BookingFormScreen(
          bookingId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/bookings/:id/payments',
        builder: (context, state) => PaymentScreen(
          bookingId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
      GoRoute(path: '/hotels', builder: (context, state) => const HotelListScreen()),
      GoRoute(path: '/hotels/new', builder: (context, state) => const HotelFormScreen()),
      GoRoute(
        path: '/hotels/:id/edit',
        builder: (context, state) => HotelFormScreen(
          hotelId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/carriers', builder: (context, state) => const CarrierListScreen()),
      GoRoute(
        path: '/carriers/new',
        builder: (context, state) => const CarrierFormScreen(),
      ),
      GoRoute(
        path: '/carriers/:id/edit',
        builder: (context, state) => CarrierFormScreen(
          carrierId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/staff', builder: (context, state) => const StaffListScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ],
  );
}
