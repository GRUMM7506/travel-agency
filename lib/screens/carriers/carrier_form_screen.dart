import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/carrier.dart';
import '../../providers/carrier_provider.dart';
import '../../services/carrier_service.dart';
// import '../../theme/app_theme.dart'; (unused)

class CarrierFormScreen extends StatefulWidget {
  const CarrierFormScreen({super.key, this.carrierId});

  final int? carrierId;

  @override
  State<CarrierFormScreen> createState() => _CarrierFormScreenState();
}

class _CarrierFormScreenState extends State<CarrierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carrierService = CarrierService();

  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _tripCostController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _notesController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String? _transportType;
  bool _isSaving = false;
  bool _isLoading = false;

  bool get _isEditing => widget.carrierId != null;

  final List<String> _transportTypes = ['авиа', 'автобус', 'поезд', 'круиз'];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadCarrier();
    }
  }

  Future<void> _loadCarrier() async {
    setState(() => _isLoading = true);
    try {
      final carrier = await _carrierService.getById(widget.carrierId!);
      _nameController.text = carrier.companyName;
      _transportType = carrier.transportType;
      _contactPersonController.text = carrier.contactPerson ?? '';
      _phoneController.text = carrier.phone ?? '';
      _emailController.text = carrier.email ?? '';
      _addressController.text = carrier.address ?? '';
      _tripCostController.text = carrier.tripCost.toStringAsFixed(2);
      _scheduleController.text = carrier.schedule ?? '';
      _notesController.text = carrier.notes ?? '';
      _imageUrlController.text = carrier.imageUrl ?? '';
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
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _tripCostController.dispose();
    _scheduleController.dispose();
    _notesController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final carrier = Carrier(
      carrierId: widget.carrierId,
      companyName: _nameController.text.trim(),
      transportType: _transportType ?? 'авиа',
      contactPerson: _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      tripCost: double.parse(_tripCostController.text.replaceAll(',', '.')),
      schedule: _scheduleController.text.trim().isEmpty ? null : _scheduleController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
    );

    try {
      final provider = context.read<CarrierProvider>();
      if (_isEditing) {
        await provider.edit(widget.carrierId!, carrier);
      } else {
        await provider.add(carrier);
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
      appBar: AppBar(title: Text(_isEditing ? 'Редактирование перевозчика' : 'Новый перевозчик')),
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
                      decoration: const InputDecoration(labelText: 'Название компании'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _transportType,
                      decoration: const InputDecoration(labelText: 'Тип транспорта'),
                      items: _transportTypes
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (value) => setState(() => _transportType = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactPersonController,
                      decoration: const InputDecoration(labelText: 'Контактное лицо'),
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
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Адрес'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tripCostController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Стоимость поездки'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Обязательное поле';
                        if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Некорректное число';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _scheduleController,
                      decoration: const InputDecoration(labelText: 'Расписание'),
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
                          : Text(_isEditing ? 'Сохранить изменения' : 'Создать перевозчика'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}