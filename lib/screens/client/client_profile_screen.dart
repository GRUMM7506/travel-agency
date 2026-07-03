import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/client_auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/my_bookings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/password_dialog.dart';

/// Профиль клиента: паспортные данные (нужны для оформления тура), тема,
/// смена пароля, выход.
class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastName = TextEditingController();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _passport = TextEditingController();
  final _foreignPassport = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final account = context.read<ClientAuthProvider>().account;
    if (account != null) {
      _lastName.text = account.lastName;
      _firstName.text = account.firstName;
      _middleName.text = account.middleName ?? '';
      _phone.text = account.phone ?? '';
      _address.text = account.address ?? '';
      _passport.text = account.passport ?? '';
      _foreignPassport.text = account.foreignPassport ?? '';
    }
  }

  @override
  void dispose() {
    _lastName.dispose();
    _firstName.dispose();
    _middleName.dispose();
    _phone.dispose();
    _address.dispose();
    _passport.dispose();
    _foreignPassport.dispose();
    super.dispose();
  }

  String? _emptyToNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<ClientAuthProvider>();
    final account = auth.account;
    if (account == null) return;

    setState(() => _isSaving = true);
    final success = await auth.updateProfile(
      account.copyWith(
        lastName: _lastName.text.trim(),
        firstName: _firstName.text.trim(),
        middleName: _emptyToNull(_middleName),
        phone: _emptyToNull(_phone),
        address: _emptyToNull(_address),
        passport: _emptyToNull(_passport),
        foreignPassport: _emptyToNull(_foreignPassport),
      ),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Профиль сохранён' : auth.error ?? 'Ошибка')),
    );
  }

  Future<void> _changePassword() async {
    final result = await showPasswordDialog(context);
    if (result == null || !mounted) return;

    final auth = context.read<ClientAuthProvider>();
    final success = await auth.changePassword(result.current, result.newPassword);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Пароль изменён' : auth.error ?? 'Ошибка')),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Ваши бронирования сохранятся — вы увидите их после входа.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Выйти', style: TextStyle(color: ThemeColors.of(context).danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    context.read<MyBookingsProvider>().clear();
    await context.read<ClientAuthProvider>().logout();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final account = context.watch<ClientAuthProvider>().account;
    final themeProvider = context.watch<ThemeProvider>();

    if (account == null) {
      // Redirect роутера уже в пути — просто не мигаем пустым экраном.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Container(
        color: colors.background,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colors.accentSecondary.withValues(alpha: 0.2),
                    child: Text(
                      account.initials,
                      style: TextStyle(
                        color: colors.accentSecondary,
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
                          account.fullName,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.email ?? '—',
                          style: TextStyle(color: colors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle(colors, Icons.badge_outlined, 'Данные для оформления'),
                    const SizedBox(height: 6),
                    Text(
                      'Менеджеру нужны паспортные данные, чтобы оформить документы по туру.',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _lastName,
                            decoration: const InputDecoration(labelText: 'Фамилия'),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Обязательно' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _firstName,
                            decoration: const InputDecoration(labelText: 'Имя'),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Обязательно' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _middleName,
                      decoration: const InputDecoration(labelText: 'Отчество'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Телефон',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address,
                      decoration: const InputDecoration(
                        labelText: 'Адрес',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _passport,
                            decoration: const InputDecoration(labelText: 'Паспорт'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _foreignPassport,
                            decoration: const InputDecoration(labelText: 'Загранпаспорт'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Сохранить'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(themeProvider.icon, color: colors.accentPrimary),
                    title: Text('Тема оформления',
                        style: TextStyle(color: colors.textPrimary)),
                    subtitle: Text(themeProvider.label,
                        style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
                    onTap: themeProvider.toggleTheme,
                  ),
                  Consumer<FavoritesProvider>(
                    builder: (context, favorites, _) => ListTile(
                      leading: Icon(Icons.favorite_border, color: colors.danger),
                      title: Text('Избранные туры',
                          style: TextStyle(color: colors.textPrimary)),
                      subtitle: Text('${favorites.count} в списке',
                          style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                      trailing: favorites.count > 0
                          ? TextButton(
                              onPressed: favorites.clearAll,
                              child: const Text('Очистить'),
                            )
                          : null,
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.lock_outline, color: colors.accentSecondary),
                    title: Text('Сменить пароль',
                        style: TextStyle(color: colors.textPrimary)),
                    trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
                    onTap: _changePassword,
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: colors.danger),
                    title: Text('Выйти из аккаунта',
                        style: TextStyle(color: colors.danger)),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeColors colors, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.accentPrimary),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
