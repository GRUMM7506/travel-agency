import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'auth_scaffold.dart';

/// Вход СОТРУДНИКА в CRM.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(_emailController.text, _passwordController.text);
    if (!mounted || !success) return;

    // Роутер сам уведёт с /login (redirect слушает AuthProvider), но если
    // пользователь пришёл сюда осознанно с витрины — отправим его в админку.
    context.go('/admin');
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final auth = context.watch<AuthProvider>();

    return AuthScaffold(
      title: 'Вход для сотрудников',
      subtitle: 'CRM турагентства «Мечта»',
      icon: Icons.admin_panel_settings_outlined,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Рабочий email',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Введите email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Введите пароль' : null,
              ),
              const SizedBox(height: 24),
              if (auth.error != null) AuthErrorBanner(message: auth.error!),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: auth.isLoading ? null : _submit,
                  icon: auth.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: Text(auth.isLoading ? 'Входим...' : 'Войти'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: Icon(Icons.storefront_outlined, size: 18, color: colors.textSecondary),
                label: Text(
                  'Вернуться на витрину туров',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
