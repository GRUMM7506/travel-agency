import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/hotel.dart';
import '../../providers/hotel_provider.dart';
import '../../services/hotel_service.dart';
// import '../../theme/app_theme.dart'; (unused)

class HotelFormScreen extends StatefulWidget {
  const HotelFormScreen({super.key, this.hotelId});

  final int? hotelId;

  @override
  State<HotelFormScreen> createState() => _HotelFormScreenState();
}

class _HotelFormScreenState extends State<HotelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hotelService = HotelService();

  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nightPriceController = TextEditingController();
  final _notesController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String? _category;
  int? _starRating;
  bool _isSaving = false;
  bool _isLoading = false;

  bool get _isEditing => widget.hotelId != null;

  final List<String> _categories = ['стандарт', 'премиум', 'люкс'];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadHotel();
    }
  }

  Future<void> _loadHotel() async {
    setState(() => _isLoading = true);
    try {
      final hotel = await _hotelService.getById(widget.hotelId!);
      _nameController.text = hotel.hotelName;
      _countryController.text = hotel.country;
      _cityController.text = hotel.city;
      _addressController.text = hotel.address ?? '';
      _category = hotel.category;
      _starRating = hotel.starRating;
      _phoneController.text = hotel.phone ?? '';
      _emailController.text = hotel.email ?? '';
      _nightPriceController.text = hotel.nightPrice.toStringAsFixed(2);
      _notesController.text = hotel.notes ?? '';
      _imageUrlController.text = hotel.imageUrl ?? '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nightPriceController.dispose();
    _notesController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final hotel = Hotel(
      hotelId: widget.hotelId,
      hotelName: _nameController.text.trim(),
      country: _countryController.text.trim(),
      city: _cityController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      category: _category,
      starRating: _starRating,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      nightPrice: double.parse(_nightPriceController.text.replaceAll(',', '.')),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
    );

    try {
      final provider = context.read<HotelProvider>();
      if (_isEditing) {
        await provider.edit(widget.hotelId!, hotel);
      } else {
        await provider.add(hotel);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Редактирование гостиницы' : 'Новая гостиница')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Название гостиницы'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _countryController,
                            decoration: const InputDecoration(labelText: 'Страна'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(labelText: 'Город'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Адрес'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Категория'),
                      items: _categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (value) => setState(() => _category = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _starRating,
                      decoration: const InputDecoration(labelText: 'Звёздность'),
                      items: List.generate(5, (i) => i + 1)
                          .map((v) => DropdownMenuItem(value: v, child: Text('$v звёзд')))
                          .toList(),
                      onChanged: (value) => setState(() => _starRating = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Телефон'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nightPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Цена за ночь'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Обязательное поле';
                        if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Некорректное число';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Примечание'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL изображения',
                        hintText: 'https://example.com/image.jpg',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_isEditing ? 'Сохранить изменения' : 'Создать гостиницу'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
