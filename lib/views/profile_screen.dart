import 'dart:io';
import 'package:flutter/material.dart';
import '../models/job.dart';
import '../models/user.dart';
import '../presenters/profile_presenter.dart';
import '../services/mock_api_service.dart';
import '../utils/constants.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/job_card.dart';
import '../widgets/loading_widget.dart';
import 'edit_profile_screen.dart';
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
  void onProfileUpdated(User updatedUser) {
    if (mounted) {
      setState(() {
        _user = updatedUser;
        _errorMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('پروفایل با موفقیت به‌روزرسانی شد')),
      );
      _presenter.loadProfile(); // Reload applied jobs
    }
  }

  @override
  void onAvatarUploaded(String avatarUrl) {
    if (mounted && _user != null) {
      setState(() {
        _user = _user!.copyWith(avatarUrl: avatarUrl);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عکس پروفایل با موفقیت آپلود شد')),
      );
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
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        actions: [
          if (_user != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editProfile(),
              tooltip: 'ویرایش پروفایل',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Future<void> _editProfile() async {
    if (_user == null) return;
    
    final updatedUser = await Navigator.of(context).push<User>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          user: _user!,
          onSave: (updated) async {
            await _presenter.updateProfile(updated);
            return _user!;
          },
        ),
      ),
    );
    
    if (updatedUser != null && mounted) {
      setState(() => _user = updatedUser);
    }
  }

  Future<void> _uploadAvatar(File image) async {
    await _presenter.uploadAvatar(image);
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
    return RefreshIndicator(
      onRefresh: () => _presenter.loadProfile(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _ProfileHeader(
            user: user,
            onAvatarPicked: _uploadAvatar,
          ),
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
            onPressed: () => _showLogoutDialog(),
            icon: const Icon(Icons.logout),
            label: const Text(AppStrings.logout),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خروج از حساب'),
        content: const Text('آیا از خروج خود اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _presenter.logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User user;
  final Function(File) onAvatarPicked;

  const _ProfileHeader({
    required this.user,
    required this.onAvatarPicked,
  });

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
            AvatarWidget(
              avatarUrl: user.avatarUrl,
              initials: user.initials,
              isEditable: true,
              onImagePicked: onAvatarPicked,
              radius: 45,
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
              _InfoRow(icon: Icons.location_city_outlined, value: user.city!),
            if (user.province != null)
              _InfoRow(icon: Icons.location_on_outlined, value: user.province!),
            if (user.birthDate != null)
              _InfoRow(icon: Icons.cake_outlined, value: user.birthDate!),
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
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      user: user,
                      onSave: (updated) async {
                        // This will be handled by parent
                        return updated;
                      },
                    ),
                  ),
                ).then((result) {
                  if (result != null && context.mounted) {
                    // Trigger refresh
                    (context.findAncestorStateOfType<_ProfileScreenState>()
                        ?._presenter
                        .updateProfile(result as User));
                  }
                });
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('ویرایش اطلاعات'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
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