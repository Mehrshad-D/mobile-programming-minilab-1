import 'package:flutter/material.dart';

import '../models/job.dart';
import '../models/user.dart';
import '../presenters/profile_presenter.dart';
import '../services/mock_api_service.dart';
import '../utils/constants.dart';
import '../widgets/job_card.dart';
import '../widgets/loading_widget.dart';
import 'job_detail_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> implements ProfileView {
  late final ProfilePresenter _presenter;

  User? _user;
  List<Job> _appliedJobs = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _presenter = ProfilePresenter(this, MockApiService());
    _presenter.loadProfile();
  }

  // ---- ProfileView ----
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
  void showProfile(User user, List<Job> appliedJobs) {
    if (mounted) {
      setState(() {
        _user = user;
        _appliedJobs = appliedJobs;
        _errorMessage = null;
      });
    }
  }

  @override
  void onLoggedOut() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.profile)),
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
        onRetry: _presenter.loadProfile,
      );
    }
    final user = _user;
    if (user == null) {
      return const SizedBox.shrink();
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _ProfileHeader(user: user),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          AppStrings.appliedJobs,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_appliedJobs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: EmptyStateWidget(
              message: AppStrings.noAppliedJobs,
              icon: Icons.description_outlined,
            ),
          )
        else
          ..._appliedJobs.map(
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
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: _presenter.logout,
          icon: const Icon(Icons.logout),
          label: const Text(AppStrings.logout),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User user;

  const _ProfileHeader({required this.user});

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
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                user.name.isNotEmpty ? user.name.characters.first : '?',
                style: const TextStyle(
                  fontSize: 32,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (user.headline != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                user.headline!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(icon: Icons.email_outlined, value: user.email),
            if (user.phone != null)
              _InfoRow(icon: Icons.phone_outlined, value: user.phone!),
            if (user.city != null)
              _InfoRow(icon: Icons.location_on_outlined, value: user.city!),
            if (user.about != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                user.about!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
