import 'package:flutter/material.dart';
import '../models/resume.dart';
import '../utils/constants.dart';

class ResumeExperienceScreen extends StatefulWidget {
  final WorkExperience? experience;

  const ResumeExperienceScreen({super.key, this.experience});

  @override
  State<ResumeExperienceScreen> createState() => _ResumeExperienceScreenState();
}

class _ResumeExperienceScreenState extends State<ResumeExperienceScreen> {
  late final TextEditingController _companyController;
  late final TextEditingController _positionController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _startYearController;
  late final TextEditingController _endYearController;
  bool _isCurrent = false;

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: widget.experience?.company ?? '');
    _positionController = TextEditingController(text: widget.experience?.position ?? '');
    _descriptionController = TextEditingController(text: widget.experience?.description ?? '');
    _startYearController = TextEditingController(
      text: widget.experience?.startYear.toString() ?? '',
    );
    _endYearController = TextEditingController(
      text: widget.experience?.endYear?.toString() ?? '',
    );
    _isCurrent = widget.experience?.isCurrent ?? false;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _positionController.dispose();
    _descriptionController.dispose();
    _startYearController.dispose();
    _endYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.experience == null ? 'افزودن سابقه شغلی' : 'ویرایش سابقه شغلی'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Name
            const Text(
              'نام شرکت',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'مثال: شرکت فناوری اطلاعات',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Position
            const Text(
              'عنوان شغلی',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _positionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'مثال: توسعه‌دهنده فلاتر',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Start Year
            const Text(
              'سال شروع',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _startYearController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'مثال: 1400',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),

            // Current Checkbox
            Row(
              children: [
                Checkbox(
                  value: _isCurrent,
                  onChanged: (value) {
                    setState(() {
                      _isCurrent = value ?? false;
                      if (_isCurrent) {
                        _endYearController.clear();
                      }
                    });
                  },
                ),
                const Text('هم اکنون مشغول به کار هستم'),
              ],
            ),

            if (!_isCurrent) ...[
              const SizedBox(height: AppSpacing.md),
              const Text(
                'سال پایان',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _endYearController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'مثال: 1403',
                ),
                keyboardType: TextInputType.number,
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Description
            const Text(
              'توضیحات (اختیاری)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'مسئولیت‌ها و دستاوردهای شما...',
              ),
              maxLines: 4,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Save Button
            ElevatedButton(
              onPressed: _saveExperience,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
              ),
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveExperience() {
    // Validation
    if (_companyController.text.isEmpty) {
      _showError('لطفاً نام شرکت را وارد کنید');
      return;
    }
    if (_positionController.text.isEmpty) {
      _showError('لطفاً عنوان شغلی را وارد کنید');
      return;
    }
    final startYear = int.tryParse(_startYearController.text);
    if (startYear == null) {
      _showError('لطفاً سال شروع را به درستی وارد کنید');
      return;
    }

    int? endYear;
    if (!_isCurrent) {
      endYear = int.tryParse(_endYearController.text);
      if (endYear == null) {
        _showError('لطفاً سال پایان را به درستی وارد کنید');
        return;
      }
      if (endYear <= startYear) {
        _showError('سال پایان باید بزرگتر از سال شروع باشد');
        return;
      }
    }

    final experience = WorkExperience(
      id: widget.experience?.id ?? '',
      company: _companyController.text,
      position: _positionController.text,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      startYear: startYear,
      endYear: endYear,
      isCurrent: _isCurrent,
    );

    Navigator.pop(context, experience);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }
}