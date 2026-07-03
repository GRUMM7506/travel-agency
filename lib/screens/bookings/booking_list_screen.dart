import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_chip.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  final _dateFormat = DateFormat('dd.MM.yyyy');
  final _moneyFormat = NumberFormat('#,##0.00');
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(Booking booking) async {
    final colors = ThemeColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить бронирование №${booking.bookingId}?'),
        content: const Text(
          'Действие необратимо. Связанные платежи также станут недоступны.\n\n'
          'Если клиент просто передумал — лучше поставить статус «отменён», '
          'тогда бронь останется в отчётах.',
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
    if (confirmed == true && mounted) {
      await context.read<BookingProvider>().remove(booking.bookingId!);
    }
  }

  Future<void> _changeStatus(Booking booking) async {
    final colors = ThemeColors.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Статус брони №${booking.bookingId}',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            for (final status in BookingStatuses.all)
              ListTile(
                leading: Icon(
                  BookingStatusStyle.icon(status),
                  color: BookingStatusStyle.color(colors, status),
                ),
                title: Text(status, style: TextStyle(color: colors.textPrimary)),
                trailing: status == booking.status
                    ? Icon(Icons.check, color: colors.accentPrimary)
                    : null,
                onTap: () => Navigator.pop(context, status),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected == null || selected == booking.status || !mounted) return;
    final error = await context.read<BookingProvider>().setStatus(booking.bookingId!, selected);
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Бронирования')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/bookings/new'),
        icon: const Icon(Icons.add),
        label: const Text('Новое'),
      ),
      body: Container(
        color: colors.background,
        child: Consumer<BookingProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                _buildSearch(colors, provider),
                _buildStatusFilter(colors, provider),
                Expanded(child: _buildList(colors, provider)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearch(ThemeColors colors, BookingProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: provider.setQuery,
        decoration: InputDecoration(
          hintText: 'Клиент, тур или номер брони',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    provider.setQuery('');
                  },
                ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildStatusFilter(ThemeColors colors, BookingProvider provider) {
    final counts = provider.statusCounts;
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _filterChip(colors, 'Все', provider.statusFilter == null,
              () => provider.setStatusFilter(null)),
          for (final status in BookingStatuses.all) ...[
            const SizedBox(width: 8),
            _filterChip(
              colors,
              // Счётчик показываем только когда фильтр «Все»: при активном
              // фильтре бэкенд вернул одну группу, и цифры у остальных были бы 0.
              provider.statusFilter == null && counts[status] != null
                  ? '$status · ${counts[status]}'
                  : status,
              provider.statusFilter == status,
              () => provider.setStatusFilter(status),
              color: BookingStatusStyle.color(colors, status),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(
    ThemeColors colors,
    String label,
    bool active,
    VoidCallback onTap, {
    Color? color,
  }) {
    final accent = color ?? colors.accentPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? accent : colors.surfaceGlass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? accent : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : colors.textSecondary,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Widget _buildList(ThemeColors colors, BookingProvider provider) {
    if (provider.isLoading && provider.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.bookings.isEmpty) {
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

    final bookings = provider.visibleBookings;
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: colors.textSecondary),
              const SizedBox(height: 12),
              Text(
                provider.query.isNotEmpty
                    ? 'Ничего не найдено по запросу'
                    : provider.statusFilter != null
                        ? 'Нет броней в статусе «${provider.statusFilter}»'
                        : 'Бронирований пока нет',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _bookingCard(colors, bookings[index]),
      ),
    );
  }

  Widget _bookingCard(ThemeColors colors, Booking booking) {
    return AppCard(
      onTap: () => context.push('/bookings/${booking.bookingId}/payments'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.clientName ?? 'Клиент #${booking.clientId}',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.tourName ?? 'Тур #${booking.tourId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _changeStatus(booking),
                child: StatusChip(status: booking.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _fact(colors, Icons.tag, '№${booking.bookingId}'),
              _fact(colors, Icons.group_outlined, '${booking.peopleCount} чел.'),
              if (booking.destination != null)
                _fact(colors, Icons.place_outlined, booking.destination!),
              if (booking.bookingDate != null)
                _fact(colors, Icons.event_note_outlined,
                    _dateFormat.format(booking.bookingDate!)),
              if (booking.discountPercent > 0)
                _fact(colors, Icons.local_offer_outlined,
                    'скидка ${booking.discountPercent.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_moneyFormat.format(booking.totalCost ?? 0)} \$',
                    style: TextStyle(
                      color: colors.accentSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    'комиссия ${_moneyFormat.format(booking.commissionAmount)} \$',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.payments_outlined, color: colors.success),
                tooltip: 'Платежи',
                onPressed: () => context.push('/bookings/${booking.bookingId}/payments'),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: colors.textSecondary),
                tooltip: 'Изменить',
                onPressed: () => context.push('/bookings/${booking.bookingId}/edit'),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: colors.danger),
                tooltip: 'Удалить',
                onPressed: () => _confirmDelete(booking),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fact(ThemeColors colors, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
