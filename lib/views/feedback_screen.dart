import 'package:flutter/material.dart';
import '../models/feedback.dart';
import '../presenters/utility_presenter.dart';
import '../services/mock_api_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_widget.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> implements UtilityView {
  late final UtilityPresenter _presenter;
  
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  int _rating = 0;
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
    _subjectController.dispose();
    _messageController.dispose();
    _emailController.dispose();
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
  void onFeedbackSubmitted(FeedbackResult result) {
    if (mounted) {
      setState(() => _result = result);
      _subjectController.clear();
      _messageController.clear();
      _emailController.clear();
      setState(() => _rating = 0);
    }
  }

  @override
  void onContactSubmitted(FeedbackResult result) {
    // Not used in this screen
  }

  @override
  void onEmailValidated(EmailValidationResult result) {
    // Not used in this screen
  }

  void _submitFeedback() {
    if (_subjectController.text.trim().isEmpty) {
      _showError('لطفاً موضوع را وارد کنید');
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      _showError('لطفاً متن بازخورد را وارد کنید');
      return;
    }

    final feedback = FeedbackRequest(
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
      rating: _rating > 0 ? _rating : null,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
    );
    
    _presenter.submitFeedback(feedback);
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
        title: const Text('ارسال بازخورد'),
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
                'بازخورد شما با موفقیت ارسال شد',
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
          
          // Rating
          const Text(
            'امتیاز شما به جابینجا',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () => setState(() => _rating = index + 1),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Subject
          CustomTextField(
            label: 'موضوع',
            controller: _subjectController,
            hint: 'موضوع بازخورد خود را وارد کنید',
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Message
        const Text(
        'متن بازخورد',
        style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
        controller: _messageController,
        decoration: const InputDecoration(
            hintText: 'بازخورد خود را بنویسید...',
            border: OutlineInputBorder(),
        ),
        maxLines: 5,
        ),
          const SizedBox(height: AppSpacing.md),
          
          // Email (optional)
          CustomTextField(
            label: 'ایمیل (اختیاری)',
            controller: _emailController,
            hint: 'برای دریافت پاسخ، ایمیل خود را وارد کنید',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.xl),
          
            SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: _submitFeedback,
                style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: const Text('ارسال بازخورد'),
            ),
            ),
        ],
      ),
    );
  }
}