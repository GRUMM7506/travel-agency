import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/carrier.dart';
import '../../providers/carrier_provider.dart';
import '../../theme/app_theme.dart';

class CarrierListScreen extends StatefulWidget {
  const CarrierListScreen({super.key});

  @override
  State<CarrierListScreen> createState() => _CarrierListScreenState();
}

class _CarrierListScreenState extends State<CarrierListScreen> {
  Future<void> _confirmDelete(Carrier carrier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить перевозчика?'),
        content: Text('Перевозчик «${carrier.companyName}» будет удалён без возможности восстановления.'),
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
      await context.read<CarrierProvider>().remove(carrier.carrierId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Перевозчики')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/carriers/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<CarrierProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) return const Center(child: CircularProgressIndicator());
            if (provider.carriers.isEmpty) return const Center(child: Text('Перевозчики не добавлены'));
            return ListView.separated(
              itemCount: provider.carriers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final carrier = provider.carriers[index];
                return AppCard(
                  onTap: () => context.push('/carriers/${carrier.carrierId}/edit'),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Изображение перевозчика (если есть)
                      if (carrier.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            carrier.imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                      if (carrier.imageUrl != null) const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(carrier.companyName, style: Theme.of(context).textTheme.titleMedium),
                            Text(carrier.transportType, style: TextStyle(color: ThemeColors.of(context).textSecondary)),
                          ],
                        ),
                      ),
                      Text('${carrier.tripCost.toStringAsFixed(0)} \$'),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: ThemeColors.of(context).danger),
                        onPressed: () => _confirmDelete(carrier),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}