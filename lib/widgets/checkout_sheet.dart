import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../models/booking_balance.dart';
import '../providers/my_bookings_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Оплата бронирования картой.
///
/// ВАЖНО: настоящего эквайринга в проекте нет. Номер карты, срок и CVC
/// остаются в этой форме — они никуда не отправляются и нигде не сохраняются,
/// а «проведение платежа» имитируется задержкой. На бэкенд уходят только
/// последние 4 цифры (POST /bookings/{id}/pay), и уже там создаётся реальная
/// запись в payments на весь остаток и бронь переводится в «оплачен».
///
/// Возвращает [CheckoutResult] при успешной оплате и null, если закрыли.
Future<CheckoutResult?> showCheckoutSheet(
  BuildContext context, {
  required Booking booking,
  required double amount,
}) {
  return showModalBottomSheet<CheckoutResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => _CheckoutSheet(booking: booking, amount: amount),
  );
}

enum _Phase { form, processing, done }

class _CheckoutSheet extends StatefulWidget {
  const _CheckoutSheet({required this.booking, required this.amount});

  final Booking booking;
  final double amount;

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _moneyFormat = NumberFormat('#,##0.00');

  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _holderController = TextEditingController();

  _Phase _phase = _Phase.form;
  String? _error;
  CheckoutResult? _result;

  String get _digits => _numberController.text.replaceAll(RegExp(r'\D'), '');

  @override
  void initState() {
    super.initState();
    // Превью карты перерисовывается по мере ввода.
    _numberController.addListener(_refresh);
    _expiryController.addListener(_refresh);
    _holderController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _numberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _phase = _Phase.processing;
      _error = null;
    });

    // Имитация запроса к банку: без этой паузы «оплата» выглядела бы как
    // обычная кнопка, а весь смысл экрана — показать привычный проход.
    await Future.delayed(const Duration(milliseconds: 1700));
    if (!mounted) return;

    try {
      final result = await context.read<MyBookingsProvider>().pay(
            widget.booking.bookingId!,
            cardLast4: _digits.substring(_digits.length - 4),
            cardholder: _holderController.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _phase = _Phase.done;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.instance.parseError(e);
        _phase = _Phase.form;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                alignment: Alignment.topCenter,
                child: switch (_phase) {
                  _Phase.form => _buildForm(colors),
                  _Phase.processing => _buildProcessing(colors),
                  _Phase.done => _buildDone(colors),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Фаза 1: форма -------------------------------------------------------

  Widget _buildForm(ThemeColors colors) {
    return Form(
      key: _formKey,
      // Иначе ошибка «номер карты неверный» висит под полем до следующего
      // нажатия «Оплатить», хотя пользователь уже исправил цифру.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _grabber(colors),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Оплата картой',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Бронирование №${widget.booking.bookingId}'
                      '${widget.booking.tourName != null ? ' · ${widget.booking.tourName}' : ''}',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: colors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _cardPreview(colors),
          const SizedBox(height: 18),
          _demoBanner(colors),
          const SizedBox(height: 18),
          TextFormField(
            controller: _numberController,
            keyboardType: TextInputType.number,
            autofillHints: const [],
            inputFormatters: [_CardNumberFormatter()],
            decoration: const InputDecoration(
              labelText: 'Номер карты',
              hintText: '4111 1111 1111 1111',
              prefixIcon: Icon(Icons.credit_card),
            ),
            validator: (_) {
              if (_digits.length != 16) return 'Введите 16 цифр';
              if (!_luhnValid(_digits)) return 'Номер карты неверный';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_ExpiryFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Срок',
                    hintText: 'ММ/ГГ',
                  ),
                  validator: _validateExpiry,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cvcController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 3,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'CVC',
                    hintText: '123',
                    counterText: '',
                  ),
                  validator: (value) =>
                      (value ?? '').length == 3 ? null : 'Три цифры с оборота',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _holderController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Zа-яА-Я \-]')),
              LengthLimitingTextInputFormatter(40),
            ],
            decoration: const InputDecoration(
              labelText: 'Держатель карты',
              hintText: 'IVAN IVANOV',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) =>
                (value ?? '').trim().length < 3 ? 'Как на карте' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.danger.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: colors.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_error!,
                        style: TextStyle(color: colors.danger, fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pay,
              icon: const Icon(Icons.lock_outline, size: 18),
              label: Text('Оплатить ${_moneyFormat.format(widget.amount)} \$'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Плашка обязательна: без неё форма неотличима от настоящей оплаты,
  /// а вводить сюда данные реальной карты никому не нужно.
  Widget _demoBanner(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, size: 18, color: colors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Демонстрационный режим. Платёж имитируется, деньги не списываются — '
              'данные настоящей карты вводить не нужно. Тестовый номер: 4111 1111 1111 1111.',
              style: TextStyle(color: colors.textSecondary, fontSize: 11.5, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  /// Превью карты — заполняется по мере ввода, чисто визуальная часть.
  Widget _cardPreview(ThemeColors colors) {
    final digits = _digits;
    final groups = List.generate(4, (i) {
      final part = digits.substring(
        (i * 4).clamp(0, digits.length),
        ((i + 1) * 4).clamp(0, digits.length),
      );
      return part.padRight(4, '•');
    });

    return Container(
      height: 172,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.accentPrimary, colors.accentSecondary],
        ),
        boxShadow: colors.cardShadow(raised: true),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Text(
                _brandOf(digits),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            groups.join('  '),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _holderController.text.isEmpty
                      ? 'ДЕРЖАТЕЛЬ КАРТЫ'
                      : _holderController.text.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                _expiryController.text.isEmpty ? 'ММ/ГГ' : _expiryController.text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Фаза 2: «связь с банком» --------------------------------------------

  Widget _buildProcessing(ThemeColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _grabber(colors),
        const SizedBox(height: 40),
        SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(strokeWidth: 3, color: colors.accentPrimary),
        ),
        const SizedBox(height: 26),
        Text(
          'Проводим платёж',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Подтверждение банка · карта •••• '
          '${_digits.length >= 4 ? _digits.substring(_digits.length - 4) : '••••'}',
          style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
        ),
        const SizedBox(height: 46),
      ],
    );
  }

  // --- Фаза 3: успех -------------------------------------------------------

  Widget _buildDone(ThemeColors colors) {
    final result = _result!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _grabber(colors),
        const SizedBox(height: 28),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, size: 42, color: colors.success),
        ),
        const SizedBox(height: 20),
        Text(
          'Платёж прошёл',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_moneyFormat.format(result.amount)} \$ · бронирование №${widget.booking.bookingId}',
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceGlassStrong,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _receiptRow(colors, 'Способ', result.paymentMethod ?? 'карта'),
              _receiptRow(colors, 'Статус брони', result.bookingStatus),
              _receiptRow(
                colors,
                'Остаток',
                '${_moneyFormat.format(result.balance.remaining)} \$',
                highlight: result.balance.isPaid,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, result),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text('Готово'),
          ),
        ),
      ],
    );
  }

  Widget _receiptRow(ThemeColors colors, String label, String value,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
          Text(
            value,
            style: TextStyle(
              color: highlight ? colors.success : colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _grabber(ThemeColors colors) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: colors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  String? _validateExpiry(String? value) {
    final text = value ?? '';
    if (text.length != 5) return 'ММ/ГГ';
    final month = int.tryParse(text.substring(0, 2));
    final year = int.tryParse(text.substring(3));
    if (month == null || year == null || month < 1 || month > 12) {
      return 'Неверный срок';
    }
    // Карта действительна до конца указанного месяца.
    final expiry = DateTime(2000 + year, month + 1, 0);
    if (expiry.isBefore(DateTime.now())) return 'Срок истёк';
    return null;
  }
}

/// Проверка номера по алгоритму Луна — та же, что делают настоящие формы
/// оплаты: отсеивает опечатки ещё до обращения к серверу.
bool _luhnValid(String digits) {
  if (digits.length < 13) return false;
  var sum = 0;
  var alternate = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var n = int.parse(digits[i]);
    if (alternate) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}

String _brandOf(String digits) {
  if (digits.isEmpty) return 'CARD';
  if (digits.startsWith('4')) return 'VISA';
  if (RegExp(r'^5[1-5]').hasMatch(digits)) return 'MASTERCARD';
  if (digits.startsWith('2')) return 'МИР';
  return 'CARD';
}

/// Разбивает номер на группы по 4 цифры, как в банковских приложениях.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 16 ? digits.substring(0, 16) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(limited[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Подставляет «/» после месяца: пользователь набирает только цифры.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    final text = limited.length <= 2
        ? limited
        : '${limited.substring(0, 2)}/${limited.substring(2)}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
