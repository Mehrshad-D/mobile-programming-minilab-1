import 'package:flutter/material.dart';
import '../models/feedback.dart';
import '../presenters/utility_presenter.dart';
import '../services/mock_api_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_widget.dart';

class ViolationReportScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const ViolationReportScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<ViolationReportScreen> createState() => _ViolationReportScreenState();
}

class _ViolationReportScreenState extends State<ViolationReportScreen>
    implements UtilityView {
  late final UtilityPresenter _presenter;
  
  List<ViolationReason> _reasons = [];
  String? _selectedReasonId;
  final _additionalInfoController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _presenter = UtilityPresenter(this, MockApiService());
    _presenter.loadViolationReasons();
  }

  @override
  void dispose() {
    _additionalInfoController.dispose();
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
  void onViolationReasonsLoaded(List<ViolationReason> reasons) {
    if (mounted) {
      setState(() {
        _reasons = reasons;
        _isLoading = false;
      });
    }
  }

  @override
  void onViolationReported() {
    if (mounted) {
      setState(() => _submitted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('گزارش تخلف شما با موفقیت ثبت شد'),
          backgroundColor: AppColors.success,
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  void onFeedbackSubmitted(FeedbackResult result) {}
  
  @override
  void onContactSubmitted(FeedbackResult result) {}
  
  @override
  void onEmailValidated(EmailValidationResult result) {}

  void _submitReport() {
    if (_selectedReasonId == null) {
      _showError('لطفاً دلیل گزارش را انتخاب کنید');
      return;
    }

    final report = ViolationReport(
      jobId: widget.jobId,
      reasonId: _selectedReasonId!,
      additionalInfo: _additionalInfoController.text.trim().isNotEmpty
          ? _additionalInfoController.text.trim()
          : null,
    );
    
    _presenter.reportViolation(report);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('گزارش تخلف'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_submitted) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: AppColors.success),
            SizedBox(height: AppSpacing.md),
            Text(
              'گزارش تخلف شما ثبت شد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'از کمک شما در بهبود کیفیت آگهی‌ها سپاسگزاریم',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'آگهی مورد نظر',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(widget.jobTitle),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          const Text(
            'دلیل گزارش',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          
          ..._reasons.map((reason) => RadioListTile<String>(
            title: Text(reason.title),
            subtitle: Text(reason.description, style: const TextStyle(fontSize: 12)),
            value: reason.id,
            groupValue: _selectedReasonId,
            onChanged: (value) => setState(() => _selectedReasonId = value),
            activeColor: AppColors.primary,
          )),
          
          const SizedBox(height: AppSpacing.md),
          
          const Text(
            'توضیحات تکمیلی (اختیاری)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _additionalInfoController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'توضیحات بیشتر را وارد کنید...',
            ),
            maxLines: 4,
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          
            SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: _submitReport,
                style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: const Text('ثبت گزارش'),
            ),
            ),
        ],
      ),
    );
  }
}