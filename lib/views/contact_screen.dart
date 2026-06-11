import 'package:flutter/material.dart';
import '../models/feedback.dart';
import '../presenters/utility_presenter.dart';
import '../services/mock_api_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_widget.dart';
import 'feedback_screen.dart';
import 'violation_report_screen.dart';
import 'job_detail_screen.dart';
import '../models/feedback.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> implements UtilityView {
    late final UtilityPresenter _presenter;

    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _subjectController = TextEditingController();
    final _messageController = TextEditingController();

    bool _isLoading = false;
    String? _errorMessage;
    FeedbackResult? _result;
    @override
    void onViolationReasonsLoaded(List<ViolationReason> reasons) {
    // Not used in this screen
    }

    @override
    void onViolationReported() {
    // Not used in this screen
    }
  @override
  void initState() {
    super.initState();
    _presenter = UtilityPresenter(this, MockApiService());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
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
  void onContactSubmitted(FeedbackResult result) {
    if (mounted) {
      setState(() => _result = result);
    }
  }

  @override
  void onFeedbackSubmitted(FeedbackResult result) {
    // Not used
  }

  @override
  void onEmailValidated(EmailValidationResult result) {
    // Not used
  }

  void _submitContact() {
    if (_nameController.text.trim().isEmpty) {
      _showError('لطفاً نام خود را وارد کنید');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showError('لطفاً ایمیل خود را وارد کنید');
      return;
    }
    if (_subjectController.text.trim().isEmpty) {
      _showError('لطفاً موضوع را وارد کنید');
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      _showError('لطفاً متن پیام را وارد کنید');
      return;
    }

    final contact = ContactRequest(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
    );
    
    _presenter.submitContact(contact);
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
        title: const Text('تماس با ما'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_result != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: AppColors.success),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'پیام شما با موفقیت ارسال شد',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'کد پیگیری: ${_result!.trackingCode ?? _result!.id}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('بازگشت'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radius),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(_errorMessage!)),
                ],
              ),
            ),
          if (_errorMessage != null) const SizedBox(height: AppSpacing.md),
          
          CustomTextField(
            label: 'نام و نام خانوادگی',
            controller: _nameController,
            hint: 'نام خود را وارد کنید',
          ),
          const SizedBox(height: AppSpacing.md),
          
          CustomTextField(
            label: 'ایمیل',
            controller: _emailController,
            hint: 'ایمیل خود را وارد کنید',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.md),
          
          CustomTextField(
            label: 'موضوع',
            controller: _subjectController,
            hint: 'موضوع پیام را وارد کنید',
          ),
          const SizedBox(height: AppSpacing.md),
          
          const Text(
            'پیام',
            style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
            controller: _messageController,
            decoration: const InputDecoration(
                hintText: 'متن پیام خود را بنویسید...',
                border: OutlineInputBorder(),
            ),
            maxLines: 6,
            ),
          const SizedBox(height: AppSpacing.xl),
          
            SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: _submitContact,
                style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: const Text('ارسال پیام'),
            ),
            ),
        ],
      ),
    );
  }
}