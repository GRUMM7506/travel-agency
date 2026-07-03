import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/tour.dart';
import '../../providers/favorites_provider.dart';
import '../../services/api_service.dart';
import '../../services/tour_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/country_flags.dart';
import '../../widgets/book_tour_sheet.dart';

/// Публичная страница тура. Открывается с витрины и доступна без логина —
/// GET /tours/{id} на бэкенде намеренно не защищён.
class TourDetailScreen extends StatefulWidget {
  const TourDetailScreen({super.key, required this.tourId});

  final int tourId;

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen> {
  final _service = TourService();
  final _dateFormat = DateFormat('d MMMM yyyy', 'ru');
  final _moneyFormat = NumberFormat('#,##0');

  Tour? _tour;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tour = await _service.getById(widget.tourId);
      if (!mounted) return;
      setState(() => _tour = tour);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiService.instance.parseError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _tour == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Тур')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colors.danger),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Тур не найден',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final tour = _tour!;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(tour, colors),
          SliverToBoxAdapter(child: _buildBody(tour, colors)),
        ],
      ),
      bottomNavigationBar: _buildBookingBar(tour, colors),
    );
  }

  // -------------------------------------------------------------------------

  Widget _buildHeader(Tour tour, ThemeColors colors) {
    final image = tour.displayImageUrl;
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: colors.background,
      leading: IconButton(
        icon: const CircleAvatar(
          backgroundColor: Colors.black45,
          child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        // Экран можно открыть и прямой ссылкой — тогда стека для pop нет.
        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
      ),
      actions: [
        Consumer<FavoritesProvider>(
          builder: (context, favorites, _) {
            final isFavorite = favorites.contains(tour.tourId!);
            return IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.black45,
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? colors.danger : Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => favorites.toggle(tour.tourId!),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null)
              Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imageFallback(tour, colors),
              )
            else
              _imageFallback(tour, colors),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xCC000000)],
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(CountryFlags.getFlag(tour.country),
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(
                        '${tour.country}, ${tour.city}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tour.tourName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback(Tour tour, ThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accentPrimary.withValues(alpha: 0.4),
            colors.accentSecondary.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(CountryFlags.getFlag(tour.country),
            style: const TextStyle(fontSize: 72)),
      ),
    );
  }

  Widget _buildBody(Tour tour, ThemeColors colors) {
    final nights = tour.nights;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _factCard(colors, Icons.nights_stay, '$nights',
                    _pluralNights(nights)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _factCard(colors, Icons.flight_takeoff,
                    DateFormat('d MMM', 'ru').format(tour.startDate), 'вылет'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _factCard(
                  colors,
                  Icons.star_outline,
                  tour.hotelStars != null ? '${tour.hotelStars}★' : '—',
                  'отель',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _section(colors, 'Даты поездки', [
            _detailRow(colors, Icons.calendar_month,
                '${_dateFormat.format(tour.startDate)} — ${_dateFormat.format(tour.endDate)}'),
            _detailRow(colors, Icons.schedule, '$nights ${_pluralNights(nights)}'),
          ]),
          if (tour.hotelName != null)
            _section(colors, 'Проживание', [
              _detailRow(colors, Icons.hotel, tour.hotelName!),
              if (tour.hotelStars != null)
                _detailRow(colors, Icons.star_outline, '${tour.hotelStars} звёзд'),
            ]),
          if (tour.carrierName != null)
            _section(colors, 'Транспорт', [
              _detailRow(colors, Icons.airlines, tour.carrierName!),
              if (tour.transportType != null)
                _detailRow(colors, Icons.commute, tour.transportType!),
            ]),
          if (tour.notes != null && tour.notes!.isNotEmpty)
            _section(colors, 'Описание', [
              Text(
                tour.notes!,
                style: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.5),
              ),
            ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.accentSecondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.accentSecondary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: colors.accentSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'После заявки менеджер свяжется с вами и подтвердит бронь. '
                    'Оплатить можно переводом — реквизиты появятся в личном кабинете.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingBar(Tour tour, ThemeColors colors) {
    final isPast = tour.isPast;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Стоимость от',
                      style: TextStyle(color: colors.textSecondary, fontSize: 11.5)),
                  Text(
                    '${_moneyFormat.format(tour.basePrice)} \$',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  Text('за человека',
                      style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isPast ? null : () => showBookTourSheet(context, tour),
                icon: Icon(isPast ? Icons.event_busy : Icons.event_available),
                label: Text(isPast ? 'Тур завершён' : 'Забронировать'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------

  Widget _section(ThemeColors colors, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
        ],
      ),
    );
  }

  Widget _detailRow(ThemeColors colors, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.accentPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _factCard(ThemeColors colors, IconData icon, String value, String label) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 20, color: colors.accentPrimary),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  String _pluralNights(int n) {
    final mod100 = n % 100;
    final mod10 = n % 10;
    if (mod100 >= 11 && mod100 <= 14) return 'ночей';
    if (mod10 == 1) return 'ночь';
    if (mod10 >= 2 && mod10 <= 4) return 'ночи';
    return 'ночей';
  }
}
