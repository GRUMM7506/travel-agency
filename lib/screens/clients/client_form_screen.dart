import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/client.dart';
import '../../providers/client_provider.dart';
import '../../services/client_service.dart';
// import '../../theme/app_theme.dart'; (unused)

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key, this.clientId});

  final int? clientId;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientService = ClientService();
  final _dateFormat = DateFormat('dd.MM.yyyy');

  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _passportController = TextEditingController();
  final _foreignPassportController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _birthDate;
  bool _isSaving = false;
  bool _isLoading = false;

  bool get _isEditing => widget.clientId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadClient();
    }
  }

  Future<void> _loadClient() async {
    setState(() => _isLoading = true);
    try {
      final client = await _clientService.getById(widget.clientId!);
      _lastNameController.text = client.lastName;
      _firstNameController.text = client.firstName;
      _middleNameController.text = client.middleName ?? '';
      _birthDate = client.birthDate;
      _phoneController.text = client.phone ?? '';
      _emailController.text = client.email ?? '';
      _addressController.text = client.address ?? '';
      _passportController.text = client.passport ?? '';
      _foreignPassportController.text = client.foreignPassport ?? '';
      _notesController.text = client.notes ?? '';
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
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _passportController.dispose();
    _foreignPassportController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final initial = _birthDate ?? DateTime(1990);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final client = Client(
      clientId: widget.clientId,
      lastName: _lastNameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim().isEmpty ? null : _middleNameController.text.trim(),
      birthDate: _birthDate,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      passport: _passportController.text.trim().isEmpty ? null : _passportController.text.trim(),
      foreignPassport: _foreignPassportController.text.trim().isEmpty ? null : _foreignPassportController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      final provider = context.read<ClientProvider>();
      if (_isEditing) {
        await provider.edit(widget.clientId!, client);
      } else {
        await provider.add(client);
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
      appBar: AppBar(title: Text(_isEditing ? 'Редактирование клиента' : 'Новый клиент')),
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
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Фамилия'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'Имя'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _middleNameController,
                      decoration: const InputDecoration(labelText: 'Отчество'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickBirthDate,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_birthDate == null
                          ? 'Дата рождения'
                          : _dateFormat.format(_birthDate!)),
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
                      controller: _passportController,
                      decoration: const InputDecoration(labelText: 'Паспорт'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _foreignPassportController,
                      decoration: const InputDecoration(labelText: 'Заграничный паспорт'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Примечание'),
                      maxLines: 2,
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
                          : Text(_isEditing ? 'Сохранить изменения' : 'Создать клиента'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}