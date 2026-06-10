import 'package:flutter/material.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
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
  final List<String> _genders = ['مرد', 'زن', 'ترجیح میدهم نگویم'];

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
                  
                  CustomTextField(
                    label: 'نام کامل',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline,
                    hint: 'نام و نام خانوادگی',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  CustomTextField(
                    label: 'شماره تلفن',
                    controller: _phoneController,
                    prefixIcon: Icons.phone_outlined,
                    hint: 'مثال: ۰۹۱۲۱۲۳۴۵۶۷',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  CustomTextField(
                    label: 'عنوان شغلی',
                    controller: _headlineController,
                    prefixIcon: Icons.work_outline,
                    hint: 'مثال: توسعه‌دهنده فلاتر',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  DropdownButtonFormField<String>(
                    value: _provinceController.text,
                    decoration: InputDecoration(
                      labelText: 'استان',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radius),
                      ),
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
                  
                  CustomTextField(
                    label: 'شهر',
                    controller: _cityController,
                    prefixIcon: Icons.location_city_outlined,
                    hint: 'شهر محل سکونت',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  CustomTextField(
                    label: 'تاریخ تولد',
                    controller: _birthDateController,
                    prefixIcon: Icons.cake_outlined,
                    hint: 'مثال: ۱۳۷۰/۰۵/۱۵',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  CustomTextField(
                    label: 'درباره من',
                    controller: _aboutController,
                    prefixIcon: Icons.info_outline,
                    hint: 'توضیحات کوتاه درباره خودتان',
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  CustomButton(
                    text: 'ذخیره تغییرات',
                    onPressed: _save,
                    isExpanded: true,
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