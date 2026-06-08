import 'package:flutter/material.dart';

import '../models/company.dart';
import '../models/job.dart';
import '../presenters/company_presenter.dart';
import '../services/mock_api_service.dart';
import '../utils/constants.dart';
import '../widgets/job_card.dart';
import '../widgets/loading_widget.dart';
import 'job_detail_screen.dart';

class CompanyScreen extends StatefulWidget {
  final String slug;

  const CompanyScreen({super.key, required this.slug});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> implements CompanyView {
  late final CompanyPresenter _presenter;

  Company? _company;
  List<Job> _jobs = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _presenter = CompanyPresenter(this, MockApiService());
    _presenter.loadCompany(widget.slug);
  }

  // ---- CompanyView ----
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
  void showCompany(Company company, List<Job> jobs) {
    if (mounted) {
      setState(() {
        _company = company;
        _jobs = jobs;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_company?.name ?? AppStrings.aboutCompany)),
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
        onRetry: () => _presenter.loadCompany(widget.slug),
      );
    }
    final company = _company;
    if (company == null) {
      return const SizedBox.shrink();
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _CompanyHeader(company: company),
        if (company.about != null) ...[
          const SizedBox(height: AppSpacing.lg),
          const Text(
            AppStrings.aboutCompany,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            company.about!,
            style: const TextStyle(height: 1.8, color: AppColors.textPrimary),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          '${AppStrings.companyJobs} (${_jobs.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_jobs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: EmptyStateWidget(message: AppStrings.noJobs),
          )
        else
          ..._jobs.map(
            (job) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: JobCard(
                job: job,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => JobDetailScreen(jobId: job.id),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  final Company company;

  const _CompanyHeader({required this.company});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              alignment: Alignment.center,
              child: Text(
                company.name.isNotEmpty ? company.name.characters.first : '?',
                style: const TextStyle(
                  fontSize: 28,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    company.industry,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      if (company.city != null) ...[
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          company.city!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      if (company.employeeCount != null) ...[
                        const Icon(
                          Icons.people_outline,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${company.employeeCount} نفر',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
