import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../theme/app_theme.dart';

/// Цвет и иконка статуса брони — одни на всё приложение, чтобы «оплачен»
/// выглядел одинаково и в админке, и в личном кабинете клиента.
class BookingStatusStyle {
  const BookingStatusStyle._();

  static Color color(ThemeColors colors, String status) {
    switch (status) {
      case BookingStatuses.paid:
      case BookingStatuses.completed:
        return colors.success;
      case BookingStatuses.cancelled:
        return colors.danger;
      case BookingStatuses.underReview:
        return colors.accentSecondary;
      case BookingStatuses.confirmed:
        return colors.accentPrimary;
      default: // заявка, ожидает оплаты
        return colors.warning;
    }
  }

  static IconData icon(String status) {
    switch (status) {
      case BookingStatuses.paid:
        return Icons.verified_outlined;
      case BookingStatuses.completed:
        return Icons.flag_outlined;
      case BookingStatuses.cancelled:
        return Icons.cancel_outlined;
      case BookingStatuses.underReview:
        return Icons.hourglass_top;
      case BookingStatuses.confirmed:
        return Icons.assignment_turned_in_outlined;
      case BookingStatuses.awaitingPayment:
        return Icons.payments_outlined;
      default:
        return Icons.edit_note;
    }
  }
}

/// Статус брони «таблеткой». Тонкая обёртка над AppPill — вся геометрия
/// (скругление, отступы, размеры) живёт там, здесь только выбор цвета и иконки.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return AppPill(
      label: status,
      color: BookingStatusStyle.color(colors, status),
      icon: BookingStatusStyle.icon(status),
      compact: compact,
    );
  }
}
