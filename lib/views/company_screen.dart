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
  bool _isFollowing = false;

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
        _isFollowing = company.isFollowed;
        _errorMessage = null;
      });
    }
  }

  @override
  void onFollowChanged(bool isFollowing) {
    if (mounted) {
      setState(() => _isFollowing = isFollowing);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFollowing ? 'شرکت را دنبال کردید' : 'دنبال کردن شرکت لغو شد'),
          backgroundColor: isFollowing ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _toggleFollow() async {
    if (_company == null) return;
    
    if (_isFollowing) {
      await _presenter.unfollowCompany(_company!.id);
    } else {
      await _presenter.followCompany(_company!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_company?.name ?? AppStrings.aboutCompany),
        actions: [
          if (_company != null)
            IconButton(
              icon: Icon(
                _isFollowing ? Icons.bookmark : Icons.bookmark_border,
                color: _isFollowing ? Colors.yellow : Colors.white,
              ),
              onPressed: _toggleFollow,
              tooltip: _isFollowing ? 'لغو دنبال کردن' : 'دنبال کردن',
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
        const SizedBox(height: AppSpacing.md),
        
        // Stats Row
        _buildStatsRow(company),
        const SizedBox(height: AppSpacing.md),
        
        if (company.about != null) ...[
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
          const SizedBox(height: AppSpacing.lg),
        ],
        
        // Contact Info
        _buildContactInfo(company),
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

  Widget _buildStatsRow(Company company) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people,
            value: '${company.followersCount}',
            label: 'دنبال‌کننده',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.work,
            value: '${_jobs.length}',
            label: 'موقعیت شغلی',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.star,
            value: company.rating?.toStringAsFixed(1) ?? '۴.۵',
            label: 'امتیاز',
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(Company company) {
    final hasContactInfo = company.website != null ||
        company.email != null ||
        company.phone != null;
    
    if (!hasContactInfo) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اطلاعات تماس',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (company.website != null)
              _ContactRow(
                icon: Icons.language,
                label: 'وبسایت',
                value: company.website!,
                isUrl: true,
              ),
            if (company.email != null)
              _ContactRow(
                icon: Icons.email,
                label: 'ایمیل',
                value: company.email!,
                isEmail: true,
              ),
            if (company.phone != null)
              _ContactRow(
                icon: Icons.phone,
                label: 'تلفن',
                value: company.phone!,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isUrl;
  final bool isEmail;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isUrl = false,
    this.isEmail = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: InkWell(
              onTap: () {
                // TODO: Launch URL or email
              },
              child: Text(
                value,
                style: TextStyle(
                  color: isUrl || isEmail ? AppColors.primary : AppColors.textPrimary,
                  decoration: isUrl || isEmail ? TextDecoration.underline : null,
                ),
              ),
            ),
          ),
        ],
      ),
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