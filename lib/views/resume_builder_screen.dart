import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/resume.dart';
import '../presenters/resume_presenter.dart';
import '../services/mock_api_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import 'resume_education_screen.dart';
import 'resume_list_screen.dart';
import 'resume_experience_screen.dart';
import 'resume_language_screen.dart';
import 'resume_skills_screen.dart';

class ResumeBuilderScreen extends StatefulWidget {
  /// When provided, edits this specific resume; otherwise the primary/active
  /// resume is loaded (creating a default one if none exists).
  final String? resumeId;

  const ResumeBuilderScreen({super.key, this.resumeId});

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen>
    with SingleTickerProviderStateMixin
    implements ResumeView {
  late final ResumePresenter _presenter;
  late final TabController _tabController;
  Resume? _resume;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _tabs = [
    'اطلاعات پایه',
    'تحصیلات',
    'سوابق شغلی',
    'زبان‌ها',
    'مهارت‌ها',
    'تنظیمات',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _presenter = ResumePresenter(this, MockApiService());
    if (widget.resumeId != null) {
      _presenter.loadResumeById(widget.resumeId!);
    } else {
      _presenter.loadResume();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
  void onResumeLink(String link) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('لینک عمومی رزومه'),
        content: SelectableText(
          link,
          style: const TextStyle(color: AppColors.primary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('لینک کپی شد')),
              );
            },
            child: const Text('کپی لینک'),
          ),
        ],
      ),
    );
  }

  @override
  void onResumesLoaded(List<Resume> resumes) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('رزومه‌های من (${resumes.length})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resumes.isEmpty
              ? [const Text('هنوز رزومه‌ای ندارید')]
              : resumes
                  .map(
                    (r) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description_outlined,
                          color: AppColors.primary),
                      title: Text(r.name),
                      subtitle: Text('${r.slug ?? '-'} • ${r.score}%'),
                    ),
                  )
                  .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  @override
  void onTranslationLoaded(Map<String, dynamic> translation) {
    if (!mounted) return;
    final skills = (translation['skills'] as List?)?.join('، ') ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ترجمه رزومه (${translation['lang']})'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _translationRow('نام', translation['name']?.toString()),
              _translationRow('درباره', translation['about']?.toString()),
              _translationRow('مهارت‌ها', skills),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  Widget _translationRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ساخت رزومه'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'لینک عمومی رزومه',
            onPressed: _resume == null ? null : _presenter.loadResumeLink,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _presenter.loadResume,
              child: const Text('تلاش مجدد'),
            ),
          ],
        ),
      );
    }

    final resume = _resume;
    if (resume == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildScoreCard(resume),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBasicInfoForm(resume),
              _buildEducationSection(resume),
              _buildExperienceSection(resume),
              _buildLanguageSection(resume),
              _buildSkillsSection(resume),
              _buildSettingsSection(resume),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard(Resume resume) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Card(
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
                minHeight: 8,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _getScoreMessage(resume.score),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
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

  Widget _buildBasicInfoForm(Resume resume) {
    final nameController = TextEditingController(text: resume.name);
    final emailController = TextEditingController(text: resume.email);
    final phoneController = TextEditingController(text: resume.phone ?? '');
    final aboutController = TextEditingController(text: resume.about ?? '');
    final birthDateController = TextEditingController(text: resume.birthDate ?? '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Card(
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
      ),
    );
  }

  Widget _buildEducationSection(Resume resume) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
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
      ),
    );
  }

  Widget _buildExperienceSection(Resume resume) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
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
      ),
    );
  }

  Widget _buildLanguageSection(Resume resume) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
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
      ),
    );
  }

  Widget _buildSkillsSection(Resume resume) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Card(
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
              if (resume.skills.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Text('هیچ مهارتی ثبت نشده است'),
                  ),
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
      ),
    );
  }

  Widget _buildSettingsSection(Resume resume) {
    final slugController = TextEditingController(text: resume.slug ?? '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slug
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('آدرس عمومی رزومه (slug)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: slugController,
                    decoration: const InputDecoration(
                      hintText: 'مثال: ali-developer',
                      border: OutlineInputBorder(),
                      prefixText: 'jobinja.ir/r/',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ElevatedButton(
                      onPressed: () => _presenter.updateSlug(
                        resume.id,
                        slugController.text.trim(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('ذخیره آدرس'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Publicity & search toggles
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('رزومه عمومی'),
                  subtitle: const Text('نمایش رزومه شما برای کارفرمایان'),
                  value: resume.isPublic,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => _presenter.togglePublicity(v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('قابل جستجو'),
                  subtitle: const Text('نمایش رزومه در نتایج جستجوی کارفرمایان'),
                  value: resume.isSearchable,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => _presenter.toggleSearchStatus(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Translation / list / create
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('بیشتر',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.sm),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.translate,
                        color: AppColors.primary),
                    title: const Text('مشاهده ترجمه انگلیسی'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => _presenter.loadTranslation('en'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.list_alt,
                        color: AppColors.primary),
                    title: const Text('مدیریت رزومه‌ها'),
                    subtitle: const Text('ساخت، انتخاب و حذف رزومه‌ها'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ResumeListScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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