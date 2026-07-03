import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/booking_balance.dart';
import '../../providers/client_auth_provider.dart';
import '../../providers/my_bookings_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_chip.dart';

/// Личный кабинет клиента: список его бронирований, остаток к оплате,
/// реквизиты для перевода и кнопка «Я оплатил».
class ClientBookingsScreen extends StatefulWidget {
  const ClientBookingsScreen({super.key});

  @override
  State<ClientBookingsScreen> createState() => _ClientBookingsScreenState();
}

class _ClientBookingsScreenState extends State<ClientBookingsScreen> {
  final _dateFormat = DateFormat('dd.MM.yyyy');
  final _moneyFormat = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyBookingsProvider>().load();
    });
  }

  Future<void> _confirmPayment(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сообщить об оплате?'),
        content: const Text(
          'Заявка перейдёт в статус «на проверке». Менеджер сверит поступление '
          'и подтвердит оплату вручную — это обычно занимает до одного рабочего дня.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Я оплатил'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await context
        .read<MyBookingsProvider>()
        .setStatus(booking.bookingId!, BookingStatuses.underReview);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Спасибо! Менеджер проверит поступление.')),
    );
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить заявку?'),
        content: Text(
          'Бронирование №${booking.bookingId} на «${booking.tourName ?? 'тур'}» '
          'будет отменено. Вернуть его сможет только менеджер.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false), child: const Text('Оставить')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Отменить заявку',
                style: TextStyle(color: ThemeColors.of(context).danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await context
        .read<MyBookingsProvider>()
        .setStatus(booking.bookingId!, BookingStatuses.cancelled);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final account = context.watch<ClientAuthProvider>().account;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои бронирования'),
        leading: IconButton(
          icon: const Icon(Icons.storefront_outlined),
          tooltip: 'К витрине туров',
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Профиль',
            onPressed: () => context.push('/client/profile'),
          ),
        ],
      ),
      body: Container(
        color: colors.background,
        child: Consumer<MyBookingsProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.bookings.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.error != null && provider.bookings.isEmpty) {
              return _errorState(colors, provider);
            }

            return RefreshIndicator(
              onRefresh: provider.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (account != null) _greeting(colors, account.firstName, provider),
                  const SizedBox(height: 16),
                  if (provider.bookings.isEmpty)
                    _emptyState(colors)
                  else ...[
                    for (final booking in provider.bookings) ...[
                      _BookingCard(
                        booking: booking,
                        balance: provider.balanceOf(booking.bookingId ?? -1),
                        requisites: provider.requisites,
                        dateFormat: _dateFormat,
                        moneyFormat: _moneyFormat,
                        onPaid: () => _confirmPayment(booking),
                        onCancel: () => _cancelBooking(booking),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _greeting(ThemeColors colors, String name, MyBookingsProvider provider) {
    final outstanding = provider.totalOutstanding;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Здравствуйте, $name!',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            provider.bookings.isEmpty
                ? 'У вас пока нет бронирований'
                : 'Бронирований: ${provider.bookings.length}',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          if (outstanding > 0) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 20, color: colors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Всего к оплате',
                            style: TextStyle(color: colors.textSecondary, fontSize: 11.5)),
                        Text(
                          '${_moneyFormat.format(outstanding)} \$',
                          style: TextStyle(
                            color: colors.warning,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.luggage_outlined, size: 64, color: colors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Здесь появятся ваши поездки',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите тур на витрине и отправьте заявку —\nона сразу появится в этом списке.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.travel_explore),
            label: const Text('Подобрать тур'),
          ),
        ],
      ),
    );
  }

  Widget _errorState(ThemeColors colors, MyBookingsProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 52, color: colors.danger),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary),
            ),
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
}

// ===========================================================================

class _BookingCard extends StatefulWidget {
  const _BookingCard({
    required this.booking,
    required this.balance,
    required this.requisites,
    required this.dateFormat,
    required this.moneyFormat,
    required this.onPaid,
    required this.onCancel,
  });

  final Booking booking;
  final BookingBalance? balance;
  final PaymentRequisites? requisites;
  final DateFormat dateFormat;
  final NumberFormat moneyFormat;
  final VoidCallback onPaid;
  final VoidCallback onCancel;

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _showRequisites = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final booking = widget.booking;
    final balance = widget.balance;
    final needsPayment = balance != null && !balance.isPaid && !booking.isCancelled;

    return AppCard(
      padding: const EdgeInsets.all(18),
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
                      booking.tourName ?? 'Тур №${booking.tourId}',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (booking.destination != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        booking.destination!,
                        style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusChip(status: booking.status),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (booking.tourStartDate != null)
                _fact(colors, Icons.calendar_month,
                    '${widget.dateFormat.format(booking.tourStartDate!)}'
                    '${booking.tourEndDate != null ? ' — ${widget.dateFormat.format(booking.tourEndDate!)}' : ''}'),
              _fact(colors, Icons.group_outlined, '${booking.peopleCount} чел.'),
              _fact(colors, Icons.confirmation_number_outlined, '№${booking.bookingId}'),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: 14),
          if (balance != null) _buildBalance(colors, balance) else _buildTotalOnly(colors),
          if (needsPayment) ...[
            const SizedBox(height: 14),
            _buildActions(colors, booking),
            if (_showRequisites && widget.requisites != null) ...[
              const SizedBox(height: 12),
              _buildRequisites(colors, widget.requisites!, booking),
            ],
          ] else if (balance != null && balance.isPaid && !booking.isCancelled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.verified, size: 18, color: colors.success),
                const SizedBox(width: 8),
                Text('Оплачено полностью',
                    style: TextStyle(color: colors.success, fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalOnly(ThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Сумма', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(
          '${widget.moneyFormat.format(widget.booking.totalCost ?? 0)} \$',
          style: TextStyle(
            color: colors.accentSecondary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBalance(ThemeColors colors, BookingBalance balance) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Оплачено ${widget.moneyFormat.format(balance.paidAmount)} \$ '
                'из ${widget.moneyFormat.format(balance.totalCost)} \$',
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
            Text(
              balance.isPaid
                  ? 'готово'
                  : 'осталось ${widget.moneyFormat.format(balance.remaining)} \$',
              style: TextStyle(
                color: balance.isPaid ? colors.success : colors.warning,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: balance.progress,
            minHeight: 6,
            backgroundColor: colors.surfaceGlassStrong,
            valueColor: AlwaysStoppedAnimation(
              balance.isPaid ? colors.success : colors.accentSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(ThemeColors colors, Booking booking) {
    final awaitingReview = booking.status == BookingStatuses.underReview;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _showRequisites = !_showRequisites),
            icon: Icon(_showRequisites ? Icons.expand_less : Icons.credit_card, size: 18),
            label: Text(_showRequisites ? 'Скрыть' : 'Реквизиты'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              side: BorderSide(color: colors.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            // Повторно жать «Я оплатил» на брони, уже отправленной на проверку,
            // незачем — статус от этого не изменится.
            onPressed: awaitingReview ? null : widget.onPaid,
            icon: Icon(awaitingReview ? Icons.hourglass_top : Icons.done_all, size: 18),
            label: Text(awaitingReview ? 'На проверке' : 'Я оплатил'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Отменить заявку',
          icon: Icon(Icons.close, size: 20, color: colors.textSecondary),
          onPressed: widget.onCancel,
        ),
      ],
    );
  }

  Widget _buildRequisites(
      ThemeColors colors, PaymentRequisites requisites, Booking booking) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceGlassStrong,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Реквизиты для перевода',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _requisiteRow(colors, 'Получатель', requisites.recipient),
          _requisiteRow(colors, 'Банк', requisites.bankName),
          _requisiteRow(colors, 'Карта / счёт', requisites.cardNumber, copyable: true),
          _requisiteRow(colors, 'Комментарий', 'Бронирование №${booking.bookingId}',
              copyable: true),
          const SizedBox(height: 8),
          Text(
            requisites.comment,
            style: TextStyle(color: colors.textSecondary, fontSize: 11.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _requisiteRow(ThemeColors colors, String label, String value,
      {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (copyable)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Скопировано')),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.copy, size: 15, color: colors.accentPrimary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fact(ThemeColors colors, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.textSecondary),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
      ],
    );
  }
}
