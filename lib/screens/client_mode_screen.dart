import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/tour.dart';
import '../providers/auth_provider.dart';
import '../providers/client_auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/tour_provider.dart';
import '../services/tour_service.dart';
import '../theme/app_theme.dart';
import '../utils/country_flags.dart';
import '../widgets/book_tour_sheet.dart';

enum _SortOption { none, priceAsc, priceDesc, dateAsc }

String _sortLabel(_SortOption option) {
  switch (option) {
    case _SortOption.none:
      return 'По умолчанию';
    case _SortOption.priceAsc:
      return 'Сначала дешевле';
    case _SortOption.priceDesc:
      return 'Сначала дороже';
    case _SortOption.dateAsc:
      return 'По дате отправления';
  }
}

/// Корректное склонение слова «ночь» под число.
String nightsWord(int n) {
  final mod100 = n % 100;
  final mod10 = n % 10;
  if (mod100 >= 11 && mod100 <= 14) return 'ночей';
  if (mod10 == 1) return 'ночь';
  if (mod10 >= 2 && mod10 <= 4) return 'ночи';
  return 'ночей';
}

String _toursWord(int n) {
  final mod100 = n % 100;
  final mod10 = n % 10;
  if (mod100 >= 11 && mod100 <= 14) return 'туров';
  if (mod10 == 1) return 'тур';
  if (mod10 >= 2 && mod10 <= 4) return 'тура';
  return 'туров';
}

class ClientModeScreen extends StatefulWidget {
  const ClientModeScreen({super.key});

  @override
  State<ClientModeScreen> createState() => _ClientModeScreenState();
}

class _ClientModeScreenState extends State<ClientModeScreen> {
  final _dateFormat = DateFormat('d MMM', 'ru');
  final _priceFormat = NumberFormat('#,##0');
  final _searchController = TextEditingController();

  _SortOption _sortOption = _SortOption.none;
  String? _activeCountryChip;
  bool _favoritesOnly = false;

  static const _gridSpacing = 20.0;
  static const _cardHeight = 372.0;

  int _crossAxisCount(double width) {
    if (width < 640) return 1;
    if (width < 1000) return 2;
    if (width < 1400) return 3;
    return 4;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Витрина торгует только тем, что ещё не улетело — прошедшие туры
      // отсекает бэкенд по only_upcoming, а не фильтр на клиенте.
      context.read<TourProvider>().applyFilter(TourFilter(onlyUpcoming: true));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Tour> _sortedTours(List<Tour> tours) {
    final list = List<Tour>.from(tours);
    switch (_sortOption) {
      case _SortOption.priceAsc:
        list.sort((a, b) => a.basePrice.compareTo(b.basePrice));
      case _SortOption.priceDesc:
        list.sort((a, b) => b.basePrice.compareTo(a.basePrice));
      case _SortOption.dateAsc:
        list.sort((a, b) => a.startDate.compareTo(b.startDate));
      case _SortOption.none:
        break;
    }
    return list;
  }

  /// Список после сортировки и, если включён режим «только избранное», фильтра.
  /// Избранное живёт в FavoritesProvider — переживает перезапуск приложения.
  List<Tour> _visibleTours(List<Tour> tours, FavoritesProvider favorites) {
    final sorted = _sortedTours(tours);
    if (!_favoritesOnly) return sorted;
    return sorted.where((t) => t.tourId != null && favorites.contains(t.tourId!)).toList();
  }

  void _submitSearch(String value) {
    final query = value.trim();
    context.read<TourProvider>().applyFilter(
          TourFilter(country: query.isEmpty ? null : query, onlyUpcoming: true),
        );
    setState(() => _activeCountryChip = query.isEmpty ? null : query);
  }

  void _toggleCountryChip(String country) {
    final provider = context.read<TourProvider>();
    if (_activeCountryChip == country) {
      _searchController.clear();
      provider.clearFilter();
      setState(() => _activeCountryChip = null);
    } else {
      _searchController.text = country;
      provider.applyFilter(TourFilter(country: country, onlyUpcoming: true));
      setState(() => _activeCountryChip = country);
    }
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _activeCountryChip = null;
      _favoritesOnly = false;
    });
    context.read<TourProvider>().clearFilter();
  }

  void _openTour(Tour tour) {
    if (tour.tourId == null) return;
    context.push('/tour/${tour.tourId}');
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = _crossAxisCount(width);
    final pad = width < 640 ? 20.0 : 28.0;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        titleSpacing: pad,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: colors.accentPrimary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.near_me, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Мечта'),
          ],
        ),
        actions: _buildAppBarActions(context, colors),
      ),
      body: Consumer2<TourProvider, FavoritesProvider>(
        builder: (context, provider, favorites, _) {
          final tours = _visibleTours(provider.tours, favorites);

          return RefreshIndicator(
            onRefresh: provider.load,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad, 8, pad, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHero(colors, provider),
                        const SizedBox(height: 24),
                        _buildSearchBar(colors),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildCountryChips(colors, provider.tours, pad),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad, 18, pad, 14),
                    child: _buildToolbar(colors, provider, tours.length),
                  ),
                ),
                if (provider.isLoading)
                  _buildSkeletonGrid(crossAxisCount, pad)
                else if (provider.error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildErrorState(colors, provider),
                  )
                else if (tours.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(colors, provider),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, 0, pad, 36),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: _gridSpacing,
                        mainAxisSpacing: _gridSpacing,
                        mainAxisExtent: _cardHeight,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final tour = tours[index];
                          final id = tour.tourId;
                          return _TourCard(
                            key: ValueKey('tour_${id ?? index}'),
                            tour: tour,
                            index: index,
                            priceFormat: _priceFormat,
                            dateFormat: _dateFormat,
                            isFavorite: id != null && favorites.contains(id),
                            onFavoriteToggle:
                                id == null ? null : () => favorites.toggle(id),
                            onTap: () => _openTour(tour),
                            onBook: () => showBookTourSheet(context, tour),
                          );
                        },
                        childCount: tours.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------

  List<Widget> _buildAppBarActions(BuildContext context, ThemeColors colors) {
    final clientAuth = context.watch<ClientAuthProvider>();
    final staffAuth = context.watch<AuthProvider>();
    final compact = MediaQuery.of(context).size.width < 700;

    return [
      IconButton(
        icon: Icon(context.watch<ThemeProvider>().icon, color: colors.textSecondary),
        tooltip: 'Сменить тему',
        onPressed: () => context.read<ThemeProvider>().toggleTheme(),
      ),
      // Сотрудник заходит с той же витрины — если он уже залогинен, ведём
      // прямо в админку, иначе на форму входа.
      IconButton(
        icon: Icon(Icons.admin_panel_settings_outlined, color: colors.textSecondary),
        tooltip: staffAuth.isAuthenticated ? 'В админку' : 'Вход для сотрудников',
        onPressed: () => context.push(staffAuth.isAuthenticated ? '/admin' : '/login'),
      ),
      if (clientAuth.isAuthenticated)
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 20, 0),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () => context.push('/client/bookings'),
            child: Tooltip(
              message: '${clientAuth.account!.fullName} · мои бронирования',
              child: CircleAvatar(
                radius: 17,
                backgroundColor: colors.accentSecondary,
                child: Text(
                  clientAuth.account!.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        )
      else if (compact)
        IconButton(
          icon: Icon(Icons.person_outline, color: colors.accentPrimary),
          tooltip: 'Войти',
          onPressed: () => context.push('/client/login'),
        )
      else
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 20, 8),
          child: FilledButton(
            onPressed: () => context.push('/client/login'),
            child: const Text('Войти'),
          ),
        ),
    ];
  }

  // ---------------------------------------------------------------------
  // Заголовок
  // ---------------------------------------------------------------------

  Widget _buildHero(ThemeColors colors, TourProvider provider) {
    final count = provider.tours.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text('Куда летим?', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 6),
        Text(
          provider.isLoading
              ? 'Подбираем направления…'
              : '$count ${_toursWord(count)} в подборке — от пляжей до горных маршрутов',
          style: TextStyle(color: colors.textSecondary, fontSize: 15, height: 1.4),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Поиск
  // ---------------------------------------------------------------------

  Widget _buildSearchBar(ThemeColors colors) {
    // На узком экране кнопка «Найти» съедала половину строки ввода —
    // там за неё работает клавиша Enter (onSubmitted).
    final showButton = MediaQuery.of(context).size.width >= 560;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: colors.cardShadow(),
        border: colors.isDark ? Border.all(color: colors.border) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search, color: colors.textSecondary, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: colors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Страна или город',
                hintStyle: TextStyle(color: colors.textSecondary, fontSize: 15),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onChanged: (value) {
                if (value.isEmpty) _submitSearch('');
                setState(() {});
              },
              onSubmitted: _submitSearch,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, color: colors.textSecondary, size: 19),
              onPressed: () => _submitSearch(''),
            ),
          if (showButton)
            Padding(
              padding: const EdgeInsets.all(5),
              child: FilledButton(
                onPressed: () => _submitSearch(_searchController.text),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                ),
                child: const Text('Найти'),
              ),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Быстрые фильтры по странам
  // ---------------------------------------------------------------------

  Widget _buildCountryChips(ThemeColors colors, List<Tour> tours, double pad) {
    final seen = <String>{};
    final countries = <String>[];
    for (final t in tours) {
      if (seen.add(t.country)) countries.add(t.country);
      if (countries.length >= 12) break;
    }
    if (countries.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: pad),
        itemCount: countries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final country = countries[index];
          final active = _activeCountryChip == country;
          return GestureDetector(
            onTap: () => _toggleCountryChip(country),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: active ? colors.accentPrimary : colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: active ? null : colors.cardShadow(),
                border:
                    colors.isDark && !active ? Border.all(color: colors.border) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(CountryFlags.getFlag(country),
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 7),
                  Text(
                    country,
                    style: TextStyle(
                      color: active ? Colors.white : colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Панель: счётчик + избранное + сортировка
  // ---------------------------------------------------------------------

  Widget _buildToolbar(ThemeColors colors, TourProvider provider, int shown) {
    return Row(
      children: [
        Expanded(
          child: Text(
            provider.isLoading
                ? ''
                : _favoritesOnly
                    ? 'Избранное: $shown'
                    : 'Найдено: $shown',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Consumer<FavoritesProvider>(
          builder: (context, favorites, _) {
            if (favorites.count == 0 && !_favoritesOnly) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 9),
              child: GestureDetector(
                onTap: () => setState(() => _favoritesOnly = !_favoritesOnly),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _favoritesOnly ? colors.danger : colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: _favoritesOnly ? null : colors.cardShadow(),
                    border: colors.isDark && !_favoritesOnly
                        ? Border.all(color: colors.border)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _favoritesOnly ? Icons.favorite : Icons.favorite_border,
                        size: 15,
                        color: _favoritesOnly ? Colors.white : colors.danger,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${favorites.count}',
                        style: TextStyle(
                          color: _favoritesOnly ? Colors.white : colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        PopupMenuButton<_SortOption>(
          initialValue: _sortOption,
          onSelected: (value) => setState(() => _sortOption = value),
          itemBuilder: (context) => _SortOption.values
              .map((option) => PopupMenuItem(
                    value: option,
                    child: Text(
                      _sortLabel(option),
                      style: TextStyle(
                        color: option == _sortOption
                            ? colors.accentPrimary
                            : colors.textPrimary,
                        fontWeight:
                            option == _sortOption ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ))
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: colors.cardShadow(),
              border: colors.isDark ? Border.all(color: colors.border) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_vert, size: 16, color: colors.textSecondary),
                const SizedBox(width: 7),
                Text(
                  _sortLabel(_sortOption),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Состояния
  // ---------------------------------------------------------------------

  Widget _buildSkeletonGrid(int crossAxisCount, double pad) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 36),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: _gridSpacing,
          mainAxisSpacing: _gridSpacing,
          mainAxisExtent: _cardHeight,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const _SkeletonCard(),
          childCount: crossAxisCount * 2,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors, TourProvider provider) {
    final filtered = provider.filter.country != null;

    // Три разные пустоты — три разные подсказки: пустое избранное, пустая
    // выдача по фильтру и вовсе пустой каталог лечатся по-разному.
    final (icon, title, hint) = _favoritesOnly
        ? (Icons.favorite_border, 'В избранном пусто',
            'Нажимайте на ♥ на карточке тура — он появится здесь.')
        : filtered
            ? (Icons.travel_explore, 'Ничего не нашлось',
                'Попробуйте другую страну или сбросьте фильтр.')
            : (Icons.beach_access_outlined, 'Туров пока нет',
                'Каталог ещё наполняется. Загляните позже.');

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surfaceAlt),
            child: Icon(icon, size: 40, color: colors.textSecondary),
          ),
          const SizedBox(height: 22),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.5),
          ),
          if (_favoritesOnly || filtered) ...[
            const SizedBox(height: 26),
            ElevatedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Показать все туры'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeColors colors, TourProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.danger.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.cloud_off, size: 40, color: colors.danger),
          ),
          const SizedBox(height: 22),
          Text('Не удалось загрузить туры',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            provider.error ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 26),
          ElevatedButton.icon(
            onPressed: provider.load,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Карточка тура
// ===========================================================================

class _TourCard extends StatefulWidget {
  const _TourCard({
    super.key,
    required this.tour,
    required this.index,
    required this.priceFormat,
    required this.dateFormat,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
    required this.onBook,
  });

  final Tour tour;
  final int index;
  final NumberFormat priceFormat;
  final DateFormat dateFormat;
  final bool isFavorite;

  /// null, если у тура нет id (не сохранён) — тогда «в избранное» нечего класть.
  final VoidCallback? onFavoriteToggle;
  final VoidCallback onTap;
  final VoidCallback onBook;

  @override
  State<_TourCard> createState() => _TourCardState();
}

class _TourCardState extends State<_TourCard> with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    Future.delayed(Duration(milliseconds: 40 * (widget.index % 8)), () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final tour = widget.tour;
    final curved = CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic);

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * 18),
          child: child,
        ),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovering ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: colors.cardShadow(raised: _hovering),
            border: colors.isDark ? Border.all(color: colors.border) : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImage(colors, tour),
                  Expanded(child: _buildBody(colors, tour)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(ThemeColors colors, Tour tour) {
    final image = tour.displayImageUrl;
    return SizedBox(
      height: 186,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null)
            Image.network(
              image,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _imageFallback(colors, tour),
              errorBuilder: (_, __, ___) => _imageFallback(colors, tour),
            )
          else
            _imageFallback(colors, tour),
          // Затемнение только у нижней кромки — под подписью страны.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0x8C000000)],
                begin: Alignment.center,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 14,
            right: 56,
            child: Row(
              children: [
                Text(CountryFlags.getFlag(tour.country),
                    style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    '${tour.country}, ${tour.city}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 6, color: Color(0x99000000))],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (tour.startsSoon)
            Positioned(
              top: 14,
              left: 14,
              child: AppPill(
                label: 'Скоро вылет',
                color: colors.accentSecondary,
                icon: Icons.bolt,
                filled: true,
                compact: true,
              ),
            ),
          if (widget.onFavoriteToggle != null)
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: Colors.white.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.onFavoriteToggle,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AnimatedScale(
                      scale: widget.isFavorite ? 1.15 : 1,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: widget.isFavorite
                            ? AppLightColors.danger
                            : const Color(0xFF5A544C),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeColors colors, Tour tour) {
    final nights = tour.nights;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tour.tourName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: [
              AppPill(
                label: '$nights ${nightsWord(nights)}',
                color: colors.textSecondary,
                icon: Icons.dark_mode_outlined,
                compact: true,
              ),
              if (tour.hotelStars != null)
                AppPill(label: '${tour.hotelStars}★', color: colors.warning, compact: true),
              AppPill(
                label: widget.dateFormat.format(tour.startDate),
                color: colors.accentSecondary,
                icon: Icons.flight_takeoff,
                compact: true,
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('от',
                        style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          widget.priceFormat.format(tour.basePrice),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '\$',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: widget.onBook,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  textStyle:
                      const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                child: const Text('Выбрать'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Заглушка, пока фото не загрузилось (или его нет). Смешивать терракоту
  /// с бирюзой напрямую нельзя — на стыке получается грязно-серый; поэтому
  /// подмешиваем оба акцента к фону, а не друг к другу.
  Widget _imageFallback(ThemeColors colors, Tour tour) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(colors.backgroundAlt, colors.accentPrimary, 0.22)!,
            Color.lerp(colors.backgroundAlt, colors.accentSecondary, 0.14)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child:
            Text(CountryFlags.getFlag(tour.country), style: const TextStyle(fontSize: 48)),
      ),
    );
  }
}

// ===========================================================================
// Скелетон загрузки
// ===========================================================================

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shade = Color.lerp(
          colors.surfaceAlt,
          colors.isDark ? colors.background : colors.backgroundAlt,
          _controller.value,
        )!;
        Widget box(double w, double h, [double r = 8]) => Container(
              width: w,
              height: h,
              decoration:
                  BoxDecoration(color: shade, borderRadius: BorderRadius.circular(r)),
            );

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: colors.cardShadow(),
            border: colors.isDark ? Border.all(color: colors.border) : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              box(double.infinity, 186, 0),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box(double.infinity, 15),
                    const SizedBox(height: 9),
                    box(130, 12),
                    const SizedBox(height: 16),
                    Row(children: [
                      box(64, 22, 11),
                      const SizedBox(width: 7),
                      box(44, 22, 11),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
