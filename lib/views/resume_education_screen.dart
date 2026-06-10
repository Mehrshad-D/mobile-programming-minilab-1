import 'package:flutter/material.dart';
import '../models/resume.dart';
import '../utils/constants.dart';

class ResumeEducationScreen extends StatefulWidget {
  final Education? education;

  const ResumeEducationScreen({super.key, this.education});

  @override
  State<ResumeEducationScreen> createState() => _ResumeEducationScreenState();
}

class _ResumeEducationScreenState extends State<ResumeEducationScreen> {
  late final TextEditingController _degreeController;
  late final TextEditingController _fieldController;
  late final TextEditingController _universityController;
  late final TextEditingController _startYearController;
  late final TextEditingController _endYearController;
  bool _isCurrent = false;

  final List<String> _degrees = [
    'دیپلم',
    'کاردانی',
    'کارشناسی',
    'کارشناسی ارشد',
    'دکتری',
    'فوق دکتری',
  ];

  @override
  void initState() {
    super.initState();
    _degreeController = TextEditingController(text: widget.education?.degree ?? '');
    _fieldController = TextEditingController(text: widget.education?.field ?? '');
    _universityController = TextEditingController(text: widget.education?.university ?? '');
    _startYearController = TextEditingController(
      text: widget.education?.startYear.toString() ?? '',
    );
    _endYearController = TextEditingController(
      text: widget.education?.endYear?.toString() ?? '',
    );
    _isCurrent = widget.education?.isCurrent ?? false;
  }

  @override
  void dispose() {
    _degreeController.dispose();
    _fieldController.dispose();
    _universityController.dispose();
    _startYearController.dispose();
    _endYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.education == null ? 'افزودن سابقه تحصیلی' : 'ویرایش سابقه تحصیلی'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Degree Dropdown
            const Text(
              'مقطع تحصیلی',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _degreeController.text.isNotEmpty ? _degreeController.text : null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'مقطع تحصیلی را انتخاب کنید',
              ),
              items: _degrees.map((degree) {
                return DropdownMenuItem(value: degree, child: Text(degree));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _degreeController.text = value;
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Field of Study
            const Text(
              'رشته تحصیلی',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _fieldController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'مثال: مهندسی کامپیوتر',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // University
            const Text(
              'دانشگاه',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _universityController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'مثال: دانشگاه تهران',
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
                hintText: 'مثال: 1395',
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
                const Text('در حال حاضر مشغول به تحصیل هستم'),
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
                  hintText: 'مثال: 1400',
                ),
                keyboardType: TextInputType.number,
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // Save Button
            ElevatedButton(
              onPressed: _saveEducation,
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

  void _saveEducation() {
    // Validation
    if (_degreeController.text.isEmpty) {
      _showError('لطفاً مقطع تحصیلی را انتخاب کنید');
      return;
    }
    if (_fieldController.text.isEmpty) {
      _showError('لطفاً رشته تحصیلی را وارد کنید');
      return;
    }
    if (_universityController.text.isEmpty) {
      _showError('لطفاً نام دانشگاه را وارد کنید');
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

    final education = Education(
      id: widget.education?.id ?? '',
      degree: _degreeController.text,
      field: _fieldController.text,
      university: _universityController.text,
      startYear: startYear,
      endYear: endYear,
      isCurrent: _isCurrent,
    );

    Navigator.pop(context, education);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }
}