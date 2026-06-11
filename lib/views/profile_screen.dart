import 'dart:io';
import 'package:flutter/material.dart';
import '../models/job.dart';
import '../models/resume.dart';
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
import 'resume_builder_screen.dart';
import 'applications_screen.dart';
import 'job_alerts_screen.dart';
import 'contact_screen.dart';
import 'feedback_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> implements ProfileView {
  late final ProfilePresenter _presenter;
  late final MockApiService _apiService;

  User? _user;
  List<Job> _appliedJobs = [];
  Resume? _resume;
  bool _isLoading = false;
  bool _isLoadingResume = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = MockApiService();
    _presenter = ProfilePresenter(this, _apiService);
    _presenter.loadProfile();
    _loadResume();
  }

  Future<void> _loadResume() async {
    setState(() => _isLoadingResume = true);
    try {
      final resume = await _apiService.getResume();
      if (mounted) {
        setState(() => _resume = resume);
      }
    } catch (e) {
      // Resume might not exist yet, that's fine
      if (mounted) {
        setState(() => _resume = null);
      }
    } finally {
      if (mounted) setState(() => _isLoadingResume = false);
    }
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
      _presenter.loadProfile();
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

  void _openResumeBuilder() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ResumeBuilderScreen()),
    );
    // Refresh resume after returning
    if (result == true) {
      await _loadResume();
    }
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
      onRefresh: () async {
        await _presenter.loadProfile();
        await _loadResume();
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _ProfileHeader(
            user: user,
            onAvatarPicked: _uploadAvatar,
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Resume Section
          _buildResumeSection(),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Applied Jobs Section
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


          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ApplicationsScreen()),
              );
            },
            icon: const Icon(Icons.send_outlined),
            label: const Text('درخواست‌های من'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const JobAlertsScreen()),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
            label: const Text('هشدارهای شغلی'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FeedbackScreen()),
              );
            },
            icon: const Icon(Icons.feedback_outlined),
            label: const Text('ارسال بازخورد'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ContactScreen()),
              );
            },
            icon: const Icon(Icons.contact_mail_outlined),
            label: const Text('تماس با ما'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          
          // Logout Button
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

  Widget _buildResumeSection() {
    if (_isLoadingResume) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_resume != null) {
      // Resume exists - show preview and edit button
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          side: const BorderSide(color: AppColors.primary, width: 1),
        ),
        child: InkWell(
          onTap: _openResumeBuilder,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radius),
                      ),
                      child: const Icon(
                        Icons.description,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'رزومه من',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'امتیاز تکمیل: ${_resume!.score}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppSpacing.radius),
                      ),
                      child: const Text(
                        'ویرایش',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Progress bar
                LinearProgressIndicator(
                  value: (_resume!.score / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  minHeight: 6,
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                // Quick stats
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _buildStatChip(
                      icon: Icons.school,
                      label: '${_resume!.education.length} تحصیلات',
                    ),
                    _buildStatChip(
                      icon: Icons.work,
                      label: '${_resume!.experiences.length} سابقه',
                    ),
                    _buildStatChip(
                      icon: Icons.language,
                      label: '${_resume!.languages.length} زبان',
                    ),
                    _buildStatChip(
                      icon: Icons.code,
                      label: '${_resume!.skills.length} مهارت',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // No resume - show create button
      return Card(
        child: InkWell(
          onTap: _openResumeBuilder,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'رزومه حرفه‌ای خود را بسازید',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'با تکمیل رزومه، شانس استخدام خود را افزایش دهید',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: _openResumeBuilder,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('ساخت رزومه'),
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
  }

  Widget _buildStatChip({required IconData icon, required String label}) {
    return Container(
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
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                        return updated;
                      },
                    ),
                  ),
                ).then((result) {
                  if (result != null && context.mounted) {
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