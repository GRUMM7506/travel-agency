import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/tour.dart';
import '../../providers/booking_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/tour_provider.dart';
import '../../theme/app_theme.dart';

/// Форма бронирования. [bookingId] == null — создание, иначе редактирование.
class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key, this.bookingId});

  final int? bookingId;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _peopleCountController = TextEditingController(text: '1');
  final _discountController = TextEditingController(text: '0');
  final _commissionController = TextEditingController(text: '10');
  final _notesController = TextEditingController();
  final _moneyFormat = NumberFormat('#,##0.00');

  int? _clientId;
  int? _tourId;
  String _status = BookingStatuses.confirmed;
  bool _isSaving = false;
  bool _isLoading = false;

  bool get _isEdit => widget.bookingId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Справочники нужны в обоих режимах — без них дропдауны пустые.
      await Future.wait([
        context.read<ClientProvider>().load(),
        context.read<TourProvider>().load(),
      ]);
      if (_isEdit) await _loadBooking();
    });
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    final provider = context.read<BookingProvider>();
    // Список уже загружен на предыдущем экране — ищем в нём, лишний
    // запрос за одной записью не нужен.
    Booking? booking;
    for (final b in provider.bookings) {
      if (b.bookingId == widget.bookingId) {
        booking = b;
        break;
      }
    }
    booking ??= await _fetchSingle();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (booking == null) return;
      _clientId = booking.clientId;
      _tourId = booking.tourId;
      _peopleCountController.text = booking.peopleCount.toString();
      _discountController.text = _trimZeros(booking.discountPercent);
      _commissionController.text = _trimZeros(booking.commissionPercent);
      _notesController.text = booking.notes ?? '';
      _status = booking.status;
    });
  }

  Future<Booking?> _fetchSingle() async {
    try {
      await context.read<BookingProvider>().load();
      if (!mounted) return null;
      for (final b in context.read<BookingProvider>().bookings) {
        if (b.bookingId == widget.bookingId) return b;
      }
    } catch (_) {
      // Ошибку покажет сам список; форма просто останется пустой.
    }
    return null;
  }

  /// 10.00 -> "10", 7.50 -> "7.5" — в поле ввода лишние нули только мешают.
  String _trimZeros(double value) {
    final text = value.toStringAsFixed(2);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  void dispose() {
    _peopleCountController.dispose();
    _discountController.dispose();
    _commissionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _parse(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;

  double? _estimateTotal(Tour? tour) {
    if (tour == null) return null;
    final people = int.tryParse(_peopleCountController.text) ?? 0;
    return tour.basePrice * people * (1 - _parse(_discountController) / 100);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final booking = Booking(
      bookingId: widget.bookingId,
      clientId: _clientId!,
      tourId: _tourId!,
      peopleCount: int.parse(_peopleCountController.text),
      discountPercent: _parse(_discountController),
      commissionPercent: _parse(_commissionController),
      status: _status,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    final provider = context.read<BookingProvider>();
    String? errorText;
    if (_isEdit) {
      try {
        await provider.edit(widget.bookingId!, booking);
      } catch (e) {
        errorText = e.toString();
      }
    } else {
      final created = await provider.add(booking);
      if (created == null) errorText = provider.error ?? 'Не удалось создать бронирование';
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (errorText == null) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Бронирование №${widget.bookingId}' : 'Новое бронирование'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Consumer<ClientProvider>(
                      builder: (context, provider, _) => DropdownButtonFormField<int>(
                        initialValue: _clientId,
                        decoration: const InputDecoration(
                          labelText: 'Клиент',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        isExpanded: true,
                        items: provider.clients
                            .map((c) =>
                                DropdownMenuItem(value: c.clientId, child: Text(c.fullName)))
                            .toList(),
                        onChanged: (value) => setState(() => _clientId = value),
                        validator: (v) => v == null ? 'Выберите клиента' : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<TourProvider>(
                      builder: (context, provider, _) => DropdownButtonFormField<int>(
                        initialValue: _tourId,
                        decoration: const InputDecoration(
                          labelText: 'Тур',
                          prefixIcon: Icon(Icons.flight_takeoff),
                        ),
                        isExpanded: true,
                        items: provider.tours
                            .map((t) => DropdownMenuItem(
                                  value: t.tourId,
                                  child: Text(
                                    '${t.tourName} · ${_moneyFormat.format(t.basePrice)} \$',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _tourId = value),
                        validator: (v) => v == null ? 'Выберите тур' : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _peopleCountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Человек'),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n <= 0) return 'Число > 0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _discountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Скидка, %'),
                            onChanged: (_) => setState(() {}),
                            validator: (v) => _percentError(v, max: 99),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _commissionController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Комиссия, %'),
                            onChanged: (_) => setState(() {}),
                            validator: (v) => _percentError(v, max: 99),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Статус',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      isExpanded: true,
                      items: BookingStatuses.all
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _status = value ?? BookingStatuses.confirmed),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Примечания',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Consumer<TourProvider>(
                      builder: (context, provider, _) {
                        Tour? tour;
                        for (final t in provider.tours) {
                          if (t.tourId == _tourId) {
                            tour = t;
                            break;
                          }
                        }
                        final estimate = _estimateTotal(tour);
                        final commission =
                            estimate == null ? null : estimate * _parse(_commissionController) / 100;
                        return AppCard(
                          child: Column(
                            children: [
                              _summaryRow(
                                colors,
                                'Предварительная сумма',
                                estimate != null
                                    ? '${_moneyFormat.format(estimate)} \$'
                                    : '—',
                                colors.accentSecondary,
                                big: true,
                              ),
                              const SizedBox(height: 8),
                              _summaryRow(
                                colors,
                                'Комиссия агентства',
                                commission != null
                                    ? '${_moneyFormat.format(commission)} \$'
                                    : '—',
                                colors.textSecondary,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Итоговая сумма пересчитывается и сохраняется на сервере.',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_isEdit ? 'Сохранить' : 'Оформить бронирование'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String? _percentError(String? value, {required double max}) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return 'Число';
    if (parsed < 0 || parsed > max) return '0—${max.toStringAsFixed(0)}';
    return null;
  }

  Widget _summaryRow(ThemeColors colors, String label, String value, Color valueColor,
      {bool big = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: big ? 14 : 12)),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: big ? FontWeight.bold : FontWeight.w600,
            fontSize: big ? 18 : 13,
          ),
        ),
      ],
    );
  }
}
