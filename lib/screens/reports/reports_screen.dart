import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/report.dart';
import '../../providers/report_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_chip.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _dateFormat = DateFormat('dd.MM.yyyy');
  final _moneyFormat = NumberFormat('#,##0.00');
  final _compactMoney = NumberFormat('#,##0');

  DateTime _dateFrom = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dateTo = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<ReportProvider>().loadAll(_dateFrom, _dateTo);
  }

  Future<void> _pickPeriod() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(start: _dateFrom, end: _dateTo),
    );
    if (range == null || !mounted) return;
    setState(() {
      _dateFrom = range.start;
      _dateTo = range.end;
    });
    _load();
  }

  /// Быстрые пресеты периода — вручную тыкать в календарь ради «последних
  /// 30 дней» каждый раз утомительно.
  void _applyPreset(int days) {
    setState(() {
      _dateTo = DateTime.now();
      _dateFrom = _dateTo.subtract(Duration(days: days));
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Отчёты'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.accentPrimary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.accentPrimary,
          tabs: const [
            Tab(text: 'Продажи'),
            Tab(text: 'Направления'),
            Tab(text: 'Доход'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: _load,
          ),
        ],
      ),
      body: Container(
        color: colors.background,
        child: Column(
          children: [
            _buildPeriodBar(colors),
            Expanded(
              child: Consumer<ReportProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.error != null) {
                    return _errorState(colors, provider);
                  }
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSalesTab(colors, provider),
                      _buildDestinationsTab(colors, provider),
                      _buildRevenueTab(colors, provider),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------

  Widget _buildPeriodBar(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _pickPeriod,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surfaceGlass,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range, size: 18, color: colors.accentPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_dateFormat.format(_dateFrom)} — ${_dateFormat.format(_dateTo)}',
                      style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
                    ),
                  ),
                  Icon(Icons.edit_calendar_outlined,
                      size: 16, color: colors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _presetChip(colors, 'Неделя', 7),
                const SizedBox(width: 8),
                _presetChip(colors, 'Месяц', 30),
                const SizedBox(width: 8),
                _presetChip(colors, 'Квартал', 90),
                const SizedBox(width: 8),
                _presetChip(colors, 'Год', 365),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(ThemeColors colors, String label, int days) {
    return GestureDetector(
      onTap: () => _applyPreset(days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: colors.surfaceGlass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: Text(label,
            style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
      ),
    );
  }

  Widget _errorState(ThemeColors colors, ReportProvider provider) {
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
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyTab(ThemeColors colors, IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: colors.textSecondary),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: colors.textSecondary)),
        ],
      ),
    );
  }

  // --- Вкладка «Продажи» ---------------------------------------------------

  Widget _buildSalesTab(ThemeColors colors, ReportProvider provider) {
    if (provider.salesReport.isEmpty) {
      return _emptyTab(colors, Icons.receipt_long_outlined, 'Нет продаж за период');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(colors, 'Оборот',
                  '${_compactMoney.format(provider.salesTotal)} \$', colors.accentSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(colors, 'Продаж',
                  '${provider.salesReport.length}', colors.accentPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                  colors, 'Туристов', '${provider.salesPeople}', colors.success),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final row in provider.salesReport) ...[
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.tourName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${row.clientName} · ${row.peopleCount} чел. · '
                        '${_dateFormat.format(row.bookingDate)}',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_moneyFormat.format(row.totalCost)} \$',
                      style: TextStyle(
                        color: colors.accentSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StatusChip(status: row.status, compact: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  // --- Вкладка «Направления» -----------------------------------------------

  Widget _buildDestinationsTab(ThemeColors colors, ReportProvider provider) {
    final data = provider.popularDestinations;
    if (data.isEmpty) {
      return _emptyTab(colors, Icons.public_off, 'Нет данных по направлениям');
    }

    // На графике только топ-8: дальше подписи городов сливаются в кашу.
    final chartData = data.take(8).toList();
    final maxValue = chartData
        .map((r) => r.bookingsCount)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        AppCard(
          padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
          child: SizedBox(
            height: 230,
            child: BarChart(
              BarChartData(
                maxY: (maxValue + 1).toDouble(),
                barGroups: [
                  for (int i = 0; i < chartData.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: chartData[i].bookingsCount.toDouble(),
                        color: colors.accentPrimary,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ]),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= chartData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Transform.rotate(
                            angle: -0.5,
                            child: Text(
                              chartData[i].city,
                              style: TextStyle(
                                  fontSize: 9.5, color: colors.textSecondary),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      // Дробные брони бессмысленны — рисуем только целые деления.
                      interval: 1,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 10, color: colors.textSecondary),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: colors.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final row in data) ...[
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${row.country}, ${row.city}',
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  ),
                ),
                Text(
                  '${row.bookingsCount} броней · ${row.totalPeople} чел.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  // --- Вкладка «Доход» ------------------------------------------------------

  Widget _buildRevenueTab(ThemeColors colors, ReportProvider provider) {
    final revenue = provider.agencyRevenue;
    if (revenue == null) {
      return _emptyTab(colors, Icons.savings_outlined, 'Нет данных о доходе');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Комиссия агентства за период',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Text(
                '${_moneyFormat.format(revenue.totalCommission)} \$',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: colors.accentSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.event_available, size: 15, color: colors.textSecondary),
                  const SizedBox(width: 6),
                  Text('Бронирований: ${revenue.bookingsCount}',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (provider.monthlyRevenue.isNotEmpty)
          _buildMonthlyChart(colors, provider.monthlyRevenue),
      ],
    );
  }

  Widget _buildMonthlyChart(ThemeColors colors, List<MonthlyRevenueRow> data) {
    final maxValue = data
        .map((r) => r.totalCommission)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              'Комиссия по месяцам',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                // Небольшой запас сверху, иначе самый высокий столбик
                // упирается в потолок графика.
                maxY: maxValue * 1.15,
                barGroups: [
                  for (int i = 0; i < data.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: data[i].totalCommission,
                        color: colors.accentSecondary,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ]),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colors.surface,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${data[group.x].shortLabel}\n'
                      '${_moneyFormat.format(rod.toY)} \$\n'
                      '${data[group.x].bookingsCount} броней',
                      TextStyle(color: colors.textPrimary, fontSize: 12),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            data[i].shortLabel,
                            style: TextStyle(fontSize: 9.5, color: colors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        _compactMoney.format(value),
                        style: TextStyle(fontSize: 9.5, color: colors.textSecondary),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: colors.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(ThemeColors colors, String label, String value, Color color) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11.5)),
        ],
      ),
    );
  }
}
