import '../models/api_response.dart';
import '../models/company.dart';
import '../models/job.dart';
import '../models/job_category.dart';
import '../models/job_filters.dart';
import '../models/job_search_meta.dart';
import '../models/job_skill.dart';
import '../models/login_request.dart';
import '../models/province.dart';
import '../models/signup_request.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'dart:io';
import 'storage_service.dart';


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

  // Private constructor
  MockApiService._internal() {
    _loadPersistedUser();
  }

  Future<void> _loadPersistedUser() async {
    _currentUser = await StorageService.getCurrentUser();
    if (_currentUser != null) {
      final jobIds = await StorageService.getAppliedJobs(_currentUser!.id.toString());
      _appliedJobIds.addAll(jobIds);
    }
  }

  @override
  User? get currentUser => _currentUser;

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  @override
  Future<User> login(LoginRequest request) async {
    await Future.delayed(_latency);
    
    // Validate credentials
    final user = await StorageService.validateLogin(request.email, request.password);
    
    if (user == null) {
      throw ApiException('ایمیل یا رمز عبور اشتباه است', statusCode: 401);
    }
    
    _currentUser = user;
    await StorageService.saveCurrentUser(user);
    
    // Load applied jobs
    final jobIds = await StorageService.getAppliedJobs(user.id.toString());
    _appliedJobIds.clear();
    _appliedJobIds.addAll(jobIds);
    
    return _currentUser!;
  }

  @override
  Future<User> signup(SignupRequest request) async {
    await Future.delayed(_latency);
    
    // Create new user
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch,
      name: request.name,
      email: request.email,
      phone: request.phone,
      city: 'تهران',
      headline: 'کارجوی تازه‌وارد',
    );
    
    // Register user
    final success = await StorageService.registerUser(request.email, newUser);
    
    if (!success) {
      throw ApiException('این ایمیل قبلاً ثبت نام کرده است', statusCode: 409);
    }
    
    _currentUser = newUser;
    await StorageService.saveCurrentUser(newUser);
    
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _appliedJobIds.clear();
    await StorageService.clearCurrentUser();
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
    
    // Update in registered users list
    final users = await StorageService.getRegisteredUsers();
    users[updatedUser.email] = updatedUser;
    await StorageService.saveRegisteredUsers(users);
    
    return _currentUser!;
  }

  @override
  Future<String> uploadAvatar(File imageFile) async {
    await Future.delayed(_latency);
    
    if (_currentUser == null) {
      throw ApiException('برای آپلود عکس ابتدا وارد شوید', statusCode: 401);
    }
    
    // In a real app, you'd upload the file to a server
    // For mock, we'll use UI Avatars API with the user's name
    final fakeAvatarUrl = 'https://ui-avatars.com/api/?background=00bfa5&color=fff&name=${Uri.encodeComponent(_currentUser!.name)}&size=128&rounded=true';
    
    _currentUser = _currentUser!.copyWith(avatarUrl: fakeAvatarUrl);
    await StorageService.saveCurrentUser(_currentUser!);
    
    return fakeAvatarUrl;
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
    String slug, {
    int page = 1,
  }) async {
    await Future.delayed(_latency);
    final companyJobs = _jobs.where((j) => j.company.slug == slug).toList();
    _sort(companyJobs, JobSort.publishedAtDesc);
    return _paginate(companyJobs, page);
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

  @override
  Future<void> applyToJob(String jobId) async {
    await Future.delayed(_latency);
    if (_currentUser == null) {
      throw ApiException('برای ثبت درخواست ابتدا وارد شوید', statusCode: 401);
    }
    _appliedJobIds.add(jobId);
    await StorageService.addAppliedJob(_currentUser!.id.toString(), jobId);
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
