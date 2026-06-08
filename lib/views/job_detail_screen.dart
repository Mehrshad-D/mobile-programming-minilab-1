import 'package:flutter/material.dart';

import '../models/job.dart';
import '../presenters/job_presenter.dart';
import '../services/mock_api_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_widget.dart';
import 'company_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen>
    implements JobDetailView {
  late final JobDetailPresenter _presenter;

  Job? _job;
  bool _isLoading = false;
  bool _isApplied = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _presenter = JobDetailPresenter(this, MockApiService());
    _presenter.loadJob(widget.jobId);
  }

  // ---- JobDetailView ----
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
  void showJob(Job job) {
    if (mounted) setState(() => _job = job);
  }

  @override
  void onApplied() {
    if (!mounted) return;
    setState(() => _isApplied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.applied),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.jobsTitle)),
      body: _buildBody(),
      bottomNavigationBar: _job == null ? null : _buildApplyBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget();
    }
    if (_errorMessage != null) {
      return AppErrorWidget(
        message: _errorMessage!,
        onRetry: () => _presenter.loadJob(widget.jobId),
      );
    }
    final job = _job;
    if (job == null) {
      return const SizedBox.shrink();
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _JobHeader(job: job),
        const SizedBox(height: AppSpacing.md),
        _DetailChips(job: job),
        const SizedBox(height: AppSpacing.lg),
        if (job.description != null) ...[
          _Section(
            title: AppStrings.jobDescription,
            child: Text(
              job.description!,
              style: const TextStyle(height: 1.8, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (job.requirements.isNotEmpty) ...[
          _Section(
            title: AppStrings.jobRequirements,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: job.requirements
                  .map(
                    (req) => Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(req)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _buildCompanyTile(job),
      ],
    );
  }

  Widget _buildCompanyTile(Job job) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: const Icon(Icons.business, color: AppColors.primary),
        title: Text(job.company.name),
        subtitle: Text(job.company.industry),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CompanyScreen(slug: job.company.slug),
          ),
        ),
      ),
    );
  }

  Widget _buildApplyBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: CustomButton(
          label: _isApplied ? AppStrings.applied : AppStrings.apply,
          icon: _isApplied ? Icons.check : Icons.send,
          onPressed:
              _isApplied ? null : () => _presenter.apply(widget.jobId),
        ),
      ),
    );
  }
}

class _JobHeader extends StatelessWidget {
  final Job job;

  const _JobHeader({required this.job});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          job.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Icon(Icons.business, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              job.company.name,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailChips extends StatelessWidget {
  final Job job;

  const _DetailChips({required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'موقعیت مکانی',
              value: job.location.display,
            ),
            _InfoRow(
              icon: Icons.work_outline,
              label: AppStrings.contractType,
              value: job.contractType,
            ),
            _InfoRow(
              icon: Icons.timeline,
              label: AppStrings.experience,
              value: job.experienceLevel,
            ),
            _InfoRow(
              icon: Icons.payments_outlined,
              label: AppStrings.salary,
              value: job.salary.display,
            ),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'تاریخ انتشار',
              value: job.publishedAt,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}
