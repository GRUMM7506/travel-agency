import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/staff.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../theme/app_theme.dart';

/// Управление учётными записями сотрудников. Роутер сюда пускает любого
/// сотрудника, но эндпоинты /staff закрыты ролью admin — менеджеру показываем
/// понятную заглушку вместо голого 403 из сети.
class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().isAdmin) {
        context.read<StaffProvider>().load();
      }
    });
  }

  Future<void> _openForm({Staff? staff}) async {
    final result = await showDialog<_StaffFormResult>(
      context: context,
      builder: (context) => _StaffFormDialog(staff: staff),
    );
    if (result == null || !mounted) return;

    final provider = context.read<StaffProvider>();
    final error = staff == null
        ? await provider.add(result.staff, result.password!)
        : await provider.edit(staff.staffId!, result.staff, password: result.password);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? (staff == null ? 'Сотрудник добавлен' : 'Сохранено'))),
    );
  }

  Future<void> _confirmDelete(Staff staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить сотрудника?'),
        content: Text('${staff.fullName} потеряет доступ в систему. Действие необратимо.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Удалить', style: TextStyle(color: ThemeColors.of(context).danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await context.read<StaffProvider>().remove(staff.staffId!);
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final auth = context.watch<AuthProvider>();

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Сотрудники')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 52, color: colors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'Раздел доступен только администратору',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ваша роль — ${auth.currentStaff?.roleLabel ?? 'менеджер'}. '
                  'Попросите администратора завести нужную учётную запись.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Сотрудники')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Добавить'),
      ),
      body: Container(
        color: colors.background,
        child: Consumer<StaffProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.staff.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.error != null && provider.staff.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: colors.danger),
                      const SizedBox(height: 16),
                      Text(provider.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.textSecondary)),
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

            return RefreshIndicator(
              onRefresh: provider.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: provider.staff.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final staff = provider.staff[index];
                  final isSelf = staff.staffId == auth.currentStaff?.staffId;
                  return _staffCard(colors, staff, isSelf);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _staffCard(ThemeColors colors, Staff staff, bool isSelf) {
    final roleColor = staff.isAdmin ? colors.accentPrimary : colors.accentSecondary;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: roleColor.withValues(alpha: 0.18),
            child: Text(
              staff.initials,
              style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        staff.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Text('· это вы',
                          style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(staff.email,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _tag(roleColor, staff.roleLabel),
                    const SizedBox(width: 8),
                    if (!staff.isActive) _tag(colors.danger, 'отключён'),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: colors.textSecondary),
            tooltip: 'Изменить',
            onPressed: () => _openForm(staff: staff),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: isSelf ? colors.textSecondary.withValues(alpha: 0.3) : colors.danger),
            tooltip: isSelf ? 'Нельзя удалить себя' : 'Удалить',
            onPressed: isSelf ? null : () => _confirmDelete(staff),
          ),
        ],
      ),
    );
  }

  Widget _tag(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ===========================================================================

class _StaffFormResult {
  const _StaffFormResult(this.staff, this.password);

  final Staff staff;

  /// null при редактировании = «пароль не менять».
  final String? password;
}

class _StaffFormDialog extends StatefulWidget {
  const _StaffFormDialog({this.staff});

  final Staff? staff;

  @override
  State<_StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends State<_StaffFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _email;
  final _password = TextEditingController();

  late String _role;
  late bool _isActive;

  bool get _isEdit => widget.staff != null;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: widget.staff?.fullName ?? '');
    _email = TextEditingController(text: widget.staff?.email ?? '');
    _role = widget.staff?.role ?? 'manager';
    _isActive = widget.staff?.isActive ?? true;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _StaffFormResult(
        Staff(
          staffId: widget.staff?.staffId,
          fullName: _fullName.text.trim(),
          email: _email.text.trim(),
          role: _role,
          isActive: _isActive,
        ),
        _password.text.isEmpty ? null : _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Изменить сотрудника' : 'Новый сотрудник'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _fullName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'ФИО'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Обязательно' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Рабочий email'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Обязательно' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _isEdit ? 'Новый пароль' : 'Пароль',
                    helperText: _isEdit
                        ? 'Оставьте пустым, чтобы не менять'
                        : 'Минимум 6 символов',
                  ),
                  validator: (v) {
                    if (_isEdit && (v == null || v.isEmpty)) return null;
                    return (v == null || v.length < 6) ? 'Минимум 6 символов' : null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Роль'),
                  items: const [
                    DropdownMenuItem(value: 'manager', child: Text('Менеджер')),
                    DropdownMenuItem(value: 'admin', child: Text('Администратор')),
                  ],
                  onChanged: (value) => setState(() => _role = value ?? 'manager'),
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  title: const Text('Доступ разрешён'),
                  subtitle: Text(
                    _isActive ? 'Может входить в систему' : 'Вход заблокирован',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: _submit, child: const Text('Сохранить')),
      ],
    );
  }
}
