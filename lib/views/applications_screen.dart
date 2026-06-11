import 'package:flutter/material.dart';
import '../models/application.dart';
import '../presenters/application_presenter.dart';
import '../services/mock_api_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import 'application_detail_screen.dart';
import '../models/api_response.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen>
    implements ApplicationsView {
  late final ApplicationsPresenter _presenter;

  List<JobApplication> _applications = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _presenter = ApplicationsPresenter(this, MockApiService());
    _presenter.loadApplications();
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
  void showApplications(List<JobApplication> applications) {
    if (mounted) {
      setState(() {
        _applications = applications;
        _errorMessage = null;
      });
    }
  }

  @override
  void onApplicationCancelled(String applicationId) {
    if (mounted) {
      setState(() {
        _applications.removeWhere((app) => app.id == applicationId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('درخواست با موفقیت لغو شد')),
      );
    }
  }

  @override
  void onCoverLetterUpdated(String applicationId) {
  // Refresh applications list when cover letter is updated
  _presenter.loadApplications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('درخواست‌های شغلی'),
        centerTitle: true,
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
        onRetry: _presenter.loadApplications,
      );
    }

    if (_applications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'شما هنوز هیچ درخواستی ثبت نکرده‌اید',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'برای مشاهده درخواست‌ها، ابتدا برای مشاغل اقدام کنید',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _presenter.loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _applications.length,
        itemBuilder: (context, index) {
          final application = _applications[index];
          return _ApplicationCard(
            application: application,
            onTap: () => _openApplicationDetail(application),
          );
        },
      ),
    );
  }

  void _openApplicationDetail(JobApplication application) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApplicationDetailScreen(applicationId: application.id),
      ),
    );
    if (result == true) {
      _presenter.loadApplications();
    }
  }
}

class _ApplicationCard extends StatelessWidget {
  final JobApplication application;
  final VoidCallback onTap;

  const _ApplicationCard({
    required this.application,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      application.job.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: application.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      application.status.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: application.status.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.business,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    application.job.company.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _formatDate(application.appliedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (application.coverLetter != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.description,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Text(
                      'کاورلتر ارسال شده',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}