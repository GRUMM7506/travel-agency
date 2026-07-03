import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/client_auth_provider.dart';
import '../../theme/app_theme.dart';
import 'auth_scaffold.dart';

/// Вход КЛИЕНТА в личный кабинет.
class ClientLoginScreen extends StatefulWidget {
  const ClientLoginScreen({super.key});

  @override
  State<ClientLoginScreen> createState() => _ClientLoginScreenState();
}

class _ClientLoginScreenState extends State<ClientLoginScreen> {
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

    final auth = context.read<ClientAuthProvider>();
    final success = await auth.login(_emailController.text, _passwordController.text);
    if (!mounted || !success) return;
    context.go('/client/bookings');
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final auth = context.watch<ClientAuthProvider>();

    return AuthScaffold(
      title: 'Вход в личный кабинет',
      subtitle: 'Ваши бронирования, статусы и оплата',
      icon: Icons.person_outline,
      accent: colors.accentSecondary,
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
                  labelText: 'Email',
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
                  style: ElevatedButton.styleFrom(backgroundColor: colors.accentSecondary),
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Впервые у нас?',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  TextButton(
                    onPressed: () {
                      auth.clearError();
                      context.push('/client/register');
                    },
                    child: const Text('Зарегистрироваться'),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: Icon(Icons.storefront_outlined, size: 18, color: colors.textSecondary),
                label: Text(
                  'К витрине туров',
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
