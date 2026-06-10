import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ResumeSkillsScreen extends StatefulWidget {
  final List<String> skills;

  const ResumeSkillsScreen({super.key, required this.skills});

  @override
  State<ResumeSkillsScreen> createState() => _ResumeSkillsScreenState();
}

class _ResumeSkillsScreenState extends State<ResumeSkillsScreen> {
  late List<String> _skills;
  final TextEditingController _skillController = TextEditingController();

  final List<String> _suggestedSkills = [
    'Flutter',
    'Dart',
    'Python',
    'Java',
    'JavaScript',
    'React',
    'Node.js',
    'Django',
    'SQL',
    'Git',
    'Docker',
    'Kubernetes',
    'AWS',
    'Figma',
    'UI/UX',
    'Product Management',
    'Agile',
    'Scrum',
    'TDD',
    'REST API',
    'GraphQL',
    'Firebase',
    'MongoDB',
    'PostgreSQL',
  ];

  @override
  void initState() {
    super.initState();
    _skills = List.from(widget.skills);
  }

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('مهارت‌های حرفه‌ای'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, _skills),
          ),
        ],
      ),
      body: Column(
        children: [
          // Add skill input
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillController,
                    decoration: const InputDecoration(
                      hintText: 'مهارت خود را وارد کنید...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _addSkill(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: _addSkill,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Skills list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (_skills.isNotEmpty) ...[
                  const Text(
                    'مهارت‌های شما',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _skills.map((skill) => Chip(
                      label: Text(skill),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeSkill(skill),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    )).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                
                const Text(
                  'مهارت‌های پیشنهادی',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _suggestedSkills
                      .where((skill) => !_skills.contains(skill))
                      .map((skill) => ActionChip(
                        label: Text(skill),
                        onPressed: () => _addSuggestedSkill(skill),
                        backgroundColor: Colors.grey.shade200,
                      ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _addSuggestedSkill(String skill) {
    if (!_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }
}