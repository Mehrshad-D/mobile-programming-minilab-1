import 'package:flutter/material.dart';
import '../models/job_alert.dart';
import '../models/job_filters.dart';
import '../utils/constants.dart';

class CreateAlertScreen extends StatefulWidget {
  final AlertMeta meta;
  final JobAlert? existingAlert;

  const CreateAlertScreen({
    super.key,
    required this.meta,
    this.existingAlert,
  });

  @override
  State<CreateAlertScreen> createState() => _CreateAlertScreenState();
}

class _CreateAlertScreenState extends State<CreateAlertScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _keywordController;
  
  late List<String> _selectedKeywords;
  late List<String> _selectedLocations;
  late List<String> _selectedCategories;
  late List<String> _selectedJobTypes;
  late List<String> _selectedExperiences;
  late AlertFrequency _selectedFrequency;
  late bool _remoteOnly;
  late bool _internshipOnly;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAlert;
    final filters = existing?.filters ?? const JobFilters();
    
    _nameController = TextEditingController(text: existing?.name ?? '');
    _keywordController = TextEditingController();
    
    _selectedKeywords = List.from(filters.keywords);
    _selectedLocations = List.from(filters.locations);
    _selectedCategories = List.from(filters.jobCategories);
    _selectedJobTypes = List.from(filters.jobTypes);
    _selectedExperiences = List.from(filters.workExperiences);
    _selectedFrequency = existing?.frequency ?? AlertFrequency.weekly;
    _remoteOnly = filters.remote;
    _internshipOnly = filters.internship;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  void _addKeyword() {
    final keyword = _keywordController.text.trim();
    if (keyword.isNotEmpty && !_selectedKeywords.contains(keyword)) {
      setState(() {
        _selectedKeywords.add(keyword);
        _keywordController.clear();
      });
    }
  }

  void _removeKeyword(String keyword) {
    setState(() {
      _selectedKeywords.remove(keyword);
    });
  }

  void _saveAlert() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً نام هشدار را وارد کنید')),
      );
      return;
    }

    if (_selectedKeywords.isEmpty && _selectedLocations.isEmpty && _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداقل یک فیلتر (کلمه کلیدی، مکان یا دسته) را انتخاب کنید')),
      );
      return;
    }

    final filters = JobFilters(
      keywords: _selectedKeywords,
      locations: _selectedLocations,
      jobCategories: _selectedCategories,
      jobTypes: _selectedJobTypes,
      workExperiences: _selectedExperiences,
      remote: _remoteOnly,
      internship: _internshipOnly,
      sortBy: JobSort.publishedAtDesc,
      page: 1,
    );

    final alert = JobAlert(
      id: widget.existingAlert?.id ?? '',
      name: _nameController.text.trim(),
      filters: filters,
      frequency: _selectedFrequency,
      createdAt: widget.existingAlert?.createdAt ?? DateTime.now(),
    );

    Navigator.pop(context, alert);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.existingAlert == null ? 'ایجاد هشدار جدید' : 'ویرایش هشدار'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert Name
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'نام هشدار',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'مثال: برنامه‌نویس پایتون در تهران',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Keywords
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'کلمات کلیدی',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _keywordController,
                            decoration: const InputDecoration(
                              hintText: 'مثال: Flutter, Python',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _addKeyword(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ElevatedButton(
                          onPressed: _addKeyword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('افزودن'),
                        ),
                      ],
                    ),
                    if (_selectedKeywords.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _selectedKeywords.map((keyword) => Chip(
                          label: Text(keyword),
                          onDeleted: () => _removeKeyword(keyword),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Locations
            _buildMultiSelectSection(
              title: 'مکان',
              options: widget.meta.locations,
              selected: _selectedLocations,
              onChanged: (selected) => setState(() => _selectedLocations = selected),
            ),
            const SizedBox(height: AppSpacing.md),

            // Categories
            _buildMultiSelectSection(
              title: 'دسته‌بندی شغلی',
              options: widget.meta.jobCategories,
              selected: _selectedCategories,
              onChanged: (selected) => setState(() => _selectedCategories = selected),
            ),
            const SizedBox(height: AppSpacing.md),

            // Job Types
            _buildMultiSelectSection(
              title: 'نوع همکاری',
              options: widget.meta.jobTypes,
              selected: _selectedJobTypes,
              onChanged: (selected) => setState(() => _selectedJobTypes = selected),
            ),
            const SizedBox(height: AppSpacing.md),

            // Work Experiences
            _buildMultiSelectSection(
              title: 'سابقه کار',
              options: widget.meta.workExperiences,
              selected: _selectedExperiences,
              onChanged: (selected) => setState(() => _selectedExperiences = selected),
            ),
            const SizedBox(height: AppSpacing.md),

            // Frequency
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'فرکانس ارسال',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<AlertFrequency>(
                      segments: const [
                        ButtonSegment(value: AlertFrequency.instantly, label: Text('فوری')),
                        ButtonSegment(value: AlertFrequency.daily, label: Text('روزانه')),
                        ButtonSegment(value: AlertFrequency.weekly, label: Text('هفتگی')),
                        ButtonSegment(value: AlertFrequency.biweekly, label: Text('دو هفته یکبار')),
                      ],
                      selected: {_selectedFrequency},
                      onSelectionChanged: (Set<AlertFrequency> selection) {
                        setState(() {
                          _selectedFrequency = selection.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'گزینه‌های اضافی',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CheckboxListTile(
                      title: const Text('فقط دورکاری'),
                      value: _remoteOnly,
                      onChanged: (value) => setState(() => _remoteOnly = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text('فقط کارآموزی'),
                      value: _internshipOnly,
                      onChanged: (value) => setState(() => _internshipOnly = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: Text(widget.existingAlert == null ? 'ایجاد هشدار' : 'ذخیره تغییرات'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectSection({
    required String title,
    required List<String> options,
    required List<String> selected,
    required Function(List<String>) onChanged,
  }) {
    if (options.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: options.map((option) {
                final isSelected = selected.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (selectedValue) {
                    if (selectedValue) {
                      onChanged([...selected, option]);
                    } else {
                      onChanged(selected.where((s) => s != option).toList());
                    }
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}