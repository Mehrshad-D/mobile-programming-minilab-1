import 'package:flutter/material.dart';
import '../models/resume.dart';
import '../presenters/resume_list_presenter.dart';
import '../services/mock_api_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import 'resume_builder_screen.dart';

/// "My Resumes" manager: list, choose, create and delete multiple resumes.
class ResumeListScreen extends StatefulWidget {
  const ResumeListScreen({super.key});

  @override
  State<ResumeListScreen> createState() => _ResumeListScreenState();
}

class _ResumeListScreenState extends State<ResumeListScreen>
    implements ResumeListView {
  late final ResumeListPresenter _presenter;

  List<Resume> _resumes = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _presenter = ResumeListPresenter(this, MockApiService());
    _presenter.loadResumes();
  }

  // ---- ResumeListView ----
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
  void onResumesLoaded(List<Resume> resumes) {
    if (mounted) {
      setState(() {
        _resumes = resumes;
        _errorMessage = null;
      });
    }
  }

  @override
  void onResumeCreated(Resume resume) {
    _changed = true;
    _presenter.loadResumes();
    _openBuilder(resume.id);
  }

  @override
  void onResumeDeleted() {
    _changed = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('رزومه حذف شد')),
    );
    _presenter.loadResumes();
  }

  Future<void> _openBuilder(String resumeId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResumeBuilderScreen(resumeId: resumeId),
      ),
    );
    _changed = true;
    if (mounted) _presenter.loadResumes();
  }

  Future<void> _createResume() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رزومه جدید'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'عنوان رزومه',
            hintText: 'مثال: رزومه برنامه‌نویسی',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('ایجاد'),
          ),
        ],
      ),
    );
    if (name != null) {
      _presenter.createResume(name);
    }
  }

  Future<void> _confirmDelete(Resume resume) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف رزومه'),
        content: Text('آیا از حذف «${resume.name}» اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _presenter.deleteResume(resume.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('رزومه‌های من'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createResume,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('رزومه جدید'),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _resumes.isEmpty) {
      return const LoadingWidget();
    }
    if (_errorMessage != null && _resumes.isEmpty) {
      return AppErrorWidget(
        message: _errorMessage!,
        onRetry: _presenter.loadResumes,
      );
    }
    if (_resumes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description_outlined,
                  size: 56, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'هنوز رزومه‌ای نساخته‌اید',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton.icon(
                onPressed: _createResume,
                icon: const Icon(Icons.add),
                label: const Text('ساخت اولین رزومه'),
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
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _resumes.length,
      itemBuilder: (context, index) => _buildResumeCard(_resumes[index]),
    );
  }

  Widget _buildResumeCard(Resume resume) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _openBuilder(resume.id),
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
                child: const Icon(Icons.description, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resume.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'امتیاز: ${resume.score}% • ${resume.slug ?? '-'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        _badge(
                          resume.isPublic ? 'عمومی' : 'خصوصی',
                          resume.isPublic,
                        ),
                        _badge(
                          resume.isSearchable
                              ? 'قابل جستجو'
                              : 'غیرقابل جستجو',
                          resume.isSearchable,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: 'حذف',
                onPressed: () => _confirmDelete(resume),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, bool active) {
    final color = active ? AppColors.primary : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }
}
