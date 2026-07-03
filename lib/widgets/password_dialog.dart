import 'package:flutter/material.dart';

/// Результат диалога смены пароля.
class PasswordChangeResult {
  const PasswordChangeResult(this.current, this.newPassword);

  final String current;
  final String newPassword;
}

/// Диалог «Сменить пароль» — общий для сотрудника и клиента: эндпоинты разные
/// (/auth/password и /auth/client/password), а форма и правила одинаковые.
/// Возвращает null, если пользователь отменил.
Future<PasswordChangeResult?> showPasswordDialog(BuildContext context) {
  return showDialog<PasswordChangeResult>(
    context: context,
    builder: (context) => const _PasswordDialog(),
  );
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      PasswordChangeResult(_current.text, _newPassword.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Смена пароля'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _current,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Текущий пароль',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Введите текущий пароль' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newPassword,
              obscureText: _obscure,
              decoration: const InputDecoration(
                labelText: 'Новый пароль',
                helperText: 'Минимум 6 символов',
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Минимум 6 символов' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'Повторите новый пароль'),
              validator: (v) => v != _newPassword.text ? 'Пароли не совпадают' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: _submit, child: const Text('Сменить')),
      ],
    );
  }
}
