import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/client.dart';
import '../../providers/client_provider.dart';
import '../../theme/app_theme.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить клиента?'),
        content: Text('${client.fullName} будет удалён без возможности восстановления.'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text('Удалить', style: TextStyle(color: ThemeColors.of(context).danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<ClientProvider>().remove(client.clientId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Клиенты')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/clients/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить клиента'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск по ФИО, телефону, email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ClientProvider>().search('');
                  },
                ),
              ),
              onSubmitted: (value) => context.read<ClientProvider>().search(value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<ClientProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.clients.isEmpty) {
                    return const Center(child: Text('Клиенты не найдены'));
                  }
                  return ListView.separated(
                    itemCount: provider.clients.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final client = provider.clients[index];
                      return AppCard(
                        onTap: () => context.push('/clients/${client.clientId}/edit'),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(client.fullName, style: Theme.of(context).textTheme.titleMedium),
                                  if (client.phone != null)
                                    Text(client.phone!, style: TextStyle(color: ThemeColors.of(context).textSecondary)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: ThemeColors.of(context).danger),
                              onPressed: () => _confirmDelete(client),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
