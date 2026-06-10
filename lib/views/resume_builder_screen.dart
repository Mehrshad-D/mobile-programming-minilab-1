import 'package:flutter/material.dart';
import '../models/resume.dart';
import '../presenters/resume_presenter.dart';
import '../services/mock_api_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import 'resume_education_screen.dart';
import 'resume_experience_screen.dart';
import 'resume_language_screen.dart';
import 'resume_skills_screen.dart';
import 'resume_preference_screen.dart';

class ResumeBuilderScreen extends StatefulWidget {
  const ResumeBuilderScreen({super.key});

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen>
    implements ResumeView {
  late final ResumePresenter _presenter;
  Resume? _resume;
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedTab = 0;

  final List<String> _tabs = [
    'اطلاعات پایه',
    'تحصیلات',
    'سوابق شغلی',
    'زبان‌ها',
    'مهارت‌ها',
    'ترجیحات',
  ];

  @override
  void initState() {
    super.initState();
    _presenter = ResumePresenter(this, MockApiService());
    _presenter.loadResume();
  }

  @override
  void showLoading() => setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

  @override
  void hideLoading() {
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void showError(String message) {
    if (mounted) setState(() => _errorMessage = message);
  }

  @override
  void showResume(Resume resume) {
    if (mounted) {
      setState(() {
        _resume = resume;
        _errorMessage = null;
      });
      _presenter.getResumeScore();
    }
  }

  @override
  void onResumeUpdated(Resume resume) {
    if (mounted) {
      setState(() => _resume = resume);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رزومه با موفقیت به‌روزرسانی شد')),
      );
    }
  }

  @override
  void onScoreUpdated(int score) {
    if (mounted && _resume != null) {
      setState(() => _resume = _resume!.copyWith(score: score));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ساخت رزومه'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildTabBar(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.primary,
      child: TabBar(
        tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        onTap: (index) => setState(() => _selectedTab = index),
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_errorMessage != null) {
      return AppErrorWidget(
        message: _errorMessage!,
        onRetry: _presenter.loadResume,
      );
    }

    final resume = _resume;
    if (resume == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _buildScoreCard(resume),
          const SizedBox(height: AppSpacing.md),
          _buildTabContent(resume),
        ],
      ),
    );
  }

  Widget _buildScoreCard(Resume resume) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'امتیاز تکمیل رزومه',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${resume.score}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: resume.score / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _getScoreMessage(resume.score),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _getScoreMessage(int score) {
    if (score < 30) return 'برای بهبود شانس استخدام، رزومه خود را کامل کنید';
    if (score < 60) return 'در مسیر درستی هستید، ادامه دهید!';
    if (score < 90) return 'رزومه عالی! فقط چند قدم تا کامل شدن باقی مانده';
    return 'تبریک! رزومه شما کامل است';
  }

  Widget _buildTabContent(Resume resume) {
    switch (_selectedTab) {
      case 0:
        return _buildBasicInfoForm(resume);
      case 1:
        return _buildEducationSection(resume);
      case 2:
        return _buildExperienceSection(resume);
      case 3:
        return _buildLanguageSection(resume);
      case 4:
        return _buildSkillsSection(resume);
      case 5:
        return _buildPreferenceSection(resume);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoForm(Resume resume) {
    final nameController = TextEditingController(text: resume.name);
    final emailController = TextEditingController(text: resume.email);
    final phoneController = TextEditingController(text: resume.phone ?? '');
    final aboutController = TextEditingController(text: resume.about ?? '');
    final birthDateController = TextEditingController(text: resume.birthDate ?? '');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اطلاعات شخصی',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'نام کامل',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'ایمیل',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'شماره تلفن',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: birthDateController,
              decoration: const InputDecoration(
                labelText: 'تاریخ تولد',
                hintText: 'مثال: ۱۳۷۰/۰۵/۱۵',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: aboutController,
              decoration: const InputDecoration(
                labelText: 'درباره من',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                _presenter.updatePersonalInfo({
                  'name': nameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                  'birth_date': birthDateController.text,
                  'about': aboutController.text,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('ذخیره اطلاعات'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationSection(Resume resume) {
    return Column(
      children: [
        if (resume.education.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text('هیچ سابقه تحصیلی ثبت نشده است'),
              ),
            ),
          )
        else
          ...resume.education.map((edu) => Card(
                child: ListTile(
                  title: Text(edu.degree),
                  subtitle: Text('${edu.field} - ${edu.university} (${edu.startYear} - ${edu.endYear ?? 'اکنون'})'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => _confirmDeleteEducation(edu.id),
                  ),
                ),
              )),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: () => _addEducation(),
          icon: const Icon(Icons.add),
          label: const Text('افزودن سابقه تحصیلی'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceSection(Resume resume) {
    return Column(
      children: [
        if (resume.experiences.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text('هیچ سابقه شغلی ثبت نشده است'),
              ),
            ),
          )
        else
          ...resume.experiences.map((exp) => Card(
                child: ListTile(
                  title: Text(exp.position),
                  subtitle: Text('${exp.company} (${exp.startYear} - ${exp.endYear ?? 'اکنون'})'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => _confirmDeleteExperience(exp.id),
                  ),
                ),
              )),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: () => _addExperience(),
          icon: const Icon(Icons.add),
          label: const Text('افزودن سابقه شغلی'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSection(Resume resume) {
    return Column(
      children: [
        if (resume.languages.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text('هیچ زبانی ثبت نشده است'),
              ),
            ),
          )
        else
          ...resume.languages.map((lang) => Card(
                child: ListTile(
                  title: Text(lang.name),
                  subtitle: Text(lang.level),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () => _editLanguages(resume),
                  ),
                ),
              )),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: () => _editLanguages(resume),
          icon: const Icon(Icons.add),
          label: const Text('ویرایش زبان‌ها'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection(Resume resume) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مهارت‌های حرفه‌ای',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: resume.skills.map((skill) => Chip(
                    label: Text(skill),
                    onDeleted: () {
                      final newSkills = resume.skills.where((s) => s != skill).toList();
                      _presenter.updateSkills(newSkills);
                    },
                  )).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () => _editSkills(resume),
              icon: const Icon(Icons.add),
              label: const Text('افزودن مهارت'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceSection(Resume resume) {
    final salaryController = TextEditingController(
      text: resume.preference.expectedSalary?.toString() ?? '',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ترجیحات شغلی',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('حقوق مورد انتظار (تومان)'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: salaryController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'مثال: 50000000',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text('عمومی بودن رزومه'),
                    value: resume.isPublic,
                    onChanged: (value) => _presenter.togglePublicity(value),
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('قابل جستجو'),
                    value: resume.isSearchable,
                    onChanged: (value) => _presenter.toggleSearchStatus(value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                _presenter.updateResume(resume.copyWith(
                  preference: JobPreference(
                    categories: resume.preference.categories,
                    provinces: resume.preference.provinces,
                    expectedSalary: int.tryParse(salaryController.text),
                  ),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('ذخیره ترجیحات'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addEducation() async {
    final result = await Navigator.of(context).push<Education>(
      MaterialPageRoute(builder: (_) => const ResumeEducationScreen()),
    );
    if (result != null) {
      await _presenter.addEducation(result);
    }
  }

  Future<void> _addExperience() async {
    final result = await Navigator.of(context).push<WorkExperience>(
      MaterialPageRoute(builder: (_) => const ResumeExperienceScreen()),
    );
    if (result != null) {
      await _presenter.addExperience(result);
    }
  }

  Future<void> _editLanguages(Resume resume) async {
    final result = await Navigator.of(context).push<List<Language>>(
      MaterialPageRoute(
        builder: (_) => ResumeLanguageScreen(languages: resume.languages),
      ),
    );
    if (result != null) {
      await _presenter.updateLanguages(result);
    }
  }

  Future<void> _editSkills(Resume resume) async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => ResumeSkillsScreen(skills: resume.skills),
      ),
    );
    if (result != null) {
      await _presenter.updateSkills(result);
    }
  }

  void _confirmDeleteEducation(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف سابقه تحصیلی'),
        content: const Text('آیا از حذف این سابقه تحصیلی اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _presenter.deleteEducation(id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExperience(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف سابقه شغلی'),
        content: const Text('آیا از حذف این سابقه شغلی اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _presenter.deleteExperience(id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}