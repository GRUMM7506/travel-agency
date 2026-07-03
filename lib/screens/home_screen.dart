import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../models/report.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/status_chip.dart';

/// Главный экран CRM: живая сводка по агентству + навигация по разделам.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _moneyFormat = NumberFormat('#,##0');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  int _crossAxisCount(double width) {
    if (width < 600) return 2;
    if (width < 1200) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final auth = context.watch<AuthProvider>();
    final width = MediaQuery.of(context).size.width;

    // «Сотрудники» показываем только админу — менеджеру раздел всё равно
    // вернёт 403 с бэкенда, дразнить его карточкой незачем.
    final sections = <_NavSection>[
      const _NavSection('Туры', Icons.flight_takeoff, '/tours', AppColors.accentPrimary),
      const _NavSection('Клиенты', Icons.people_outline, '/clients', AppColors.accentSecondary),
      const _NavSection('Бронирования', Icons.event_available, '/bookings', AppColors.success),
      const _NavSection('Отчёты', Icons.bar_chart, '/reports', AppColors.warning),
      const _NavSection('Гостиницы', Icons.hotel, '/hotels', AppColors.accentPrimary),
      const _NavSection('Перевозчики', Icons.directions_bus, '/carriers', AppColors.accentSecondary),
      if (auth.isAdmin)
        const _NavSection('Сотрудники', Icons.badge_outlined, '/staff', AppColors.danger),
      const _NavSection('Настройки', Icons.settings_outlined, '/settings', AppColors.textSecondary),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM турагентства'),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'Витрина туров',
            onPressed: () => context.go('/'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить сводку',
            onPressed: () => context.read<DashboardProvider>().load(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: _userChip(colors, auth),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.background, colors.backgroundAlt],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Consumer<DashboardProvider>(
            builder: (context, dashboard, _) {
              return RefreshIndicator(
                onRefresh: dashboard.load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _greeting(colors, auth),
                    const SizedBox(height: 16),
                    if (dashboard.error != null)
                      _errorBanner(colors, dashboard)
                    else
                      _statsSection(colors, dashboard, width),
                    const SizedBox(height: 24),
                    const SectionLabel('Разделы'),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _crossAxisCount(width),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 132,
                      ),
                      itemCount: sections.length,
                      itemBuilder: (context, index) {
                        final section = sections[index];
                        return AppCard(
                          onTap: () => context.push(section.route),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: section.color.withValues(alpha: 0.15),
                                ),
                                child: Icon(section.icon, size: 28, color: section.color),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                section.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------

  Widget _userChip(ThemeColors colors, AuthProvider auth) {
    final staff = auth.currentStaff;
    if (staff == null) return const SizedBox.shrink();
    return Tooltip(
      message: '${staff.fullName} · ${staff.roleLabel}',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/settings'),
        child: CircleAvatar(
          radius: 17,
          backgroundColor: colors.accentPrimary.withValues(alpha: 0.2),
          child: Text(
            staff.initials,
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _greeting(ThemeColors colors, AuthProvider auth) {
    final name = auth.currentStaff?.fullName.split(' ').first ?? '';
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accentPrimary.withValues(alpha: 0.18),
            ),
            child: Icon(Icons.flight_class, size: 32, color: colors.accentPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Панель управления' : 'Добрый день, $name',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  auth.currentStaff?.roleLabel ?? 'Сводка по агентству',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(ThemeColors colors, DashboardProvider dashboard) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: colors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              dashboard.error!,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
          TextButton(onPressed: dashboard.load, child: const Text('Повторить')),
        ],
      ),
    );
  }

  Widget _statsSection(ThemeColors colors, DashboardProvider dashboard, double width) {
    final stats = dashboard.stats;
    if (stats == null) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final tiles = <Widget>[
      _StatTile(
        icon: Icons.tour,
        label: 'Активных туров',
        value: '${stats.activeToursCount}',
        hint: 'всего ${stats.toursCount}',
        color: colors.accentPrimary,
      ),
      _StatTile(
        icon: Icons.people,
        label: 'Клиентов',
        value: '${stats.clientsCount}',
        color: colors.accentSecondary,
      ),
      _StatTile(
        icon: Icons.event_available,
        label: 'Бронирований',
        value: '${stats.bookingsCount}',
        color: colors.success,
      ),
      _StatTile(
        icon: Icons.payments_outlined,
        label: 'Комиссия',
        value: '${_moneyFormat.format(stats.totalCommission)} \$',
        hint: 'оборот ${_moneyFormat.format(stats.totalRevenue)} \$',
        color: colors.warning,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: width < 700 ? 2 : 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          // Фиксированная высота, а не aspectRatio: на широком экране колонка
          // растягивалась до 290px и плитка раздувалась вдвое выше содержимого.
          // 124 — минимум, при котором помещается строка-подсказка (hint).
          mainAxisExtent: 124,
          children: tiles,
        ),
        if (stats.outstandingAmount > 0) ...[
          const SizedBox(height: 12),
          _outstandingCard(colors, stats),
        ],
        if (stats.bookingsByStatus.isNotEmpty) ...[
          const SizedBox(height: 12),
          _statusBreakdown(colors, stats),
        ],
      ],
    );
  }

  Widget _outstandingCard(ThemeColors colors, DashboardStats stats) {
    final collected = stats.totalRevenue > 0
        ? (stats.paidAmount / stats.totalRevenue).clamp(0.0, 1.0)
        : 1.0;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 20, color: colors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Собрано оплат',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(collected * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: colors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: collected,
              minHeight: 7,
              backgroundColor: colors.surfaceGlassStrong,
              valueColor: AlwaysStoppedAnimation(colors.success),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Оплачено ${_moneyFormat.format(stats.paidAmount)} \$',
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
              ),
              Text(
                'Долг ${_moneyFormat.format(stats.outstandingAmount)} \$',
                style: TextStyle(
                  color: colors.warning,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBreakdown(ThemeColors colors, DashboardStats stats) {
    // Идём по каноническому порядку статусов, а не по порядку из Map:
    // так плашки не прыгают между обновлениями.
    final entries = BookingStatuses.all
        .where((s) => (stats.bookingsByStatus[s] ?? 0) > 0)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Бронирования по статусам',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final status in entries)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.push('/bookings'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusChip(status: status, compact: true),
                      const SizedBox(width: 5),
                      Text(
                        '${stats.bookingsByStatus[status]}',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavSection {
  final String title;
  final IconData icon;
  final String route;
  final Color color;

  const _NavSection(this.title, this.icon, this.route, this.color);
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.hint,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? hint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textPrimary, fontSize: 12),
          ),
          if (hint != null)
            Text(
              hint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary, fontSize: 10.5),
            ),
        ],
      ),
    );
  }
}
