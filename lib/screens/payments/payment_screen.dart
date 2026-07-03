import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/booking_balance.dart';
import '../../models/payment.dart';
import '../../providers/booking_provider.dart';
import '../../providers/payment_provider.dart';
import '../../theme/app_theme.dart';

/// Платежи по бронированию: остаток к оплате + история платежей.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _dateFormat = DateFormat('dd.MM.yyyy');
  final _moneyFormat = NumberFormat('#,##0.00');
  final _amountController = TextEditingController();
  String _method = 'карта';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().load(bookingId: widget.bookingId);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _addPayment() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректную сумму')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final error = await context.read<PaymentProvider>().add(
          Payment(bookingId: widget.bookingId, amount: amount, paymentMethod: _method),
        );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    _amountController.clear();
    await _maybeOfferPaidStatus();
  }

  /// Как только долг закрыт — предлагаем сразу перевести бронь в «оплачен»,
  /// чтобы сотруднику не пришлось искать её в списке отдельным действием.
  Future<void> _maybeOfferPaidStatus() async {
    if (!mounted) return;
    final balance = context.read<PaymentProvider>().balance;
    if (balance == null || !balance.isPaid) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Бронирование оплачено полностью'),
        content: const Text('Перевести его в статус «оплачен»?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Позже')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Перевести'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await context
        .read<BookingProvider>()
        .setStatus(widget.bookingId, BookingStatuses.paid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Статус обновлён')),
    );
  }

  Future<void> _deletePayment(Payment payment) async {
    final colors = ThemeColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить платёж?'),
        content: Text('${_moneyFormat.format(payment.amount)} \$ будут списаны из истории.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Удалить', style: TextStyle(color: colors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await context
        .read<PaymentProvider>()
        .remove(payment.paymentId!, bookingId: widget.bookingId);
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Оплата брони №${widget.bookingId}')),
      body: Container(
        color: colors.background,
        child: Consumer<PaymentProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.payments.isEmpty && provider.balance == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (provider.balance != null) _buildBalanceCard(colors, provider.balance!),
                const SizedBox(height: 16),
                _buildNewPaymentCard(colors, provider.balance),
                const SizedBox(height: 20),
                Text(
                  'ИСТОРИЯ ПЛАТЕЖЕЙ',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                if (provider.payments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 44, color: colors.textSecondary),
                        const SizedBox(height: 10),
                        Text('Платежей пока нет',
                            style: TextStyle(color: colors.textSecondary)),
                      ],
                    ),
                  )
                else
                  for (final payment in provider.payments) ...[
                    _buildPaymentTile(colors, payment),
                    const SizedBox(height: 10),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ThemeColors colors, BookingBalance balance) {
    final accent = balance.isPaid ? colors.success : colors.warning;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                balance.isPaid ? Icons.verified_outlined : Icons.pending_actions,
                color: accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  balance.isPaid ? 'Оплачено полностью' : 'Остаток к оплате',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_moneyFormat.format(balance.remaining)} \$',
            style: TextStyle(color: accent, fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: balance.progress,
              minHeight: 7,
              backgroundColor: colors.surfaceGlassStrong,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Оплачено ${_moneyFormat.format(balance.paidAmount)} \$',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
              Text('Сумма ${_moneyFormat.format(balance.totalCost)} \$',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewPaymentCard(ThemeColors colors, BookingBalance? balance) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Новый платёж',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Сумма, \$',
              prefixIcon: const Icon(Icons.attach_money),
              // Быстрая подстановка остатка — самый частый сценарий: клиент
              // гасит долг целиком.
              suffixIcon: balance != null && balance.remaining > 0
                  ? TextButton(
                      onPressed: () => setState(() =>
                          _amountController.text = balance.remaining.toStringAsFixed(2)),
                      child: const Text('Весь остаток'),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: const InputDecoration(
              labelText: 'Способ оплаты',
              prefixIcon: Icon(Icons.credit_card),
            ),
            items: const [
              DropdownMenuItem(value: 'карта', child: Text('Карта')),
              DropdownMenuItem(value: 'наличные', child: Text('Наличные')),
              DropdownMenuItem(value: 'перевод', child: Text('Банковский перевод')),
            ],
            onChanged: (value) => setState(() => _method = value ?? 'карта'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _addPayment,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add),
              label: const Text('Добавить платёж'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(ThemeColors colors, Payment payment) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.success.withValues(alpha: 0.15),
            ),
            child: Icon(Icons.check, size: 16, color: colors.success),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_moneyFormat.format(payment.amount)} \$',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  [
                    payment.paymentMethod,
                    if (payment.paymentDate != null)
                      _dateFormat.format(payment.paymentDate!),
                  ].whereType<String>().join(' · '),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colors.danger),
            tooltip: 'Удалить платёж',
            onPressed: () => _deletePayment(payment),
          ),
        ],
      ),
    );
  }
}
