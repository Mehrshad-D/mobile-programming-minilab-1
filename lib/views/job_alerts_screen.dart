import 'package:flutter/material.dart';
import '../models/job_alert.dart';
import '../models/job_filters.dart';
import '../presenters/job_alert_presenter.dart';
import '../services/mock_api_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import 'create_alert_screen.dart';
import '../models/api_response.dart';

class JobAlertsScreen extends StatefulWidget {
  const JobAlertsScreen({super.key});

  @override
  State<JobAlertsScreen> createState() => _JobAlertsScreenState();
}

class _JobAlertsScreenState extends State<JobAlertsScreen>
    implements JobAlertsView {
  late final JobAlertPresenter _presenter;

  List<JobAlert> _alerts = [];
  AlertMeta? _meta;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  BuildContext getContext() => context;

  @override
  void initState() {
    super.initState();
    _presenter = JobAlertPresenter(this, MockApiService());
    _presenter.loadAlerts();
    _presenter.loadAlertMeta();
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
  void showAlerts(List<JobAlert> alerts) {
    if (mounted) {
      setState(() {
        _alerts = alerts;
        _errorMessage = null;
      });
    }
  }

  @override
  void showAlertMeta(AlertMeta meta) {
    if (mounted) setState(() => _meta = meta);
  }

  @override
  void onAlertCreated(JobAlert alert) {
    if (mounted) {
      setState(() => _alerts.add(alert));
    }
  }

  @override
  void onAlertDeleted(String alertId) {
    if (mounted) {
      setState(() => _alerts.removeWhere((a) => a.id == alertId));
    }
  }

  @override
  void onAlertUpdated(JobAlert alert) {
    if (mounted) {
      final index = _alerts.indexWhere((a) => a.id == alert.id);
      if (index != -1) {
        setState(() => _alerts[index] = alert);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('هشدارهای شغلی'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewAlert,
            tooltip: 'ایجاد هشدار جدید',
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
        onRetry: _presenter.loadAlerts,
      );
    }

    if (_alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_none,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'هیچ هشدار شغلی فعالی ندارید',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'با ایجاد هشدار، جدیدترین فرصت‌های شغلی مرتبط را دریافت کنید',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _createNewAlert,
              icon: const Icon(Icons.add),
              label: const Text('ایجاد هشدار جدید'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _presenter.loadAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          final alert = _alerts[index];
          return _AlertCard(
            alert: alert,
            onToggle: (isActive) => _presenter.toggleAlert(alert.id, isActive),
            onDelete: () => _confirmDelete(alert),
            onEdit: () => _editAlert(alert),
          );
        },
      ),
    );
  }

  void _createNewAlert() async {
    if (_meta == null) return;

    final newAlert = await Navigator.of(context).push<JobAlert>(
      MaterialPageRoute(
        builder: (_) => CreateAlertScreen(meta: _meta!),
      ),
    );

    if (newAlert != null) {
      await _presenter.createAlert(newAlert);
    }
  }

  void _editAlert(JobAlert alert) async {
    if (_meta == null) return;

    final updatedAlert = await Navigator.of(context).push<JobAlert>(
      MaterialPageRoute(
        builder: (_) => CreateAlertScreen(meta: _meta!, existingAlert: alert),
      ),
    );

    if (updatedAlert != null) {
      await _presenter.updateAlert(alert.id, updatedAlert);
    }
  }

  void _confirmDelete(JobAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف هشدار'),
        content: Text('آیا از حذف هشدار "${alert.name}" اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _presenter.deleteAlert(alert.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final JobAlert alert;
  final Function(bool) onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _AlertCard({
    required this.alert,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    alert.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  value: alert.isActive,
                  onChanged: onToggle,
                  activeColor: AppColors.primary,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('ویرایش'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('حذف', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildFilterSummary(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(
                  icon: Icons.notifications,
                  label: alert.frequency.displayName,
                ),
                _buildInfoChip(
                  icon: Icons.search,
                  label: '${alert.matchCount} موقعیت جدید',
                ),
                if (alert.lastSentAt != null)
                  _buildInfoChip(
                    icon: Icons.history,
                    label: _formatDate(alert.lastSentAt!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSummary() {
    final filters = alert.filters;
    final parts = <String>[];

    if (filters.keywords.isNotEmpty) {
      parts.add('کلمات کلیدی: ${filters.keywords.take(2).join(', ')}');
    }
    if (filters.locations.isNotEmpty) {
      parts.add('مکان: ${filters.locations.take(2).join(', ')}');
    }
    if (filters.jobCategories.isNotEmpty) {
      parts.add('دسته: ${filters.jobCategories.take(2).join(', ')}');
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: parts.map((part) => Text(
        part,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      )).toList(),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}