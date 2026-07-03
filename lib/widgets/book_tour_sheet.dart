import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/tour.dart';
import '../providers/client_auth_provider.dart';
import '../providers/my_bookings_provider.dart';
import '../theme/app_theme.dart';

/// Диалог «Забронировать тур» — общий для витрины и карточки тура.
///
/// Незалогиненного клиента отправляет на вход, а не показывает форму:
/// POST /bookings/self всё равно вернёт 401 без токена.
Future<void> showBookTourSheet(BuildContext context, Tour tour) async {
  final clientAuth = context.read<ClientAuthProvider>();

  if (!clientAuth.isAuthenticated) {
    final goToLogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Нужен аккаунт'),
        content: const Text(
          'Чтобы забронировать тур, войдите в личный кабинет или '
          'зарегистрируйтесь — это займёт минуту.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Позже')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Войти'),
          ),
        ],
      ),
    );
    if (goToLogin == true && context.mounted) context.push('/client/login');
    return;
  }

  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BookTourSheet(tour: tour),
  );
}

class _BookTourSheet extends StatefulWidget {
  const _BookTourSheet({required this.tour});

  final Tour tour;

  @override
  State<_BookTourSheet> createState() => _BookTourSheetState();
}

class _BookTourSheetState extends State<_BookTourSheet> {
  final _notesController = TextEditingController();
  final _moneyFormat = NumberFormat('#,##0.00');
  int _people = 1;
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Messenger и router берём ДО pop: после закрытия шита этот State
    // отсоединён от дерева, и обращаться к его context уже нельзя.
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    setState(() => _isSaving = true);
    final error = await context.read<MyBookingsProvider>().book(
          tourId: widget.tour.tourId!,
          peopleCount: _people,
          notes: _notesController.text.trim(),
        );
    if (!mounted) return;

    setState(() => _isSaving = false);
    Navigator.pop(context);

    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Заявка отправлена — она уже в вашем кабинете')),
    );
    router.push('/client/bookings');
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final tour = widget.tour;
    // Предварительная сумма. Итог всё равно считает бэкенд — здесь только
    // чтобы человек видел порядок цифры до подтверждения.
    final estimate = tour.basePrice * _people;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Бронирование тура',
              style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 4),
            Text(
              tour.tourName,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Туристов', style: TextStyle(color: colors.textPrimary, fontSize: 15)),
                const Spacer(),
                _stepperButton(
                  colors,
                  Icons.remove,
                  _people > 1 ? () => setState(() => _people--) : null,
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    '$_people',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _stepperButton(
                  colors,
                  Icons.add,
                  _people < 20 ? () => setState(() => _people++) : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Пожелания (необязательно)',
                hintText: 'Например: номер с видом на море',
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.accentPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('К оплате примерно',
                          style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                      Text(
                        '${_moneyFormat.format(estimate)} \$',
                        style: TextStyle(
                          color: colors.accentSecondary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_moneyFormat.format(tour.basePrice)} \$\n× $_people',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Точную сумму подтвердит менеджер. Оплата — после подтверждения заявки.',
              style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isSaving ? 'Отправляем...' : 'Отправить заявку'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepperButton(ThemeColors colors, IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? colors.surfaceGlassStrong : colors.surfaceGlass,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? colors.textPrimary : colors.textSecondary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
