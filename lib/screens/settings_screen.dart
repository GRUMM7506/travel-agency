import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/password_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _changePassword(BuildContext context) async {
    final result = await showPasswordDialog(context);
    if (result == null || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(result.current, result.newPassword);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Пароль изменён' : auth.error ?? 'Ошибка')),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final colors = ThemeColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из системы?'),
        content: const Text('Придётся войти заново, чтобы работать с данными агентства.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Выйти', style: TextStyle(color: colors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Чистим сводку, иначе следующий вошедший на миг увидит цифры предыдущего.
    context.read<DashboardProvider>().clear();
    await context.read<AuthProvider>().logout();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final colors = ThemeColors.of(context);
    final staff = auth.currentStaff;

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: Container(
        color: colors.background,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              if (staff != null) ...[
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: colors.accentPrimary.withValues(alpha: 0.2),
                        child: Text(
                          staff.initials,
                          style: TextStyle(
                            color: colors.accentPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff.fullName,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(staff.email,
                                style: TextStyle(
                                    color: colors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 6),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.accentPrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                staff.roleLabel,
                                style: TextStyle(
                                  color: colors.accentPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_outlined, color: colors.accentPrimary, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Тема оформления',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Выберите, как приложение будет выглядеть',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: AppThemeMode.values.map((mode) {
                        final isLast = mode == AppThemeMode.values.last;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: isLast ? 0 : 12),
                            child: _ThemeOptionCard(
                              mode: mode,
                              selected: themeProvider.mode == mode,
                              onTap: () => themeProvider.setMode(mode),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.lock_outline, color: colors.accentSecondary),
                      title: Text('Сменить пароль',
                          style: TextStyle(color: colors.textPrimary)),
                      trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
                      onTap: () => _changePassword(context),
                    ),
                    if (auth.isAdmin)
                      ListTile(
                        leading: Icon(Icons.badge_outlined, color: colors.accentPrimary),
                        title: Text('Сотрудники',
                            style: TextStyle(color: colors.textPrimary)),
                        subtitle: Text('Учётные записи и роли',
                            style:
                                TextStyle(color: colors.textSecondary, fontSize: 12)),
                        trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
                        onTap: () => context.push('/staff'),
                      ),
                    ListTile(
                      leading: Icon(Icons.storefront_outlined, color: colors.success),
                      title: Text('Открыть витрину туров',
                          style: TextStyle(color: colors.textPrimary)),
                      trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
                      onTap: () => context.go('/'),
                    ),
                    ListTile(
                      leading: Icon(Icons.logout, color: colors.danger),
                      title: Text('Выйти из системы',
                          style: TextStyle(color: colors.danger)),
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: colors.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Text('О приложении',
                            style: TextStyle(
                                color: colors.textPrimary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _infoRow(colors, 'Версия', '1.0.0'),
                    _infoRow(colors, 'Сервер', kApiBaseUrl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(ThemeColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(color: colors.textPrimary, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка выбора темы с миниатюрным превью интерфейса —
/// сразу видно, как будет выглядеть приложение.
class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  ({Color bg, Color surface, Color accent, Color text}) _previewPalette(BuildContext context) {
    switch (mode) {
      case AppThemeMode.light:
        return (
          bg: AppLightColors.background,
          surface: AppLightColors.surface,
          accent: AppLightColors.accentPrimary,
          text: AppLightColors.textPrimary,
        );
      case AppThemeMode.dark:
        return (
          bg: AppColors.background,
          surface: AppColors.surface,
          accent: AppColors.accentPrimary,
          text: AppColors.textPrimary,
        );
      case AppThemeMode.system:
        final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
        return isDark
            ? (
                bg: AppColors.background,
                surface: AppColors.surface,
                accent: AppColors.accentPrimary,
                text: AppColors.textPrimary,
              )
            : (
                bg: AppLightColors.background,
                surface: AppLightColors.surface,
                accent: AppLightColors.accentPrimary,
                text: AppLightColors.textPrimary,
              );
    }
  }

  String get _label {
    switch (mode) {
      case AppThemeMode.system:
        return 'Системная';
      case AppThemeMode.light:
        return 'Светлая';
      case AppThemeMode.dark:
        return 'Тёмная';
    }
  }

  IconData get _icon {
    switch (mode) {
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.light:
        return Icons.wb_sunny_outlined;
      case AppThemeMode.dark:
        return Icons.nightlight_round;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final palette = _previewPalette(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colors.accentPrimary : colors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.accentPrimary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Мини-превью интерфейса
            Container(
              height: 64,
              width: double.infinity,
              color: palette.bg,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 8,
                    width: 34,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: palette.accent.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: selected
                  ? colors.accentPrimary.withValues(alpha: 0.12)
                  : colors.surfaceGlass,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Icon(
                    _icon,
                    size: 18,
                    color: selected ? colors.accentPrimary : colors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? colors.accentPrimary : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
