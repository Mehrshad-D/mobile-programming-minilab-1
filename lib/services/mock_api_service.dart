import 'dart:io';
import 'dart:math';
import '../models/api_response.dart';
import '../models/auth_session.dart';
import '../models/company.dart';
import '../models/job.dart';
import '../models/job_category.dart';
import '../models/job_filters.dart';
import '../models/job_search_meta.dart';
import '../models/job_skill.dart';
import '../models/login_request.dart';
import '../models/login_result.dart';
import '../models/province.dart';
import '../models/signup_request.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../models/resume.dart';
import '../models/application.dart';
import '../models/job_alert.dart';
import '../models/feedback.dart';

/// In-app implementation of [ApiService].
///
/// It returns static seed data after a short artificial delay so the UI can
/// exercise loading/error states exactly as it would against a real backend.
/// Implemented as a singleton so the "logged-in" session and applied jobs
/// persist while navigating between screens.
class MockApiService implements ApiService {
  // Singleton instance
  static final MockApiService _instance = MockApiService._internal();
  
  factory MockApiService() => _instance;

  static const Duration _latency = Duration(milliseconds: 700);
  static const int _perPage = 4;

  User? _currentUser;
  final Set<String> _appliedJobIds = <String>{};

  /// In-memory cookie jar holding the active Sanctum session (section 5.3).
  AuthSession? _session;

  // Private constructor
  MockApiService._internal() {
    _loadPersistedUser();
  }

  Future<void> _loadPersistedUser() async {
    _currentUser = await StorageService.getCurrentUser();
    _session = await StorageService.getSession();
    if (_currentUser != null) {
      final userId = _currentUser!.id.toString();
      final jobIds = await StorageService.getAppliedJobs(userId);
      _appliedJobIds.addAll(jobIds);
      _resumes
        ..clear()
        ..addAll(await StorageService.getResumes(userId));
      _registerUsedSlugs();
      _activeResumeId = _resumes.isNotEmpty ? _resumes.first.id : null;
      await _loadApplicationsForCurrentUser();
      await _loadAlertsForCurrentUser();
    }
  }

  @override
  User? get currentUser => _currentUser;

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  /// GET /login/user — simulates loading the login page. Issues a fresh CSRF
  /// token (the `<meta name="csrf-token">` value) plus `JSESSID` and
  /// `XSRF-TOKEN` cookies, and stores them in the in-memory cookie jar.
  @override
  Future<AuthSession> getLoginPage() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final session = AuthSession(
      csrfToken: _randomToken(40),
      jsessid: _randomToken(32),
      xsrfToken: _randomToken(40),
    );
    _session = session;
    await StorageService.saveSession(session);
    return session;
  }

  /// POST /login/user — simulates the form-urlencoded login submission.
  ///
  /// Mirrors the Sanctum behaviour: the `_token` must match the CSRF token
  /// issued by [getLoginPage] (else 419), then credentials are checked. Returns
  /// a [LoginResult] modelling the 302 redirect rather than throwing on bad
  /// credentials, matching the spec (success → home, failure → /login/user).
  @override
  Future<LoginResult> submitLogin(LoginRequest request) async {
    await Future.delayed(_latency);

    // Cookie jar / CSRF validation: the session must exist and the submitted
    // `_token` must match the issued CSRF token.
    final session = _session;
    if (session == null || request.token != session.csrfToken) {
      throw ApiException(
        'نشست شما منقضی شده است. صفحه را تازه کرده و دوباره تلاش کنید.',
        statusCode: 419,
      );
    }

    // Credential check (identifier == email).
    final user = await StorageService.validateLogin(
      request.identifier,
      request.password,
    );
    if (user == null) {
      // 302 Redirect → /login/user
      return LoginResult.failure();
    }

    _currentUser = user;
    await StorageService.saveCurrentUser(user);

    // Load applied jobs and resume for this user.
    final jobIds = await StorageService.getAppliedJobs(user.id.toString());
    _appliedJobIds
      ..clear()
      ..addAll(jobIds);
    await _loadResumeForCurrentUser();
    await _loadApplicationsForCurrentUser();
    await _loadAlertsForCurrentUser();

    // 302 Redirect → homepage
    return LoginResult.success(user);
  }

  /// Generates a random URL-safe token, used for the CSRF token and cookies.
  String _randomToken(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }

@override
Future<User> signup(SignupRequest request) async {
  await Future.delayed(_latency);
  
  // Validate password is not empty
  if (request.password.isEmpty) {
    throw ApiException('رمز عبور نمی‌تواند خالی باشد', statusCode: 400);
  }
  
  // Create new user
  final newUser = User(
    id: DateTime.now().millisecondsSinceEpoch,
    name: request.name,
    email: request.email,
    phone: request.phone,
    city: 'تهران',
    headline: 'کارجوی تازه‌وارد',
  );
  
  // Register user with the actual password they provided
  final success = await StorageService.registerUser(
    request.email, 
    newUser, 
    request.password  // Store the actual password
  );
  
  if (!success) {
    throw ApiException('این ایمیل قبلاً ثبت نام کرده است', statusCode: 409);
  }
  
  _currentUser = newUser;
  _clearResumes();
  await StorageService.saveCurrentUser(newUser);
  
  return _currentUser!;
}

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _session = null;
    _clearResumes();
    _appliedJobIds.clear();
    _applications.clear();
    _jobAlerts.clear();
    await StorageService.clearCurrentUser();
    await StorageService.clearSession();
  }

  /// Loads the authenticated user's resume from persistent storage.
  Future<void> _loadResumeForCurrentUser() async {
    final user = _currentUser;
    if (user == null) {
      _clearResumes();
      return;
    }
    _resumes
      ..clear()
      ..addAll(await StorageService.getResumes(user.id.toString()));
    _registerUsedSlugs();
    _activeResumeId = _resumes.isNotEmpty ? _resumes.first.id : null;
  }

  // ---------------------------------------------------------------------------
  // Jobs
  // ---------------------------------------------------------------------------

  @override
  Future<User> getProfile() async {
    await Future.delayed(_latency);
    final user = _currentUser;
    if (user == null) {
      throw ApiException('برای مشاهده پروفایل ابتدا وارد شوید', statusCode: 401);
    }
    return user;
  }

  @override
  Future<User> updateProfile(User updatedUser) async {
    await Future.delayed(_latency);
    
    if (_currentUser == null) {
      throw ApiException('برای ویرایش پروفایل ابتدا وارد شوید', statusCode: 401);
    }
    
    _currentUser = updatedUser;
    await StorageService.saveCurrentUser(updatedUser);
    
    // Update in registered users list (password stays the same)
    await StorageService.updateRegisteredUser(updatedUser);
    
    return _currentUser!;
  }

  @override
  Future<String> uploadAvatar(File imageFile) async {
    await Future.delayed(_latency);
    
    if (_currentUser == null) {
      throw ApiException('برای آپلود عکس ابتدا وارد شوید', statusCode: 401);
    }
    
    // A real backend would store the file and return a hosted URL. The mock
    // can't serve files, so we keep the picked image's local path and let the
    // UI render it with Image.file — this way the actual photo is displayed.
    final avatarPath = imageFile.path;

    _currentUser = _currentUser!.copyWith(avatarUrl: avatarPath);
    await StorageService.saveCurrentUser(_currentUser!);

    return avatarPath;
  }

  @override
  Future<PaginatedResponse<Job>> getJobs(JobFilters filters) async {
    await Future.delayed(_latency);

    final matched = _jobs.where((job) => _matches(job, filters)).toList();
    _sort(matched, filters.sortBy);
    return _paginate(matched, filters.page);
  }

  /// Applies every section 5.1 filter. Within a facet values are OR-ed;
  /// across facets they are AND-ed.
  bool _matches(Job job, JobFilters f) {
    // filters[keywords][] -> matches title, company or category (OR).
    final keywords =
        f.keywords.map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
    if (keywords.isNotEmpty) {
      final hit = keywords.any((k) =>
          job.title.contains(k) ||
          job.company.name.contains(k) ||
          job.category.contains(k));
      if (!hit) return false;
    }

    // filters[locations][]
    if (f.locations.isNotEmpty &&
        !f.locations.contains(job.location.province)) {
      return false;
    }

    // filters[job_categories][]
    if (f.jobCategories.isNotEmpty &&
        !f.jobCategories.contains(job.category)) {
      return false;
    }

    // filters[job_types][]
    if (f.jobTypes.isNotEmpty && !f.jobTypes.contains(job.contractType)) {
      return false;
    }

    // filters[remote]
    if (f.remote && !job.isRemote) return false;

    // filters[internship]
    if (f.internship && !job.isInternship) return false;

    // filters[has_*] -> the job must offer every requested benefit (AND).
    if (f.benefits.isNotEmpty &&
        !f.benefits.every((b) => job.benefits.contains(b))) {
      return false;
    }

    // filters[sal_min][] -> negotiable (null amount) jobs are excluded.
    if (f.salaryMin != null) {
      final amount = job.salary.amount;
      if (amount == null || amount < f.salaryMin!) return false;
    }

    // filters[w_e][]
    if (f.workExperiences.isNotEmpty &&
        !f.workExperiences.contains(job.experienceLevel)) {
      return false;
    }

    return true;
  }

  /// Implements the `sort_by` parameter.
  void _sort(List<Job> jobs, JobSort sortBy) {
    switch (sortBy) {
      case JobSort.salaryDesc:
        // Negotiable jobs (null amount) sink to the bottom.
        jobs.sort((a, b) {
          final sa = a.salary.amount ?? -1;
          final sb = b.salary.amount ?? -1;
          return sb.compareTo(sa);
        });
      case JobSort.publishedAtDesc:
        jobs.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    }
  }

  @override
  Future<Job> getJobById(String id) async {
    await Future.delayed(_latency);
    final matches = _jobs.where((j) => j.id == id).toList();
    if (matches.isEmpty) {
      throw ApiException('شغل مورد نظر یافت نشد', statusCode: 404);
    }
    return matches.first;
  }

  @override
  Future<Company> getCompanyBySlug(String slug) async {
    await Future.delayed(_latency);
    final matches = _companies.where((c) => c.slug == slug).toList();
    if (matches.isEmpty) {
      throw ApiException('شرکت مورد نظر یافت نشد', statusCode: 404);
    }
    return matches.first;
  }

  @override
  Future<PaginatedResponse<Job>> getCompanyJobs(
    String companyIdOrSlug, {
    int page = 1,
  }) async {
    await Future.delayed(_latency);
    _requireLogin();
    final company = _companyByIdOrSlug(companyIdOrSlug);
    final companyJobs =
        _jobs.where((j) => j.company.id == company.id).toList();
    _sort(companyJobs, JobSort.publishedAtDesc);
    return _paginate(companyJobs, page);
  }

  /// Resolves a company by id (section 5.6 `{company_id}`) or by slug (legacy UI
  /// calls). Throws 404 when neither matches.
  Company _companyByIdOrSlug(String idOrSlug) {
    final matches = _companies
        .where((c) => c.id == idOrSlug || c.slug == idOrSlug)
        .toList();
    if (matches.isEmpty) {
      throw const ApiException('شرکت مورد نظر یافت نشد', statusCode: 404);
    }
    return matches.first;
  }

  // ---------------------------------------------------------------------------
  // Applied Jobs with persistence
  // ---------------------------------------------------------------------------
  @override
  Future<List<Job>> getAppliedJobs() async {
    await Future.delayed(_latency);
    if (_currentUser == null) return [];
    return _jobs.where((j) => _appliedJobIds.contains(j.id)).toList();
  }

  // ---------------------------------------------------------------------------
  // Reference data
  // ---------------------------------------------------------------------------

  @override
  Future<List<String>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Derived from the rich category list so there is a single source of truth.
    return _jobCategories.map((c) => c.name).toList();
  }

  @override
  Future<List<String>> getLocations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const ['تهران', 'اصفهان', 'شیراز', 'مشهد', 'البرز'];
  }

  @override
  Future<List<String>> getJobTypes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const ['تمام‌وقت', 'پاره‌وقت', 'کارآموزی'];
  }

  @override
  Future<List<String>> getWorkExperiences() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      'بدون نیاز به سابقه',
      'کمتر از سه سال',
      'دو تا چهار سال',
      'بیش از سه سال',
    ];
  }

  @override
  Future<List<({String label, int value})>> getSalaryRanges() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      (label: 'از ۲۰ میلیون تومان', value: 20000000),
      (label: 'از ۳۰ میلیون تومان', value: 30000000),
      (label: 'از ۴۰ میلیون تومان', value: 40000000),
      (label: 'از ۵۰ میلیون تومان', value: 50000000),
      (label: 'از ۶۰ میلیون تومان', value: 60000000),
    ];
  }

  @override
  Future<List<({String key, String label})>> getBenefits() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      (key: JobBenefit.usd, label: 'پرداخت دلاری'),
      (key: JobBenefit.supplementaryInsurance, label: 'بیمه تکمیلی'),
      (key: JobBenefit.flexibleHours, label: 'ساعت کاری شناور'),
      (key: JobBenefit.loan, label: 'وام'),
      (key: JobBenefit.bonus, label: 'پاداش'),
      (key: JobBenefit.commission, label: 'پورسانت'),
      (key: JobBenefit.esop, label: 'سهام تشویقی'),
      (key: JobBenefit.project, label: 'پروژه‌ای'),
      (key: JobBenefit.promotion, label: 'ترفیع شغلی'),
      (key: JobBenefit.overtimeOffering, label: 'اضافه‌کاری'),
      (key: JobBenefit.afternoonShift, label: 'شیفت عصر'),
      (key: JobBenefit.partTime, label: 'پاره‌وقت'),
      (key: JobBenefit.businessTrip, label: 'سفر کاری'),
      (key: JobBenefit.militaryPlacement, label: 'امریه سربازی'),
      (key: JobBenefit.disabilitySupport, label: 'استخدام معلولین'),
    ];
  }

  // ---------------------------------------------------------------------------
  // Section 5.7: Job Alerts
  // ---------------------------------------------------------------------------

  /// Working set of the *authenticated* user's alerts. Loaded on login and
  /// cleared on logout so users never see each other's alerts.
  final List<JobAlert> _jobAlerts = [];

  static const int _maxJobAlerts = 20;

  Future<void> _persistAlerts() async {
    final user = _currentUser;
    if (user == null) return;
    await StorageService.saveJobAlerts(user.id.toString(), _jobAlerts);
  }

  Future<void> _loadAlertsForCurrentUser() async {
    _jobAlerts.clear();
    final user = _currentUser;
    if (user == null) return;
    _jobAlerts.addAll(await StorageService.getJobAlerts(user.id.toString()));
  }

  @override
  Future<List<JobAlert>> getJobAlerts() async {
    await Future.delayed(_latency);
    _requireLogin();
    return List.unmodifiable(_jobAlerts);
  }

  @override
  Future<JobAlert> createJobAlert(JobAlert alert) async {
    await Future.delayed(_latency);
    _requireLogin();

    final name = alert.name.trim();
    if (name.isEmpty) {
      throw const ApiException('نام هشدار نمی‌تواند خالی باشد', statusCode: 422);
    }

    // Duplicate prevention: same (case-insensitive) name already exists.
    final isDuplicate = _jobAlerts.any(
      (a) => a.name.trim().toLowerCase() == name.toLowerCase(),
    );
    if (isDuplicate) {
      throw const ApiException(
        'هشداری با این نام قبلاً ایجاد شده است',
        statusCode: 409,
      );
    }

    if (_jobAlerts.length >= _maxJobAlerts) {
      throw const ApiException(
        'به حداکثر تعداد هشدارهای مجاز رسیده‌اید',
        statusCode: 422,
      );
    }

    final filters = alert.filters.copyWith(page: 1);
    final matchedJobs = _jobs.where((job) => _matches(job, filters)).toList();

    final newAlert = JobAlert(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      filters: filters,
      frequency: alert.frequency,
      isActive: true,
      createdAt: DateTime.now(),
      matchCount: matchedJobs.length,
    );

    _jobAlerts.add(newAlert);
    await _persistAlerts();
    return newAlert;
  }

  @override
  Future<void> deleteJobAlert(String alertId) async {
    await Future.delayed(_latency);
    _requireLogin();

    final before = _jobAlerts.length;
    _jobAlerts.removeWhere((alert) => alert.id == alertId);
    if (_jobAlerts.length == before) {
      throw const ApiException('هشدار مورد نظر یافت نشد', statusCode: 404);
    }
    await _persistAlerts();
  }

  @override
  Future<AlertMeta> getJobAlertMeta() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _requireLogin();

    final categories = _jobs.map((j) => j.category).toSet().toList();
    final locations = _jobs.map((j) => j.location.province).toSet().toList();
    final jobTypes = _jobs.map((j) => j.contractType).toSet().toList();
    final experiences = _jobs.map((j) => j.experienceLevel).toSet().toList();

    return AlertMeta(
      frequencies: const ['instantly', 'daily', 'weekly', 'biweekly'],
      jobCategories: categories,
      locations: locations,
      jobTypes: jobTypes,
      workExperiences: experiences,
    );
  }

  @override
  Future<JobAlert> updateJobAlert(String alertId, JobAlert alert) async {
    await Future.delayed(_latency);
    _requireLogin();

    final index = _jobAlerts.indexWhere((a) => a.id == alertId);
    if (index == -1) {
      throw const ApiException('هشدار مورد نظر یافت نشد', statusCode: 404);
    }

    final name = alert.name.trim();
    if (name.isEmpty) {
      throw const ApiException('نام هشدار نمی‌تواند خالی باشد', statusCode: 422);
    }

    // Duplicate name against *other* alerts.
    final isDuplicate = _jobAlerts.any(
      (a) =>
          a.id != alertId &&
          a.name.trim().toLowerCase() == name.toLowerCase(),
    );
    if (isDuplicate) {
      throw const ApiException(
        'هشداری با این نام قبلاً ایجاد شده است',
        statusCode: 409,
      );
    }

    final matchedJobs =
        _jobs.where((job) => _matches(job, alert.filters)).toList();

    final updatedAlert = alert.copyWith(
      id: alertId,
      name: name,
      createdAt: _jobAlerts[index].createdAt,
      matchCount: matchedJobs.length,
    );

    _jobAlerts[index] = updatedAlert;
    await _persistAlerts();
    return updatedAlert;
  }

  @override
  Future<void> toggleJobAlert(String alertId, bool isActive) async {
    await Future.delayed(_latency);
    _requireLogin();

    final index = _jobAlerts.indexWhere((a) => a.id == alertId);
    if (index == -1) {
      throw const ApiException('هشدار مورد نظر یافت نشد', statusCode: 404);
    }

    _jobAlerts[index] = _jobAlerts[index].copyWith(isActive: isActive);
    await _persistAlerts();
  }
  
  // ---------------------------------------------------------------------------
  // Section 5.8: Utility
  // ---------------------------------------------------------------------------

  final List<FeedbackResult> _feedbacks = [];
  final List<DeviceRegistration> _devices = [];
  final Set<String> _seenNotifications = {};
  final List<ViolationReport> _violationReports = [];
  bool _allNotificationsSeen = false;
  String? _notificationCookie;

  // Read-only diagnostics (not part of [ApiService]) used by tests/UI.
  bool get allNotificationsSeen => _allNotificationsSeen;
  String? get notificationCookie => _notificationCookie;
  List<ViolationReport> get violationReports =>
      List.unmodifiable(_violationReports);
  int get registeredDeviceCount => _devices.length;

  @override
  Future<EmailValidationResult> checkEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simple email validation regex
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    final isValid = emailRegex.hasMatch(email);
    
    String? domain;
    if (isValid) {
      domain = email.split('@').last;
    }
    
    // Check for common disposable email domains
    final disposableDomains = ['tempmail.com', '10minutemail.com', 'guerrillamail.com'];
    final isDisposable = disposableDomains.contains(domain);
    
    return EmailValidationResult(
      isValid: isValid,
      message: isValid ? 'ایمیل معتبر است' : 'فرمت ایمیل صحیح نیست',
      domain: domain,
      isDisposable: isDisposable,
    );
  }

  @override
  Future<FeedbackResult> submitFeedback(FeedbackRequest feedback) async {
    await Future.delayed(_latency);
    
    if (_currentUser == null && feedback.email == null) {
      throw ApiException('برای ارسال بازخورد، لطفاً ایمیل خود را وارد کنید', statusCode: 400);
    }

    if (feedback.subject.trim().isEmpty || feedback.message.trim().isEmpty) {
      throw const ApiException(
        'موضوع و متن بازخورد الزامی است',
        statusCode: 422,
      );
    }
    
    final result = FeedbackResult(
      id: 'fb_${DateTime.now().millisecondsSinceEpoch}',
      status: 'received',
      submittedAt: DateTime.now(),
      trackingCode: 'TRK${DateTime.now().millisecondsSinceEpoch}',
    );
    
    _feedbacks.add(result);
    return result;
  }

  @override
  Future<FeedbackResult> submitContact(ContactRequest contact) async {
    await Future.delayed(_latency);
    
    if (contact.name.trim().isEmpty ||
        contact.email.trim().isEmpty ||
        contact.message.trim().isEmpty) {
      throw const ApiException('لطفاً تمام فیلدهای ضروری را پر کنید', statusCode: 400);
    }

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(contact.email.trim())) {
      throw const ApiException('فرمت ایمیل صحیح نیست', statusCode: 422);
    }
    
    final result = FeedbackResult(
      id: 'ct_${DateTime.now().millisecondsSinceEpoch}',
      status: 'sent',
      submittedAt: DateTime.now(),
      trackingCode: 'CTK${DateTime.now().millisecondsSinceEpoch}',
    );
    
    _feedbacks.add(result);
    return result;
  }

  @override
  Future<FeedbackResult> getFeedbackResult(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final result = _feedbacks.firstWhere(
      (f) => f.id == id,
      orElse: () => throw ApiException('بازخورد مورد نظر یافت نشد', statusCode: 404),
    );
    
    return result;
  }

  @override
  Future<void> registerDevice(DeviceRegistration device) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Remove existing device with same ID
    _devices.removeWhere((d) => d.deviceId == device.deviceId);
    _devices.add(device);
  }

  @override
  Future<void> registerFCMDevice(String fcmToken) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (fcmToken.trim().isEmpty) {
      throw const ApiException('توکن FCM نامعتبر است', statusCode: 422);
    }

    // Deduplicate by token so the same device isn't registered twice.
    final existingIndex =
        _devices.indexWhere((d) => d.fcmToken == fcmToken);
    if (existingIndex != -1) {
      return;
    }

    final deviceId = 'web_${DateTime.now().millisecondsSinceEpoch}';
    _devices.add(
      DeviceRegistration(
        deviceId: deviceId,
        fcmToken: fcmToken,
        platform: 'web',
      ),
    );
  }

  @override
  Future<List<ViolationReason>> getViolationReasons() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return const [
      ViolationReason(
        id: '1',
        title: 'اطلاعات نادرست',
        description: 'آگهی حاوی اطلاعات نادرست یا گمراه‌کننده است',
      ),
      ViolationReason(
        id: '2',
        title: 'محتوای نامناسب',
        description: 'آگهی حاوی محتوای توهین‌آمیز یا نامناسب است',
      ),
      ViolationReason(
        id: '3',
        title: 'کلاهبرداری',
        description: 'این آگهی مشکوک به کلاهبرداری است',
      ),
      ViolationReason(
        id: '4',
        title: 'تکراری',
        description: 'این آگهی چندین بار منتشر شده است',
      ),
      ViolationReason(
        id: '5',
        title: 'آگهی غیرمرتبط',
        description: 'آگهی در دسته‌بندی اشتباه قرار گرفته است',
      ),
    ];
  }

  @override
  Future<void> reportViolation(ViolationReport report) async {
    await Future.delayed(_latency);
    _requireLogin();

    // Verify job exists.
    final jobMatches = _jobs.where((j) => j.id == report.jobId).toList();
    if (jobMatches.isEmpty) {
      throw const ApiException('آگهی مورد نظر یافت نشد', statusCode: 404);
    }

    // Verify the reported reason is one of the allowed reasons.
    const allowedReasonIds = {'1', '2', '3', '4', '5'};
    if (!allowedReasonIds.contains(report.reasonId)) {
      throw const ApiException('دلیل گزارش نامعتبر است', statusCode: 422);
    }

    _violationReports.add(report);
  }

  @override
  Future<void> markNotificationAsSeen(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _requireLogin();
    _seenNotifications.add(notificationId);
  }

  @override
  Future<void> markAllNotificationsAsSeen() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _requireLogin();
    _allNotificationsSeen = true;
  }

  /// `POST /api/v10/doc-notification-cookie/` — stores the notification consent
  /// cookie for the current session. Public (set before/around auth).
  @override
  Future<void> storeNotificationCookie(String cookie) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (cookie.trim().isEmpty) {
      throw const ApiException('مقدار کوکی نامعتبر است', statusCode: 422);
    }
    _notificationCookie = cookie;
  }


  // ---------------------------------------------------------------------------
  // Section 5.2: Meta / Reference data
  // ---------------------------------------------------------------------------

  /// GET /api/v10/job/categories
  @override
  Future<List<JobCategory>> getJobCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_jobCategories);
  }

  /// GET /api/v10/job_search_meta — facet lists with job counts.
  @override
  Future<JobSearchMeta> getJobSearchMeta() async {
    await Future.delayed(_latency);
    return JobSearchMeta(
      jobCategories: _countBy(_jobs.map((j) => j.category)),
      companyCategories: _countBy(_jobs.map((j) => j.company.industry)),
      locations: _countBy(_jobs.map((j) => j.location.province)),
      companySizes:
          _countBy(_jobs.map((j) => _sizeBucket(j.company.employeeCount))),
      total: _jobs.length,
    );
  }

  /// GET /api/v10/region/province
  @override
  Future<List<Province>> getProvinces() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_provinces);
  }

  /// GET /api/v10/job-skills/search?q={query}
  @override
  Future<List<JobSkill>> searchSkills(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List.unmodifiable(_skills);
    return _skills
        .where((skill) => skill.name.toLowerCase().contains(q))
        .toList();
  }

  /// GET /api/v10/utils/last-applied-job — needs authentication (cookies).
  @override
  Future<Job?> getLastAppliedJob() async {
    await Future.delayed(_latency);
    if (_currentUser == null) {
      throw ApiException(
        'برای مشاهده آخرین درخواست ابتدا وارد شوید',
        statusCode: 401,
      );
    }
    if (_appliedJobIds.isEmpty) return null;
    final lastId = _appliedJobIds.last;
    return _jobs.firstWhere((j) => j.id == lastId);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Groups values and counts occurrences, for the search-meta facets.
  List<MetaFacet> _countBy(Iterable<String> values) {
    final counts = <String, int>{};
    for (final value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    return counts.entries
        .map((e) => MetaFacet(name: e.key, count: e.value))
        .toList();
  }

  String _sizeBucket(int? employeeCount) {
    if (employeeCount == null) return 'نامشخص';
    if (employeeCount <= 50) return '۱ تا ۵۰ نفر';
    if (employeeCount <= 200) return '۵۱ تا ۲۰۰ نفر';
    return 'بیش از ۲۰۰ نفر';
  }

  PaginatedResponse<Job> _paginate(List<Job> source, int page) {
    final total = source.length;
    final lastPage = total == 0 ? 1 : (total / _perPage).ceil();
    final safePage = page.clamp(1, lastPage);
    final start = (safePage - 1) * _perPage;
    final end = (start + _perPage).clamp(0, total);
    final pageItems = start >= total ? <Job>[] : source.sublist(start, end);

    return PaginatedResponse<Job>(
      data: pageItems,
      meta: PageMeta(
        currentPage: safePage,
        lastPage: lastPage,
        perPage: _perPage,
        total: total,
      ),
    );
  }


  // ---------------------------------------------------------------------------
  // Section 5.5: Applications
  // ---------------------------------------------------------------------------

  /// Working set of the *authenticated* user's applications (keyed by app id).
  /// Loaded on login and cleared on logout so users never see each other's data.
  final Map<String, JobApplication> _applications = {};

  /// Session-global owner registry (appId -> userId). Lets us return 403 for an
  /// application that exists but belongs to someone else, vs 404 for unknown ids.
  final Map<String, String> _applicationOwners = {};

  static const int _maxCoverLetterChars = 5000;
  static const int _maxCoverLetterFileBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> _coverLetterFileExtensions = ['pdf', 'doc', 'docx'];

  /// Auth + ownership gate shared by every application endpoint.
  /// Throws 401 (not logged in), 403 (foreign application) or 404 (unknown id).
  JobApplication _ownedApplication(String applicationId) {
    _requireLogin();
    final app = _applications[applicationId];
    if (app != null) return app;
    if (_applicationOwners.containsKey(applicationId)) {
      throw const ApiException(
        'دسترسی به این درخواست مجاز نیست',
        statusCode: 403,
      );
    }
    throw const ApiException('درخواست مورد نظر یافت نشد', statusCode: 404);
  }

  Future<void> _persistApplications() async {
    final user = _currentUser;
    if (user == null) return;
    await StorageService.saveApplications(
      user.id.toString(),
      _applications.values.toList(),
    );
  }

  /// Loads the authenticated user's applications from storage into the working
  /// set and registers ownership. Called on login and on cold start.
  Future<void> _loadApplicationsForCurrentUser() async {
    _applications.clear();
    final user = _currentUser;
    if (user == null) return;
    final userId = user.id.toString();
    final apps = await StorageService.getApplications(userId);
    for (final app in apps) {
      _applications[app.id] = app;
      _applicationOwners[app.id] = userId;
    }
  }

  String _validateCoverLetterContent(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const ApiException(
        'متن کاورلتر نمی‌تواند خالی باشد',
        statusCode: 422,
      );
    }
    if (trimmed.length > _maxCoverLetterChars) {
      throw const ApiException(
        'متن کاورلتر بیش از حد مجاز است',
        statusCode: 422,
      );
    }
    return trimmed;
  }

  @override
  Future<List<JobApplication>> getApplications() async {
    await Future.delayed(_latency);
    _requireLogin();
    final apps = _applications.values.toList()
      ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
    return apps;
  }

  @override
  Future<JobApplication> getApplicationDetail(String applicationId) async {
    await Future.delayed(_latency);
    return _ownedApplication(applicationId);
  }

  @override
  Future<JobApplication> uploadCoverLetter(
    String applicationId,
    String content,
  ) async {
    await Future.delayed(_latency);
    final app = _ownedApplication(applicationId);
    final clean = _validateCoverLetterContent(content);

    final existing = app.coverLetter;
    final coverLetter = CoverLetter(
      id: existing?.id ?? 'cl_${DateTime.now().millisecondsSinceEpoch}',
      content: clean,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: existing != null ? DateTime.now() : null,
      fileUrl: existing?.fileUrl,
    );

    final updatedApp = app.copyWith(coverLetter: coverLetter);
    _applications[applicationId] = updatedApp;
    await _persistApplications();
    return updatedApp;
  }

  @override
  Future<JobApplication> updateCoverLetter(
    String applicationId,
    String content,
  ) async {
    await Future.delayed(_latency);
    final app = _ownedApplication(applicationId);
    final existing = app.coverLetter;
    if (existing == null) {
      throw const ApiException(
        'کاورلتری برای ویرایش وجود ندارد',
        statusCode: 404,
      );
    }
    final clean = _validateCoverLetterContent(content);

    final coverLetter = CoverLetter(
      id: existing.id,
      content: clean,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      fileUrl: existing.fileUrl,
    );

    final updatedApp = app.copyWith(coverLetter: coverLetter);
    _applications[applicationId] = updatedApp;
    await _persistApplications();
    return updatedApp;
  }

  @override
  Future<JobApplication> uploadCoverLetterFile(
    String applicationId,
    File file,
  ) async {
    await Future.delayed(_latency);
    final app = _ownedApplication(applicationId);
    await _validateUpload(
      file,
      allowedExtensions: _coverLetterFileExtensions,
      maxBytes: _maxCoverLetterFileBytes,
    );

    final ext = file.path.split('.').last.toLowerCase();
    final fileUrl =
        'https://cdn.jobinja.mock/cover-letters/$applicationId-${DateTime.now().millisecondsSinceEpoch}.$ext';

    final existing = app.coverLetter;
    final coverLetter = CoverLetter(
      id: existing?.id ?? 'cl_${DateTime.now().millisecondsSinceEpoch}',
      content: existing?.content ?? '',
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: existing != null ? DateTime.now() : null,
      fileUrl: fileUrl,
    );

    final updatedApp = app.copyWith(coverLetter: coverLetter);
    _applications[applicationId] = updatedApp;
    await _persistApplications();
    return updatedApp;
  }

  @override
  Future<void> cancelApplication(String applicationId) async {
    await Future.delayed(_latency);
    final app = _ownedApplication(applicationId);

    // Idempotent: cancelling an already-cancelled application is a no-op.
    if (app.status == ApplicationStatus.cancelled) return;

    // Only submitted/under-review applications can be cancelled.
    if (app.status != ApplicationStatus.pending &&
        app.status != ApplicationStatus.reviewing) {
      throw const ApiException(
        'این درخواست در وضعیت فعلی قابل لغو نیست',
        statusCode: 422,
      );
    }

    _applications[applicationId] =
        app.copyWith(status: ApplicationStatus.cancelled);

    // A cancelled application is no longer an active applied job.
    _appliedJobIds.remove(app.job.id);
    await StorageService.saveAppliedJobs(
      _currentUser!.id.toString(),
      _appliedJobIds.toList(),
    );
    await _persistApplications();
  }

  // ---------------------------------------------------------------------------
  // Section 5.6: Companies (Enhanced)
  // ---------------------------------------------------------------------------

  final Set<String> _followedCompanyIds = {};

  @override
  Future<Company> getCompanyDetail(String slug) async {
    await Future.delayed(_latency);
    
    final matches = _companies.where((c) => c.slug == slug).toList();
    if (matches.isEmpty) {
      throw ApiException('شرکت مورد نظر یافت نشد', statusCode: 404);
    }
    
    final company = matches.first;
    final isFollowed = _followedCompanyIds.contains(company.id);
    
    return Company(
      id: company.id,
      name: company.name,
      slug: company.slug,
      industry: company.industry,
      city: company.city,
      employeeCount: company.employeeCount,
      about: company.about,
      logoUrl: company.logoUrl,
      isFollowed: isFollowed,
      followersCount: company.followersCount + (_followedCompanyIds.contains(company.id) ? 1 : 0),
      rating: company.rating ?? 4.5,
      website: company.website ?? 'www.${company.slug}.com',
      email: company.email ?? 'info@${company.slug}.com',
      phone: company.phone ?? '۰۲۱-۱۲۳۴۵۶۷۸',
    );
  }

  @override
  Future<Map<String, dynamic>> getCompanyApplyData(
    String companyId,
    String jobId,
  ) async {
    await Future.delayed(_latency);
    _requireLogin();

    final company = _companyByIdOrSlug(companyId);
    final jobMatches = _jobs
        .where((j) => j.id == jobId && j.company.id == company.id)
        .toList();
    if (jobMatches.isEmpty) {
      throw const ApiException(
        'آگهی مورد نظر برای این شرکت یافت نشد',
        statusCode: 404,
      );
    }
    final job = jobMatches.first;

    final alreadyApplied = _appliedJobIds.contains(job.id);
    final hasResume = _currentResume != null;

    return {
      'job_id': job.id,
      'job_title': job.title,
      'company_id': company.id,
      'company_name': company.name,
      'required_fields': const ['resume', 'cover_letter'],
      'resume_required': true,
      'cover_letter_required': false,
      'already_applied': alreadyApplied,
      'has_resume': hasResume,
      'can_apply': job.isPublished && !alreadyApplied && hasResume,
      'deadline':
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    };
  }

  @override
  Future<Job> getCompanyJobBySlug(String companySlug, String jobSlug) async {
    await Future.delayed(_latency);
    _requireLogin();

    final company = _companyByIdOrSlug(companySlug);
    final matches = _jobs
        .where((j) => j.company.id == company.id && j.slug == jobSlug)
        .toList();
    if (matches.isEmpty) {
      throw const ApiException('آگهی مورد نظر یافت نشد', statusCode: 404);
    }
    final job = matches.first;

    // Visibility: private/unpublished postings are not exposed publicly.
    if (!job.isPublished) {
      throw const ApiException(
        'این آگهی در دسترس عموم نیست',
        statusCode: 403,
      );
    }
    return job;
  }

  @override
  Future<Company> followCompany(String companyId) async {
    await Future.delayed(_latency);
    
    if (_currentUser == null) {
      throw ApiException('برای دنبال کردن شرکت ابتدا وارد شوید', statusCode: 401);
    }
    
    _followedCompanyIds.add(companyId);
    
    final company = _companies.firstWhere((c) => c.id == companyId);
    return Company(
      id: company.id,
      name: company.name,
      slug: company.slug,
      industry: company.industry,
      city: company.city,
      employeeCount: company.employeeCount,
      about: company.about,
      logoUrl: company.logoUrl,
      isFollowed: true,
      followersCount: company.followersCount + 1,
      rating: 4.5,
    );
  }

  @override
  Future<Company> unfollowCompany(String companyId) async {
    await Future.delayed(_latency);
    
    _followedCompanyIds.remove(companyId);
    
    final company = _companies.firstWhere((c) => c.id == companyId);
    return Company(
      id: company.id,
      name: company.name,
      slug: company.slug,
      industry: company.industry,
      city: company.city,
      employeeCount: company.employeeCount,
      about: company.about,
      logoUrl: company.logoUrl,
      isFollowed: false,
      followersCount: company.followersCount,
      rating: 4.5,
    );
  }

  @override
  Future<bool> isFollowingCompany(String companyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _followedCompanyIds.contains(companyId);
  }

  @override
  Future<int> getCompanyFollowers(String companyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final company = _companies.firstWhere((c) => c.id == companyId);
    return company.followersCount + (_followedCompanyIds.contains(companyId) ? 1 : 0);
  }

  // Update applyToJob to also create an application record
  @override
  Future<void> applyToJob(String jobId) async {
    await Future.delayed(_latency);
    if (_currentUser == null) {
      throw ApiException('برای ثبت درخواست ابتدا وارد شوید', statusCode: 401);
    }
    
    _appliedJobIds.add(jobId);
    await StorageService.addAppliedJob(_currentUser!.id.toString(), jobId);
    
    // Create application record owned by the authenticated user.
    final job = _jobs.firstWhere((j) => j.id == jobId);
    final application = JobApplication(
      id: 'app_${DateTime.now().millisecondsSinceEpoch}',
      job: job,
      appliedAt: DateTime.now(),
      status: ApplicationStatus.pending,
      resumeUrl: _currentResume?.slug,
    );
    
    _applications[application.id] = application;
    _applicationOwners[application.id] = _currentUser!.id.toString();
    await _persistApplications();
  }


  // ---------------------------------------------------------------------------
  // Resume / CV Builder (Section 5.4)
  // ---------------------------------------------------------------------------

  /// All resumes owned by the signed-in user (multi-resume support).
  final List<Resume> _resumes = <Resume>[];

  /// Id of the resume currently being read/edited.
  String? _activeResumeId;

  /// Monotonic counter to help mint unique resume ids within a session.
  int _resumeCounter = 0;

  /// Tracks slugs already taken (simulates server-side uniqueness check).
  final Set<String> _usedSlugs = <String>{};

  /// The active resume — the one CV-builder slices read and write. The
  /// getter/setter keep the original single-resume call sites working over the
  /// underlying list: assigning a resume upserts it by id and makes it active.
  Resume? get _currentResume {
    for (final r in _resumes) {
      if (r.id == _activeResumeId) return r;
    }
    return null;
  }

  set _currentResume(Resume? resume) {
    if (resume == null) {
      _activeResumeId = null;
      return;
    }
    final idx = _resumes.indexWhere((e) => e.id == resume.id);
    if (idx >= 0) {
      _resumes[idx] = resume;
    } else {
      _resumes.add(resume);
    }
    _activeResumeId = resume.id;
  }

  /// Clears the signed-in user's resume state (used on logout / account
  /// switch). [_usedSlugs] is intentionally left intact: resume slugs are
  /// public URLs and must stay globally unique across users for this session.
  void _clearResumes() {
    _resumes.clear();
    _activeResumeId = null;
  }

  /// Registers the current resumes' slugs as taken (add-only, never clears).
  void _registerUsedSlugs() {
    for (final r in _resumes) {
      if (r.slug != null) _usedSlugs.add(r.slug!);
    }
  }

  String _newResumeId() {
    _resumeCounter++;
    return 'resume_${_currentUser!.id}_'
        '${DateTime.now().millisecondsSinceEpoch}_$_resumeCounter';
  }

  /// Returns a slug guaranteed not to collide with an existing one.
  String _uniqueSlug(String base) {
    var candidate = base;
    var n = 1;
    while (_usedSlugs.contains(candidate)) {
      n++;
      candidate = '$base-$n';
    }
    return candidate;
  }

  static const int _maxAvatarBytes = 5 * 1024 * 1024; // 5 MB
  static const int _maxCvFileBytes = 10 * 1024 * 1024; // 10 MB
  static const List<String> _avatarExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> _cvFileExtensions = ['pdf', 'doc', 'docx'];

  /// Reuses Section 5.3 session auth — every resume endpoint starts here.
  void _requireLogin() {
    if (_currentUser == null) {
      throw const ApiException(
        'برای دسترسی به رزومه ابتدا وارد شوید',
        statusCode: 401,
      );
    }
  }

  Future<Resume> _resumeForCv(String cvId) async {
    _requireLogin();
    if (_resumes.isEmpty) {
      throw const ApiException('رزومه یافت نشد', statusCode: 404);
    }
    final idx = _resumes.indexWhere((r) => r.id == cvId);
    if (idx < 0) {
      throw const ApiException(
        'دسترسی به این رزومه مجاز نیست',
        statusCode: 403,
      );
    }
    _activeResumeId = cvId;
    return _resumes[idx];
  }

  Future<void> _persistResume() async {
    final user = _currentUser;
    if (user != null) {
      await StorageService.saveResumes(user.id.toString(), _resumes);
    }
  }

  Resume _withScore(Resume resume) =>
      resume.copyWith(score: resume.calculateScore());

  Future<void> _validateUpload(
    File file, {
    required List<String> allowedExtensions,
    required int maxBytes,
  }) async {
    if (!await file.exists()) {
      throw const ApiException('فایل یافت نشد', statusCode: 400);
    }
    final size = await file.length();
    if (size > maxBytes) {
      throw const ApiException('حجم فایل بیش از حد مجاز است', statusCode: 400);
    }
    final parts = file.path.split('.');
    if (parts.length < 2) {
      throw const ApiException('فرمت فایل مجاز نیست', statusCode: 400);
    }
    final ext = parts.last.toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      throw const ApiException('فرمت فایل مجاز نیست', statusCode: 400);
    }
  }

  String _defaultSlug(String name) =>
      '${name.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9\-]'), '')}-resume';

  Map<String, dynamic> _personalInfoMap(Resume resume, String lang) {
    if (lang == 'en') {
      return {
        'name': resume.name,
        'email': resume.email,
        'phone': resume.phone,
        'personal': resume.personal,
        'about': resume.about,
        'public_contact': resume.publicContact,
      };
    }
    return {
      'name': resume.name,
      'birth_date': resume.birthDate,
      'gender': resume.gender,
      'military_status': resume.militaryStatus,
      'email': resume.email,
      'phone': resume.phone,
      'personal': resume.personal,
      'about': resume.about,
      'public_contact': resume.publicContact,
    };
  }

  Future<Resume> _ensureResume() async {
    _requireLogin();
    final active = _currentResume;
    if (active != null) return active;
    if (_resumes.isNotEmpty) {
      _activeResumeId = _resumes.first.id;
      return _resumes.first;
    }
    final slug = _uniqueSlug(_defaultSlug(_currentUser!.name));
    _usedSlugs.add(slug);
    final created = Resume(
      id: _newResumeId(),
      name: _currentUser!.name,
      email: _currentUser!.email,
      phone: _currentUser!.phone,
      about: _currentUser!.about,
      slug: slug,
    );
    _resumes.add(created);
    _activeResumeId = created.id;
    await _persistResume();
    return created;
  }

  @override
  Future<List<Resume>> getResumes() async {
    await Future.delayed(_latency);
    _requireLogin();
    return List.unmodifiable(_resumes);
  }

  @override
  Future<Resume> getResume() async {
    await Future.delayed(_latency);
    return _ensureResume();
  }

  @override
  Future<Resume> getResumeById(String cvId) async {
    await Future.delayed(_latency);
    return _resumeForCv(cvId);
  }

  @override
  Future<Resume> createResume(Resume resume) async {
    await Future.delayed(_latency);
    _requireLogin();
    final name = resume.name.trim().isEmpty ? _currentUser!.name : resume.name;
    final email =
        resume.email.trim().isEmpty ? _currentUser!.email : resume.email;
    // Auto-generated default slugs are made unique; an explicit slug that
    // collides is rejected so callers know to pick another.
    final slug = resume.slug ?? _uniqueSlug(_defaultSlug(name));
    if (_usedSlugs.contains(slug)) {
      throw const ApiException('این آدرس رزومه قبلاً استفاده شده است',
          statusCode: 409);
    }
    _usedSlugs.add(slug);
    final created = _withScore(
      resume.copyWith(id: _newResumeId(), name: name, email: email, slug: slug),
    );
    _resumes.add(created);
    _activeResumeId = created.id;
    await _persistResume();
    return created;
  }

  @override
  Future<void> deleteResume(String cvId) async {
    await Future.delayed(_latency);
    _requireLogin();
    final idx = _resumes.indexWhere((r) => r.id == cvId);
    if (idx < 0) {
      throw const ApiException('رزومه یافت نشد', statusCode: 404);
    }
    final removed = _resumes.removeAt(idx);
    if (removed.slug != null) _usedSlugs.remove(removed.slug);
    if (_activeResumeId == cvId) {
      _activeResumeId = _resumes.isNotEmpty ? _resumes.first.id : null;
    }
    await _persistResume();
  }

  @override
  Future<Resume> updateResume(Resume resume) async {
    await Future.delayed(_latency);
    _requireLogin();
    if (_currentResume == null) {
      throw const ApiException('رزومه یافت نشد', statusCode: 404);
    }
    if (resume.id != _currentResume!.id) {
      throw const ApiException(
        'دسترسی به این رزومه مجاز نیست',
        statusCode: 403,
      );
    }
    _currentResume = _withScore(resume);
    await _persistResume();
    return _currentResume!;
  }

  @override
  Future<Map<String, dynamic>> getPersonalInfo(String lang) async {
    await Future.delayed(_latency);
    final resume = await _ensureResume();
    return _personalInfoMap(resume, lang);
  }

  @override
  Future<Resume> updatePersonalInfo(
    Map<String, dynamic> personalInfo, {
    String lang = 'fa',
  }) async {
    await Future.delayed(_latency);
    await _ensureResume();
    _currentResume = _withScore(
      _currentResume!.copyWith(
        name: personalInfo['name'] as String? ?? _currentResume!.name,
        birthDate: lang == 'fa'
            ? personalInfo['birth_date'] as String? ?? _currentResume!.birthDate
            : _currentResume!.birthDate,
        gender: lang == 'fa'
            ? personalInfo['gender'] as String? ?? _currentResume!.gender
            : _currentResume!.gender,
        militaryStatus: lang == 'fa'
            ? personalInfo['military_status'] as String? ??
                _currentResume!.militaryStatus
            : _currentResume!.militaryStatus,
        email: personalInfo['email'] as String? ?? _currentResume!.email,
        phone: personalInfo['phone'] as String? ?? _currentResume!.phone,
        personal:
            personalInfo['personal'] as String? ?? _currentResume!.personal,
        about: personalInfo['about'] as String? ?? _currentResume!.about,
        publicContact: personalInfo['public_contact'] as String? ??
            _currentResume!.publicContact,
      ),
    );
    await _persistResume();
    return _currentResume!;
  }

  @override
  Future<String> getResumeLink() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final resume = await _ensureResume();
    final slug = resume.slug ?? _defaultSlug(resume.name);
    return 'https://jobinja.ir/r/$slug';
  }

  @override
  Future<Map<String, dynamic>> getResumeTranslation(String lang) async {
    await Future.delayed(_latency);
    final resume = await _ensureResume();
    return {
      'lang': lang,
      'name': resume.name,
      'about': resume.about,
      'personal': resume.personal,
      'skills': resume.skills,
      'education': resume.education.map((e) => e.toJson()).toList(),
      'experiences': resume.experiences.map((e) => e.toJson()).toList(),
    };
  }

  // ---- CV Builder slices ----

  @override
  Future<Resume> getCvBasicData(String cvId) async {
    await Future.delayed(_latency);
    return _resumeForCv(cvId);
  }

  @override
  Future<Resume> updateCvBasicData(
    String cvId,
    Map<String, dynamic> data,
  ) async {
    await Future.delayed(_latency);
    await _resumeForCv(cvId);
    _currentResume = _withScore(
      _currentResume!.copyWith(
        name: data['name'] as String? ?? _currentResume!.name,
        birthDate: data['birth_date'] as String? ?? _currentResume!.birthDate,
        gender: data['gender'] as String? ?? _currentResume!.gender,
        militaryStatus:
            data['military_status'] as String? ?? _currentResume!.militaryStatus,
        email: data['email'] as String? ?? _currentResume!.email,
        phone: data['phone'] as String? ?? _currentResume!.phone,
      ),
    );
    await _persistResume();
    return _currentResume!;
  }

  @override
  Future<Resume> getCvPersonal(String cvId) async {
    await Future.delayed(_latency);
    return _resumeForCv(cvId);
  }

  @override
  Future<Resume> updateCvPersonal(
    String cvId,
    Map<String, dynamic> data,
  ) async {
    await Future.delayed(_latency);
    await _resumeForCv(cvId);
    _currentResume = _withScore(
      _currentResume!.copyWith(
        personal: data['personal'] as String? ?? _currentResume!.personal,
        about: data['about'] as String? ?? _currentResume!.about,
        publicContact:
            data['public_contact'] as String? ?? _currentResume!.publicContact,
      ),
    );
    await _persistResume();
    return _currentResume!;
  }

  @override
  Future<Resume> getCvEducation(String cvId) async {
    await Future.delayed(_latency);
    return _resumeForCv(cvId);
  }

  @override
  Future<Resume> updateCvEducation(
    String cvId,
    List<Education> education,
  ) async {
    await Future.delayed(_latency);
    await _resumeForCv(cvId);
    _currentResume = _withScore(_currentResume!.copyWith(education: education));
    await _persistResume();
    return _currentResume!;
  }

  @override
  Future<Resume> addEducation(Education education) async {
    await Future.delayed(_latency);
    await _ensureResume();
    final newEducation = Education(
      id: 'edu_${DateTime.now().millisecondsSinceEpoch}',
      degree: education.degree,
      field: education.field,
      university: education.university,
      startYear: education.startYear,
      endYear: education.endYear,
      isCurrent: education.isCurrent,
    );
    _currentResume = _withScore(
      _currentResume!.copyWith(
        education: [..._currentResume!.education, newEducation],
      ),
    );
    await _persistResume();
    return _currentResume!;
  }

  @override
  Future<Resume> updateEducation(String educationId, Education education) async {
    await Future.delayed(_latency);
    await _ensureResume();
    final updated = _currentResume!.education.map((e) {
      if (e.id == educationId) {
        return Education(
          id: e.id,
          degree: education.degree,
          field: education.field,
          university: education.university,
          startYear: education.startYear,
          endYear: education.endYear,
          isCurrent: education.isCurrent,
        );
      }
      return e;
    }).toList();
    _currentResume = _withScore(_currentResume!.copyWith(education: updated));
    await _persistResume();
    return _currentResume!;
  }

  @override
  Future<void> deleteEducation(String educationId) async {
    await Future.delayed(_latency);
    await _ensureResume();
    _currentResume = _withScore(
      _currentResume!.copyWith(
        education:
            _currentResume!.education.where((e) => e.id != educationId).toList(),
      ),
    );
    await _persistResume();
  }

  @override
  Future<Resume> getCvExperience(String cvId) async {
    await Future.delayed(_latency);
    return _resumeForCv(cvId);
  }

  @override
  Future<Resume> updateCvExperience(
    String cvId,
    List<WorkExperience> experiences,
  ) async {
    await Future.delayed(_latency);
    await _resumeForCv(cvId);
    _currentResume =
        _withScore(_currentResume!.copyWith(experiences: experiences));
    await _persistResume();
    return _currentResume!;
  }

  @override
  Future<Resume> addExperience(WorkExperience experience) async {
    await Future.delayed(_latency);
    await _ensureResume();
    final newExperience = WorkExperience(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      company: experience.company,
      position: experience.position,
      description: experience.description,
      startYear: experience.startYear,
      endYear: experience.endYear,
      isCurrent: experience.isCurrent,
    );
    _currentResume = _withScore(
      _currentResume!.copyWith(
        experiences: [..._currentResume!.experiences, newExperience],
      ),
    );
    await _persistResume();
    return _currentResume!;
  }

  @override
  Future<Resume> updateExperience(
    String experienceId,
    WorkExperience experience,
  ) async {
    await Future.delayed(_latency);
    await _ensureResume();
    final updated = _currentResume!.experiences.map((e) {
      if (e.id == experienceId) {
        return WorkExperience(
          id: e.id,
          company: experience.company,
          position: experience.position,
          description: experience.description,
          startYear: experience.startYear,
          endYear: experience.endYear,
          isCurrent: experience.isCurrent,
        );
      }
      return e;
    }).toList();
    _currentResume = _withScore(_currentResume!.copyWith(experiences: updated));
    await _persistResume();
    return _currentResume!;
  }

  @override
  Future<void> deleteExperience(String experienceId) async {
    await Future.delayed(_latency);
    await _ensureResume();
    _currentResume = _withScore(
      _currentResume!.copyWith(
        experiences: _currentResume!.experiences
            .where((e) => e.id != experienceId)
            .toList(),
      ),
    );
    await _persistResume();
  }

  @override
  Future<Resume> getCvLanguages(String cvId) async {
    await Future.delayed(_latency);
    return _resumeForCv(cvId);
  }

  @override
  Future<Resume> updateLanguages(List<Language> languages) async {
    await Future.delayed(_latency);
    await _ensureResume();
    _currentResume = _withScore(_currentResume!.copyWith(languages: languages));
    await _persistResume();
    return _currentResume!;
  }

  @override
  Future<Resume> getCvSkills(String cvId) async {
    await Future.delayed(_latency);
    return _resumeForCv(cvId);
  }

  @override
  Future<Resume> updateSkills(List<String> skills) async {
    await Future.delayed(_latency);
    await _ensureResume();
    _currentResume = _withScore(_currentResume!.copyWith(skills: skills));
    await _persistResume();
    return _currentResume!;
  }

  @override
  Future<int> getResumeScore() async {
    await Future.delayed(_latency);
    _requireLogin();
    if (_currentResume == null) return 0;
    final score = _currentResume!.calculateScore();
    _currentResume = _currentResume!.copyWith(score: score);
    await _persistResume();
    return score;
  }

  @override
  Future<String> uploadCvAvatar(String cvId, File imageFile) async {
    await Future.delayed(_latency);
    await _resumeForCv(cvId);
    await _validateUpload(
      imageFile,
      allowedExtensions: _avatarExtensions,
      maxBytes: _maxAvatarBytes,
    );
    // Keep the picked image's local path so the UI can display the real photo
    // (the mock can't host an uploaded file at a public URL).
    final url = imageFile.path;
    _currentResume = _currentResume!.copyWith(avatarUrl: url);
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(avatarUrl: url);
      await StorageService.saveCurrentUser(_currentUser!);
    }
    await _persistResume();
    return url;
  }

  @override
  Future<String> uploadResumeFile(File file) async {
    await Future.delayed(_latency);
    _requireLogin();
    await _ensureResume();
    await _validateUpload(
      file,
      allowedExtensions: _cvFileExtensions,
      maxBytes: _maxCvFileBytes,
    );
    final url =
        'https://jobinja.ir/storage/resumes/${_currentUser!.id}/${file.path.split('/').last}';
    _currentResume = _currentResume!.copyWith(cvFileUrl: url);
    await _persistResume();
    return url;
  }

  @override
  Future<Resume> updateResumeSlug(String cvId, String slug) async {
    await Future.delayed(_latency);
    await _resumeForCv(cvId);
    final normalized = slug.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw const ApiException('آدرس رزومه نمی‌تواند خالی باشد', statusCode: 400);
    }
    final currentSlug = _currentResume!.slug;
    if (_usedSlugs.contains(normalized) && normalized != currentSlug) {
      throw const ApiException('این آدرس رزومه قبلاً استفاده شده است',
          statusCode: 409);
    }
    if (currentSlug != null) _usedSlugs.remove(currentSlug);
    _usedSlugs.add(normalized);
    _currentResume = _currentResume!.copyWith(slug: normalized);
    await _persistResume();
    return _currentResume!;
  }

  @override
  Future<void> togglePublicity(bool isPublic) async {
    await Future.delayed(_latency);
    await _ensureResume();
    _currentResume = _currentResume!.copyWith(isPublic: isPublic);
    await _persistResume();
  }

  @override
  Future<void> toggleSearchStatus(bool isSearchable) async {
    await Future.delayed(_latency);
    await _ensureResume();
    _currentResume = _currentResume!.copyWith(isSearchable: isSearchable);
    await _persistResume();
  }


  // ---------------------------------------------------------------------------
  // Seed data
  // ---------------------------------------------------------------------------

  // Category constants reused by the seed jobs (match getCategories()).
  static const String _catSoftware = 'وب، برنامه‌نویسی و نرم‌افزار';
  static const String _catIndustrial = 'مهندسی صنایع و مدیریت صنعتی';
  static const String _catMarketing = 'بازاریابی و فروش';
  static const String _catDesign = 'گرافیک و طراحی';

  // Section 5.2 reference data ------------------------------------------------

  static const List<JobCategory> _jobCategories = [
    JobCategory(
      id: 1,
      machineName: 'وب،-برنامه‌نویسی-و-نرم‌افزار',
      name: _catSoftware,
      englishName: 'web, software development',
      popularity: 9,
      homePopularity: 10,
    ),
    JobCategory(
      id: 2,
      machineName: 'مهندسی-صنایع-و-مدیریت-صنعتی',
      name: _catIndustrial,
      englishName: 'industrial engineering & management',
      popularity: 7,
      homePopularity: 6,
    ),
    JobCategory(
      id: 3,
      machineName: 'مالی-و-حسابداری',
      name: 'مالی و حسابداری',
      englishName: 'finance & accounting',
      popularity: 6,
      homePopularity: 5,
    ),
    JobCategory(
      id: 4,
      machineName: 'بازاریابی-و-فروش',
      name: _catMarketing,
      englishName: 'marketing & sales',
      popularity: 8,
      homePopularity: 8,
    ),
    JobCategory(
      id: 5,
      machineName: 'منابع-انسانی',
      name: 'منابع انسانی',
      englishName: 'human resources',
      popularity: 5,
      homePopularity: 4,
    ),
    JobCategory(
      id: 6,
      machineName: 'گرافیک-و-طراحی',
      name: _catDesign,
      englishName: 'graphic & design',
      popularity: 7,
      homePopularity: 7,
    ),
  ];

  static const List<Province> _provinces = [
    Province(
      id: 1,
      englishName: 'East Azerbaijan',
      name: 'آذربایجان شرقی',
      slug: 'آذربایجان-شرقی',
    ),
    Province(id: 2, englishName: 'Tehran', name: 'تهران', slug: 'تهران'),
    Province(id: 3, englishName: 'Isfahan', name: 'اصفهان', slug: 'اصفهان'),
    Province(id: 4, englishName: 'Fars', name: 'فارس', slug: 'فارس'),
    Province(
      id: 5,
      englishName: 'Razavi Khorasan',
      name: 'خراسان رضوی',
      slug: 'خراسان-رضوی',
    ),
    Province(id: 6, englishName: 'Alborz', name: 'البرز', slug: 'البرز'),
    Province(id: 7, englishName: 'Khuzestan', name: 'خوزستان', slug: 'خوزستان'),
    Province(id: 8, englishName: 'Gilan', name: 'گیلان', slug: 'گیلان'),
  ];

  static const List<JobSkill> _skills = [
    JobSkill(id: 472, name: 'Python', total: 13001),
    JobSkill(id: 101, name: 'Java', total: 9800),
    JobSkill(id: 55, name: 'JavaScript', total: 15230),
    JobSkill(id: 900, name: 'Flutter', suggested: true, total: 4200),
    JobSkill(id: 901, name: 'Dart', isNew: true, total: 3100),
    JobSkill(id: 300, name: 'React', total: 8700),
    JobSkill(id: 301, name: 'Django', total: 2600),
    JobSkill(id: 400, name: 'Docker', total: 5400),
    JobSkill(id: 401, name: 'Kubernetes', total: 2300),
    JobSkill(id: 500, name: 'SQL', total: 11000),
    JobSkill(id: 600, name: 'Figma', total: 1900),
    JobSkill(id: 700, name: 'Product Management', total: 1500),
  ];

  static final List<Company> _companies = [
    const Company(
      id: 'company_1',
      name: 'فناوری نوآوران',
      slug: 'navavaran',
      industry: 'کامپیوتر، فناوری اطلاعات و اینترنت',
      city: 'تهران',
      employeeCount: 120,
      about:
          'شرکت فناوری نوآوران در حوزه توسعه محصولات نرم‌افزاری و اپلیکیشن‌های موبایل فعالیت می‌کند.',
    ),
    const Company(
      id: 'company_2',
      name: 'داده‌پردازان آریا',
      slug: 'daadeh-pardazan',
      industry: 'هوش مصنوعی و علم داده',
      city: 'اصفهان',
      employeeCount: 45,
      about:
          'داده‌پردازان آریا روی راهکارهای مبتنی بر داده و یادگیری ماشین تمرکز دارد.',
    ),
    const Company(
      id: 'company_3',
      name: 'فروشگاه آنلاین مهرسان',
      slug: 'mehrsan',
      industry: 'تجارت الکترونیک',
      city: 'تهران',
      employeeCount: 300,
      about:
          'مهرسان یکی از بزرگ‌ترین پلتفرم‌های خرید آنلاین کشور با تیمی پرانرژی است.',
    ),
    const Company(
      id: 'company_4',
      name: 'استودیو طراحی پرتو',
      slug: 'parto-studio',
      industry: 'گرافیک و طراحی',
      city: 'شیراز',
      employeeCount: 18,
      about:
          'استودیو پرتو در زمینه طراحی محصول و تجربه کاربری خدمات ارائه می‌دهد.',
    ),
  ];

  static Company _companyBySlug(String slug) =>
      _companies.firstWhere((c) => c.slug == slug);

  static final List<Job> _jobs = [
    Job(
      id: 'job_1',
      title: 'توسعه‌دهنده Flutter',
      company: _companyBySlug('navavaran'),
      location: const JobLocation(province: 'تهران', city: 'تهران'),
      contractType: 'تمام‌وقت',
      category: _catSoftware,
      salary: const Salary(
        amount: null,
        isNegotiable: true,
        display: 'حقوق توافقی',
      ),
      experienceLevel: 'بیش از سه سال',
      publishedAt: '۱۴۰۵/۰۳/۱۰',
      postedAt: DateTime(2026, 5, 10),
      isRemote: false,
      benefits: const {
        JobBenefit.project,
        JobBenefit.bonus,
        JobBenefit.supplementaryInsurance,
        JobBenefit.flexibleHours,
        JobBenefit.militaryPlacement,
      },
      description:
          'به دنبال توسعه‌دهنده‌ای مسلط به Flutter برای ساخت اپلیکیشن‌های موبایل هستیم. آشنایی با معماری تمیز و مدیریت state الزامی است.',
      requirements: const [
        'تسلط بر Dart و Flutter',
        'آشنایی با معماری MVP/MVVM',
        'تجربه کار با REST API',
        'آشنایی با Git',
      ],
    ),
    Job(
      id: 'job_2',
      title: 'مهندس بک‌اند پایتون',
      company: _companyBySlug('daadeh-pardazan'),
      location: const JobLocation(province: 'اصفهان', city: 'اصفهان'),
      contractType: 'تمام‌وقت',
      category: _catSoftware,
      salary: const Salary(
        amount: 45000000,
        isNegotiable: false,
        display: 'از ۴۵ میلیون تومان',
      ),
      experienceLevel: 'دو تا چهار سال',
      publishedAt: '۱۴۰۵/۰۳/۰۹',
      postedAt: DateTime(2026, 5, 9),
      isRemote: true,
      benefits: const {
        JobBenefit.usd,
        JobBenefit.supplementaryInsurance,
        JobBenefit.flexibleHours,
        JobBenefit.esop,
      },
      description:
          'توسعه سرویس‌های بک‌اند با Django و FastAPI و طراحی پایگاه‌داده برای محصولات داده‌محور.',
      requirements: const [
        'تسلط بر Python',
        'تجربه با Django یا FastAPI',
        'آشنایی با PostgreSQL',
        'آشنایی با Docker',
      ],
    ),
    Job(
      id: 'job_3',
      title: 'کارشناس دیجیتال مارکتینگ',
      company: _companyBySlug('mehrsan'),
      location: const JobLocation(province: 'تهران', city: 'تهران'),
      contractType: 'تمام‌وقت',
      category: _catMarketing,
      salary: const Salary(
        amount: 25000000,
        isNegotiable: false,
        display: 'از ۲۵ میلیون تومان',
      ),
      experienceLevel: 'کمتر از سه سال',
      publishedAt: '۱۴۰۵/۰۳/۰۸',
      postedAt: DateTime(2026, 5, 8),
      isRemote: false,
      benefits: const {
        JobBenefit.bonus,
        JobBenefit.commission,
        JobBenefit.promotion,
      },
      description:
          'مدیریت کمپین‌های تبلیغاتی، تحلیل داده‌های بازاریابی و رشد کانال‌های جذب کاربر.',
      requirements: const [
        'آشنایی با Google Analytics',
        'تجربه مدیریت کمپین',
        'مهارت تحلیل داده',
      ],
    ),
    Job(
      id: 'job_4',
      title: 'طراح رابط و تجربه کاربری',
      company: _companyBySlug('parto-studio'),
      location: const JobLocation(province: 'شیراز', city: 'شیراز'),
      contractType: 'پاره‌وقت',
      category: _catDesign,
      salary: const Salary(
        amount: null,
        isNegotiable: true,
        display: 'حقوق توافقی',
      ),
      experienceLevel: 'دو تا چهار سال',
      publishedAt: '۱۴۰۵/۰۳/۰۷',
      postedAt: DateTime(2026, 5, 7),
      isRemote: true,
      benefits: const {
        JobBenefit.flexibleHours,
        JobBenefit.partTime,
        JobBenefit.businessTrip,
      },
      description:
          'طراحی رابط کاربری اپلیکیشن‌ها و وب‌سایت‌ها با تمرکز بر تجربه کاربری و دسترس‌پذیری.',
      requirements: const [
        'تسلط بر Figma',
        'آشنایی با اصول UX',
        'نمونه‌کار قوی',
      ],
    ),
    Job(
      id: 'job_5',
      title: 'مهندس DevOps',
      company: _companyBySlug('navavaran'),
      location: const JobLocation(province: 'تهران', city: 'تهران'),
      contractType: 'تمام‌وقت',
      category: _catSoftware,
      salary: const Salary(
        amount: 60000000,
        isNegotiable: false,
        display: 'از ۶۰ میلیون تومان',
      ),
      experienceLevel: 'بیش از سه سال',
      publishedAt: '۱۴۰۵/۰۳/۰۶',
      postedAt: DateTime(2026, 5, 6),
      isRemote: false,
      benefits: const {
        JobBenefit.supplementaryInsurance,
        JobBenefit.loan,
        JobBenefit.overtimeOffering,
        JobBenefit.esop,
      },
      description:
          'مدیریت زیرساخت ابری، راه‌اندازی CI/CD و پایش سرویس‌ها در محیط تولید.',
      requirements: const [
        'تجربه با Kubernetes',
        'آشنایی با CI/CD',
        'تسلط بر Linux',
      ],
    ),
    Job(
      id: 'job_6',
      title: 'کارشناس فروش B2B',
      company: _companyBySlug('mehrsan'),
      location: const JobLocation(province: 'تهران', city: 'تهران'),
      contractType: 'تمام‌وقت',
      category: _catMarketing,
      salary: const Salary(
        amount: 20000000,
        isNegotiable: false,
        display: 'از ۲۰ میلیون تومان + پورسانت',
      ),
      experienceLevel: 'کمتر از سه سال',
      publishedAt: '۱۴۰۵/۰۳/۰۵',
      postedAt: DateTime(2026, 5, 5),
      isRemote: false,
      isPublished: false,
      benefits: const {
        JobBenefit.commission,
        JobBenefit.bonus,
        JobBenefit.promotion,
        JobBenefit.afternoonShift,
      },
      description:
          'توسعه بازار سازمانی، مذاکره با مشتریان کلیدی و مدیریت قیف فروش.',
      requirements: const [
        'مهارت مذاکره',
        'آشنایی با CRM',
        'روحیه تیمی',
      ],
    ),
    Job(
      id: 'job_7',
      title: 'دانشمند داده',
      company: _companyBySlug('daadeh-pardazan'),
      location: const JobLocation(province: 'اصفهان', city: 'اصفهان'),
      contractType: 'تمام‌وقت',
      category: _catSoftware,
      salary: const Salary(
        amount: null,
        isNegotiable: true,
        display: 'حقوق توافقی',
      ),
      experienceLevel: 'دو تا چهار سال',
      publishedAt: '۱۴۰۵/۰۳/۰۴',
      postedAt: DateTime(2026, 5, 4),
      isRemote: true,
      benefits: const {
        JobBenefit.usd,
        JobBenefit.supplementaryInsurance,
        JobBenefit.flexibleHours,
        JobBenefit.project,
      },
      description:
          'ساخت مدل‌های یادگیری ماشین، تحلیل داده و ارائه بینش تجاری به تیم محصول.',
      requirements: const [
        'تسلط بر Python و کتابخانه‌های علم داده',
        'آشنایی با یادگیری ماشین',
        'مهارت تحلیل آماری',
      ],
    ),
    Job(
      id: 'job_8',
      title: 'توسعه‌دهنده فرانت‌اند React',
      company: _companyBySlug('navavaran'),
      location: const JobLocation(province: 'تهران', city: 'تهران'),
      contractType: 'تمام‌وقت',
      category: _catSoftware,
      salary: const Salary(
        amount: 40000000,
        isNegotiable: false,
        display: 'از ۴۰ میلیون تومان',
      ),
      experienceLevel: 'دو تا چهار سال',
      publishedAt: '۱۴۰۵/۰۳/۰۳',
      postedAt: DateTime(2026, 5, 3),
      isRemote: false,
      benefits: const {
        JobBenefit.supplementaryInsurance,
        JobBenefit.loan,
        JobBenefit.promotion,
        JobBenefit.disabilitySupport,
      },
      description:
          'توسعه رابط کاربری وب با React و TypeScript و همکاری نزدیک با تیم طراحی.',
      requirements: const [
        'تسلط بر React',
        'آشنایی با TypeScript',
        'تجربه کار با REST/GraphQL',
      ],
    ),
    Job(
      id: 'job_9',
      title: 'مدیر محصول',
      company: _companyBySlug('mehrsan'),
      location: const JobLocation(province: 'تهران', city: 'تهران'),
      contractType: 'تمام‌وقت',
      category: _catIndustrial,
      salary: const Salary(
        amount: null,
        isNegotiable: true,
        display: 'حقوق توافقی',
      ),
      experienceLevel: 'بیش از سه سال',
      publishedAt: '۱۴۰۵/۰۳/۰۲',
      postedAt: DateTime(2026, 5, 2),
      isRemote: false,
      benefits: const {
        JobBenefit.bonus,
        JobBenefit.esop,
        JobBenefit.supplementaryInsurance,
        JobBenefit.businessTrip,
      },
      description:
          'تعریف نقشه راه محصول، اولویت‌بندی ویژگی‌ها و هماهنگی میان تیم‌های مختلف.',
      requirements: const [
        'تجربه مدیریت محصول',
        'تفکر تحلیلی',
        'مهارت ارتباطی قوی',
      ],
    ),
    Job(
      id: 'job_10',
      title: 'کارآموز طراحی گرافیک',
      company: _companyBySlug('parto-studio'),
      location: const JobLocation(province: 'شیراز', city: 'شیراز'),
      contractType: 'کارآموزی',
      category: _catDesign,
      salary: const Salary(
        amount: null,
        isNegotiable: true,
        display: 'حقوق توافقی',
      ),
      experienceLevel: 'بدون نیاز به سابقه',
      publishedAt: '۱۴۰۵/۰۳/۰۱',
      postedAt: DateTime(2026, 5, 1),
      isRemote: false,
      isInternship: true,
      benefits: const {
        JobBenefit.flexibleHours,
      },
      description:
          'همکاری در پروژه‌های طراحی برند و محتوای بصری زیر نظر تیم خلاقیت.',
      requirements: const [
        'آشنایی با Adobe Illustrator',
        'خلاقیت و انگیزه یادگیری',
      ],
    ),
  ];
}
