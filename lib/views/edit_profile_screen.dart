// Replace the entire EditProfileScreen with this version:

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_widget.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;
  final Future<User> Function(User updatedUser) onSave;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.onSave,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _headlineController;
  late final TextEditingController _cityController;
  late final TextEditingController _provinceController;
  late final TextEditingController _aboutController;
  late final TextEditingController _birthDateController;

  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _provinces = [
    'تهران', 'اصفهان', 'شیراز', 'مشهد', 'البرز', 'خوزستان', 'گیلان'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _headlineController = TextEditingController(text: widget.user.headline ?? '');
    _cityController = TextEditingController(text: widget.user.city ?? '');
    _provinceController = TextEditingController(text: widget.user.province ?? 'تهران');
    _aboutController = TextEditingController(text: widget.user.about ?? '');
    _birthDateController = TextEditingController(text: widget.user.birthDate ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _headlineController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _aboutController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'لطفاً نام خود را وارد کنید');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updatedUser = widget.user.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        headline: _headlineController.text.trim().isEmpty ? null : _headlineController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        province: _provinceController.text.trim().isEmpty ? null : _provinceController.text.trim(),
        about: _aboutController.text.trim().isEmpty ? null : _aboutController.text.trim(),
        birthDate: _birthDateController.text.trim().isEmpty ? null : _birthDateController.text.trim(),
      );
      
      final savedUser = await widget.onSave(updatedUser);
      if (mounted) {
        Navigator.pop(context, savedUser);
      }
    } catch (e) {
      setState(() => _errorMessage = 'خطا در ذخیره اطلاعات: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ویرایش پروفایل'),
        centerTitle: true,
      ),
      body: _isSaving
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radius),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_errorMessage != null) const SizedBox(height: AppSpacing.md),
                  
                  // Name field
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'نام کامل',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Phone field
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'شماره تلفن',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Headline field
                  TextField(
                    controller: _headlineController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان شغلی',
                      prefixIcon: Icon(Icons.work_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Province dropdown
                  DropdownButtonFormField<String>(
                    value: _provinceController.text.isNotEmpty ? _provinceController.text : null,
                    decoration: const InputDecoration(
                      labelText: 'استان',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: _provinces.map((province) {
                      return DropdownMenuItem(
                        value: province,
                        child: Text(province),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _provinceController.text = value;
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // City field
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'شهر',
                      prefixIcon: Icon(Icons.location_city_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Birth date field
                  TextField(
                    controller: _birthDateController,
                    decoration: const InputDecoration(
                      labelText: 'تاریخ تولد',
                      prefixIcon: Icon(Icons.cake_outlined),
                      hintText: 'مثال: ۱۳۷۰/۰۵/۱۵',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // About field (multi-line)
                  TextField(
                    controller: _aboutController,
                    decoration: const InputDecoration(
                      labelText: 'درباره من',
                      prefixIcon: Icon(Icons.info_outline),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Save button - using ElevatedButton instead of CustomButton
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radius),
                      ),
                    ),
                    child: const Text('ذخیره تغییرات'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('انصراف'),
                  ),
                ],
              ),
            ),
    );
  }
}