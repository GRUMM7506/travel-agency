import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/tour.dart';
import '../../providers/tour_provider.dart';
import '../../services/tour_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/country_flags.dart';

class TourListScreen extends StatefulWidget {
  const TourListScreen({super.key});

  @override
  State<TourListScreen> createState() => _TourListScreenState();
}

class _TourListScreenState extends State<TourListScreen> {
  final _dateFormat = DateFormat('dd.MM.yyyy');
  final _moneyFormat = NumberFormat('#,##0');
  final _countryController = TextEditingController();
  final _priceMinController = TextEditingController();
  final _priceMaxController = TextEditingController();

  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TourProvider>().load();
    });
  }

  @override
  void dispose() {
    _countryController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final country = _countryController.text.trim();
    context.read<TourProvider>().applyFilter(
          TourFilter(
            country: country.isEmpty ? null : country,
            priceMin: double.tryParse(_priceMinController.text.replaceAll(',', '.')),
            priceMax: double.tryParse(_priceMaxController.text.replaceAll(',', '.')),
          ),
        );
  }

  void _resetFilter() {
    _countryController.clear();
    _priceMinController.clear();
    _priceMaxController.clear();
    context.read<TourProvider>().clearFilter();
  }

  bool get _hasActiveFilter =>
      _countryController.text.trim().isNotEmpty ||
      _priceMinController.text.trim().isNotEmpty ||
      _priceMaxController.text.trim().isNotEmpty;

  Future<void> _confirmDelete(Tour tour) async {
    final colors = ThemeColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить тур?'),
        content: Text(
          'Тур «${tour.tourName}» будет удалён без возможности восстановления.\n\n'
          'Если по нему уже есть бронирования, сервер откажет в удалении.',
        ),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text('Удалить', style: TextStyle(color: colors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<TourProvider>().remove(tour.tourId!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось удалить: связанные бронирования. ($e)')),
      );
    }
  }

  int _crossAxisCount(double width) {
    if (width < 640) return 1;
    if (width < 1000) return 2;
    if (width < 1400) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = _crossAxisCount(width);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Туры'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            tooltip: 'Фильтры',
            color: _hasActiveFilter ? colors.accentPrimary : null,
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: () => context.read<TourProvider>().load(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tours/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить тур'),
      ),
      body: Container(
        color: colors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _showFilters
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _buildFilterBar(colors, width),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            Expanded(
              child: Consumer<TourProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.tours.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.error != null && provider.tours.isEmpty) {
                    return _errorState(colors, provider);
                  }
                  if (provider.tours.isEmpty) {
                    return _emptyState(colors);
                  }

                  return RefreshIndicator(
                    onRefresh: provider.load,
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        // Фиксированная высота вместо aspectRatio: карточка
                        // с картинкой не резиновая, и при узкой колонке
                        // пропорция ломала вёрстку переполнением.
                        mainAxisExtent: 250,
                      ),
                      itemCount: provider.tours.length,
                      itemBuilder: (context, index) =>
                          _buildTourCard(colors, provider.tours[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(ThemeColors colors, TourProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: colors.danger),
            const SizedBox(height: 16),
            Text(provider.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: provider.load,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ThemeColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.travel_explore, size: 48, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              _hasActiveFilter ? 'По фильтру ничего не нашлось' : 'Туров пока нет',
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (_hasActiveFilter)
              ElevatedButton.icon(
                onPressed: _resetFilter,
                icon: const Icon(Icons.clear),
                label: const Text('Сбросить фильтр'),
              )
            else
              ElevatedButton.icon(
                onPressed: () => context.push('/tours/new'),
                icon: const Icon(Icons.add),
                label: const Text('Создать первый тур'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTourCard(ThemeColors colors, Tour tour) {
    final flag = CountryFlags.getFlag(tour.country);
    final image = tour.displayImageUrl;

    return AppCard(
      onTap: () => context.push('/tours/${tour.tourId}/edit'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 96,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image != null)
                  Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(colors, flag),
                  )
                else
                  _imageFallback(colors, flag),
                if (tour.isPast)
                  Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child: const Text(
                      'завершён',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_moneyFormat.format(tour.basePrice)} \$',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('$flag ', style: const TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          tour.tourName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _line(colors, Icons.place_outlined, '${tour.country}, ${tour.city}'),
                  _line(
                    colors,
                    Icons.calendar_month,
                    '${_dateFormat.format(tour.startDate)} — '
                    '${_dateFormat.format(tour.endDate)} · ${tour.nights} дн.',
                  ),
                  if (tour.hotelName != null)
                    _line(colors, Icons.hotel, tour.hotelName!),
                  if (tour.carrierName != null)
                    _line(colors, Icons.airlines, tour.carrierName!),
                  const Spacer(),
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.edit_outlined,
                            size: 18, color: colors.textSecondary),
                        tooltip: 'Изменить',
                        onPressed: () => context.push('/tours/${tour.tourId}/edit'),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.delete_outline, size: 18, color: colors.danger),
                        tooltip: 'Удалить',
                        onPressed: () => _confirmDelete(tour),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback(ThemeColors colors, String flag) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accentPrimary.withValues(alpha: 0.3),
            colors.accentSecondary.withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Text(flag, style: const TextStyle(fontSize: 34))),
    );
  }

  Widget _line(ThemeColors colors, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 12, color: colors.textSecondary),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeColors colors, double width) {
    final narrow = width < 700;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: narrow ? 1 : 2,
                child: TextField(
                  controller: _countryController,
                  onSubmitted: (_) => _applyFilter(),
                  decoration: const InputDecoration(
                    labelText: 'Страна',
                    isDense: true,
                    prefixIcon: Icon(Icons.public, size: 18),
                  ),
                ),
              ),
              if (!narrow) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _priceMinController,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _applyFilter(),
                    decoration:
                        const InputDecoration(labelText: 'Цена от', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _priceMaxController,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _applyFilter(),
                    decoration:
                        const InputDecoration(labelText: 'Цена до', isDense: true),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.search, color: colors.accentPrimary),
                onPressed: _applyFilter,
                tooltip: 'Применить',
              ),
              IconButton(
                icon: Icon(Icons.clear, color: colors.textSecondary),
                onPressed: _resetFilter,
                tooltip: 'Сбросить',
              ),
            ],
          ),
          if (narrow) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceMinController,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _applyFilter(),
                    decoration:
                        const InputDecoration(labelText: 'Цена от', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _priceMaxController,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _applyFilter(),
                    decoration:
                        const InputDecoration(labelText: 'Цена до', isDense: true),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
