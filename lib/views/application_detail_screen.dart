import 'package:flutter/material.dart';
import '../models/application.dart';
import '../presenters/application_presenter.dart';
import '../services/mock_api_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_widget.dart';
import 'job_detail_screen.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final String applicationId;

  const ApplicationDetailScreen({super.key, required this.applicationId});

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen>
    implements ApplicationDetailView {
  late final ApplicationDetailPresenter _presenter;

  JobApplication? _application;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEditingCoverLetter = false;
  late final TextEditingController _coverLetterController;

  @override
  void initState() {
    super.initState();
    _presenter = ApplicationDetailPresenter(this, MockApiService());
    _coverLetterController = TextEditingController();
    _presenter.loadApplication(widget.applicationId);
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
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
  void showApplication(JobApplication application) {
    if (mounted) {
      setState(() {
        _application = application;
        _coverLetterController.text = application.coverLetter?.content ?? '';
        _errorMessage = null;
      });
    }
  }

  @override
  void onCoverLetterUploaded(JobApplication application) {
    if (mounted) {
      setState(() {
        _application = application;
        _isEditingCoverLetter = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کاورلتر با موفقیت ذخیره شد')),
      );
    }
  }

  @override
  void onApplicationCancelled() {
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('جزئیات درخواست'),
        centerTitle: true,
        actions: [
          if (_application != null &&
              _application!.status != ApplicationStatus.cancelled &&
              _application!.status != ApplicationStatus.accepted &&
              _application!.status != ApplicationStatus.rejected)
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
              onPressed: _confirmCancel,
              tooltip: 'لغو درخواست',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_errorMessage != null) {
      return AppErrorWidget(
        message: _errorMessage!,
        onRetry: () => _presenter.loadApplication(widget.applicationId),
      );
    }

    final application = _application;
    if (application == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Info Card
          Card(
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => JobDetailScreen(jobId: application.job.id),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.job.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      application.job.company.name,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.location_on_outlined,
                            label: application.job.location.display,
                          ),
                        ),
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.work_outline,
                            label: application.job.contractType,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.payments_outlined,
                            label: application.job.salary.display,
                          ),
                        ),
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.timeline,
                            label: application.job.experienceLevel,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: application.status.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(application.status),
                      color: application.status.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'وضعیت درخواست',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          application.status.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: application.status.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(application.appliedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Cover Letter Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'کاورلتر',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (application.status != ApplicationStatus.cancelled &&
                          application.status != ApplicationStatus.accepted &&
                          application.status != ApplicationStatus.rejected)
                        TextButton.icon(
                          onPressed: () => _toggleEditCoverLetter(application),
                          icon: Icon(
                            _isEditingCoverLetter ? Icons.close : Icons.edit,
                            size: 16,
                          ),
                          label: Text(_isEditingCoverLetter ? 'انصراف' : 'ویرایش'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_isEditingCoverLetter)
                    Column(
                      children: [
                        TextField(
                          controller: _coverLetterController,
                          decoration: const InputDecoration(
                            hintText: 'متن کاورلتر خود را وارد کنید...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 8,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: () => _saveCoverLetter(application.id),
                            style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            ),
                            child: const Text('ذخیره کاورلتر'),
                        ),
                        ),
                      ],
                    )
                  else if (application.coverLetter != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(AppSpacing.radius),
                      ),
                      child: Text(
                        application.coverLetter!.content,
                        style: const TextStyle(height: 1.6),
                      ),
                    )
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'کاورلتری ارسال نشده است',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Resume Info
          if (application.resumeUrl != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.description, color: AppColors.primary),
                title: const Text('رزومه ارسال شده'),
                subtitle: Text(application.resumeUrl!),
                trailing: const Icon(Icons.chevron_left),
                onTap: () {
                  // TODO: Open resume preview
                },
              ),
            ),
        ],
      ),
    );
  }

  void _toggleEditCoverLetter(JobApplication application) {
    setState(() {
      if (!_isEditingCoverLetter) {
        _coverLetterController.text = application.coverLetter?.content ?? '';
      }
      _isEditingCoverLetter = !_isEditingCoverLetter;
    });
  }

  void _saveCoverLetter(String applicationId) async {
    if (_coverLetterController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً متن کاورلتر را وارد کنید')),
      );
      return;
    }

    final application = _application;
    if (application == null) return;

    if (application.coverLetter != null) {
      await _presenter.updateCoverLetter(applicationId, _coverLetterController.text);
    } else {
      await _presenter.uploadCoverLetter(applicationId, _coverLetterController.text);
    }
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('لغو درخواست'),
        content: const Text(
          'آیا از لغو این درخواست اطمینان دارید؟ این عمل قابل بازگشت نیست.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _presenter.cancelApplication(widget.applicationId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('لغو درخواست'),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Icons.hourglass_empty;
      case ApplicationStatus.reviewing:
        return Icons.visibility;
      case ApplicationStatus.accepted:
        return Icons.check_circle;
      case ApplicationStatus.rejected:
        return Icons.cancel;
      case ApplicationStatus.cancelled:
        return Icons.remove_circle;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}