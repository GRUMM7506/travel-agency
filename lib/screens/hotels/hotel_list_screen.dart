import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/hotel.dart';
import '../../providers/hotel_provider.dart';
import '../../theme/app_theme.dart';

class HotelListScreen extends StatefulWidget {
  const HotelListScreen({super.key});

  @override
  State<HotelListScreen> createState() => _HotelListScreenState();
}

class _HotelListScreenState extends State<HotelListScreen> {
  Future<void> _confirmDelete(Hotel hotel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить гостиницу?'),
        content: Text('Гостиница «${hotel.hotelName}» будет удалена без возможности восстановления.'),
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
      await context.read<HotelProvider>().remove(hotel.hotelId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Гостиницы')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/hotels/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<HotelProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) return const Center(child: CircularProgressIndicator());
            if (provider.hotels.isEmpty) return const Center(child: Text('Гостиницы не добавлены'));
            return ListView.separated(
              itemCount: provider.hotels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final hotel = provider.hotels[index];
                return AppCard(
                  onTap: () => context.push('/hotels/${hotel.hotelId}/edit'),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Изображение гостиницы (если есть)
                      if (hotel.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            hotel.imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                      if (hotel.imageUrl != null) const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hotel.hotelName, style: Theme.of(context).textTheme.titleMedium),
                            Text('${hotel.country}, ${hotel.city}',
                                style: TextStyle(color: ThemeColors.of(context).textSecondary)),
                          ],
                        ),
                      ),
                      Text('${hotel.nightPrice.toStringAsFixed(0)} \$/ночь'),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: ThemeColors.of(context).danger),
                        onPressed: () => _confirmDelete(hotel),
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