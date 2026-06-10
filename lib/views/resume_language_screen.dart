import 'package:flutter/material.dart';
import '../models/resume.dart';
import '../utils/constants.dart';

class ResumeLanguageScreen extends StatefulWidget {
  final List<Language> languages;

  const ResumeLanguageScreen({super.key, required this.languages});

  @override
  State<ResumeLanguageScreen> createState() => _ResumeLanguageScreenState();
}

class _ResumeLanguageScreenState extends State<ResumeLanguageScreen> {
  late List<Language> _languages;
  final List<String> _languageNames = [
    'انگلیسی',
    'عربی',
    'آلمانی',
    'فرانسوی',
    'اسپانیایی',
    'ایتالیایی',
    'روسی',
    'ترکی استانبولی',
    'چینی',
    'ژاپنی',
    'کره‌ای',
  ];

  final List<String> _levels = [
    'مبتدی',
    'متوسط',
    'پیشرفته',
    'مسلط',
  ];

  @override
  void initState() {
    super.initState();
    _languages = List.from(widget.languages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('زبان‌ها'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, _languages),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _languages.length + 1,
              itemBuilder: (context, index) {
                if (index == _languages.length) {
                  return _buildAddButton();
                }
                return _buildLanguageCard(_languages[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(Language language, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    language.level,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: () => _editLanguage(language, index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () => _deleteLanguage(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: _addLanguage,
      icon: const Icon(Icons.add),
      label: const Text('افزودن زبان جدید'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  void _addLanguage() {
    _showLanguageDialog();
  }

  void _editLanguage(Language language, int index) {
    _showLanguageDialog(language: language, index: index);
  }

  void _deleteLanguage(int index) {
    setState(() {
      _languages.removeAt(index);
    });
  }

  void _showLanguageDialog({Language? language, int? index}) {
    String selectedLanguage = language?.name ?? _languageNames.first;
    String selectedLevel = language?.level ?? _levels.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(language == null ? 'افزودن زبان' : 'ویرایش زبان'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'زبان',
                border: OutlineInputBorder(),
              ),
              items: _languageNames.map((name) {
                return DropdownMenuItem(value: name, child: Text(name));
              }).toList(),
              onChanged: (value) {
                if (value != null) selectedLanguage = value;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: selectedLevel,
              decoration: const InputDecoration(
                labelText: 'سطح',
                border: OutlineInputBorder(),
              ),
              items: _levels.map((level) {
                return DropdownMenuItem(value: level, child: Text(level));
              }).toList(),
              onChanged: (value) {
                if (value != null) selectedLevel = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              final newLanguage = Language(
                id: language?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: selectedLanguage,
                level: selectedLevel,
              );
              setState(() {
                if (language != null && index != null) {
                  _languages[index] = newLanguage;
                } else {
                  _languages.add(newLanguage);
                }
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }
}