import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/tour.dart';
import '../../providers/carrier_provider.dart';
import '../../providers/hotel_provider.dart';
import '../../providers/tour_provider.dart';
import '../../services/tour_service.dart';
// import '../../theme/app_theme.dart'; (unused)

class TourFormScreen extends StatefulWidget {
  const TourFormScreen({super.key, this.tourId});

  /// Если передан — форма работает в режиме редактирования.
  final int? tourId;

  @override
  State<TourFormScreen> createState() => _TourFormScreenState();
}

class _TourFormScreenState extends State<TourFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd.MM.yyyy');
  final _tourService = TourService();

  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _imageUrlController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  int? _hotelId;
  int? _carrierId;
  bool _isSaving = false;
  bool _isLoadingTour = false;

  bool get _isEditing => widget.tourId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<HotelProvider>().load();
      if (mounted) await context.read<CarrierProvider>().load();
      if (_isEditing) {
        await _loadTour();
      }
    });
  }

  Future<void> _loadTour() async {
    setState(() => _isLoadingTour = true);
    try {
      final tour = await _tourService.getById(widget.tourId!);
      _nameController.text = tour.tourName;
      _countryController.text = tour.country;
      _cityController.text = tour.city;
      _priceController.text = tour.basePrice.toStringAsFixed(2);
      _notesController.text = tour.notes ?? '';
      _startDate = tour.startDate;
      _endDate = tour.endDate;
      _hotelId = tour.hotelId;
      _carrierId = tour.carrierId;
      _imageUrlController.text = tour.imageUrl ?? '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingTour = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите даты начала и окончания тура')),
      );
      return;
    }
    if (!_endDate!.isAfter(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Дата окончания должна быть позже даты начала')),
      );
      return;
    }
    if (_hotelId == null || _carrierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите гостиницу и перевозчика')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final tour = Tour(
      tourId: widget.tourId,
      tourName: _nameController.text.trim(),
      country: _countryController.text.trim(),
      city: _cityController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      basePrice: double.parse(_priceController.text.replaceAll(',', '.')),
      hotelId: _hotelId!,
      carrierId: _carrierId!,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
    );

    try {
      final provider = context.read<TourProvider>();
      if (_isEditing) {
        await provider.edit(widget.tourId!, tour);
      } else {
        await provider.add(tour);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Редактирование тура' : 'Новый тур')),
      body: _isLoadingTour
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
                      decoration: const InputDecoration(labelText: 'Название тура'),
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(isStart: true),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(_startDate == null
                                ? 'Дата начала'
                                : _dateFormat.format(_startDate!)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(isStart: false),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(_endDate == null ? 'Дата окончания' : _dateFormat.format(_endDate!)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Базовая цена (за человека)'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Обязательное поле';
                        if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Некорректное число';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Consumer<HotelProvider>(
                      builder: (context, provider, _) => DropdownButtonFormField<int>(
                        initialValue: _hotelId,
                        decoration: const InputDecoration(labelText: 'Гостиница'),
                        items: provider.hotels
                            .map((h) => DropdownMenuItem(value: h.hotelId, child: Text(h.hotelName)))
                            .toList(),
                        onChanged: (value) => setState(() => _hotelId = value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<CarrierProvider>(
                      builder: (context, provider, _) => DropdownButtonFormField<int>(
                        initialValue: _carrierId,
                        decoration: const InputDecoration(labelText: 'Перевозчик'),
                        items: provider.carriers
                            .map((c) => DropdownMenuItem(value: c.carrierId, child: Text(c.companyName)))
                            .toList(),
                        onChanged: (value) => setState(() => _carrierId = value),
                      ),
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
                          : Text(_isEditing ? 'Сохранить изменения' : 'Создать тур'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
