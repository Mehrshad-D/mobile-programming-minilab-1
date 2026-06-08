import '../models/api_response.dart';
import '../models/company.dart';
import '../models/job.dart';
import '../models/login_request.dart';
import '../models/signup_request.dart';
import '../models/user.dart';
import 'api_service.dart';

/// In-app implementation of [ApiService].
///
/// It returns static seed data after a short artificial delay so the UI can
/// exercise loading/error states exactly as it would against a real backend.
/// Implemented as a singleton so the "logged-in" session and applied jobs
/// persist while navigating between screens.
class MockApiService implements ApiService {
  MockApiService._internal();

  static final MockApiService _instance = MockApiService._internal();

  factory MockApiService() => _instance;

  static const Duration _latency = Duration(milliseconds: 700);
  static const int _perPage = 4;

  User? _currentUser;
  final Set<String> _appliedJobIds = <String>{};

  @override
  User? get currentUser => _currentUser;

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  @override
  Future<User> login(LoginRequest request) async {
    await Future.delayed(_latency);
    _currentUser = User(
      id: 1,
      name: 'کاربر آزمایشی',
      email: request.email,
      phone: '۰۹۱۲۰۰۰۰۰۰۰',
      headline: 'توسعه‌دهنده موبایل',
      city: 'تهران',
      about: 'علاقه‌مند به توسعه اپلیکیشن‌های موبایل با Flutter و معماری تمیز.',
    );
    return _currentUser!;
  }

  @override
  Future<User> signup(SignupRequest request) async {
    await Future.delayed(_latency);
    _currentUser = User(
      id: 2,
      name: request.name,
      email: request.email,
      city: 'تهران',
      headline: 'کارجوی تازه‌وارد',
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _appliedJobIds.clear();
  }

  // ---------------------------------------------------------------------------
  // Jobs
  // ---------------------------------------------------------------------------

  @override
  Future<PaginatedResponse<Job>> getJobs({
    int page = 1,
    String? keyword,
    String? location,
  }) async {
    await Future.delayed(_latency);

    final filtered = _jobs.where((job) {
      final matchesKeyword = keyword == null ||
          keyword.trim().isEmpty ||
          job.title.contains(keyword.trim()) ||
          job.company.name.contains(keyword.trim());
      final matchesLocation = location == null ||
          location.trim().isEmpty ||
          job.location.province == location.trim();
      return matchesKeyword && matchesLocation;
    }).toList();

    return _paginate(filtered, page);
  }

  @override
  Future<Job> getJobById(String id) async {
    await Future.delayed(_latency);
    final matches = _jobs.where((j) => j.id == id).toList();
    if (matches.isEmpty) {
      throw const ApiException('شغل مورد نظر یافت نشد', statusCode: 404);
    }
    return matches.first;
  }

  @override
  Future<Company> getCompanyBySlug(String slug) async {
    await Future.delayed(_latency);
    final matches = _companies.where((c) => c.slug == slug).toList();
    if (matches.isEmpty) {
      throw const ApiException('شرکت مورد نظر یافت نشد', statusCode: 404);
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
    return _paginate(companyJobs, page);
  }

  // ---------------------------------------------------------------------------
  // Profile & applications
  // ---------------------------------------------------------------------------

  @override
  Future<User> getProfile() async {
    await Future.delayed(_latency);
    final user = _currentUser;
    if (user == null) {
      throw const ApiException('برای مشاهده پروفایل ابتدا وارد شوید',
          statusCode: 401);
    }
    return user;
  }

  @override
  Future<List<Job>> getAppliedJobs() async {
    await Future.delayed(_latency);
    return _jobs.where((j) => _appliedJobIds.contains(j.id)).toList();
  }

  @override
  Future<void> applyToJob(String jobId) async {
    await Future.delayed(_latency);
    _appliedJobIds.add(jobId);
  }

  // ---------------------------------------------------------------------------
  // Reference data
  // ---------------------------------------------------------------------------

  @override
  Future<List<String>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      'وب، برنامه‌نویسی و نرم‌افزار',
      'مهندسی صنایع و مدیریت صنعتی',
      'مالی و حسابداری',
      'بازاریابی و فروش',
      'منابع انسانی',
      'گرافیک و طراحی',
    ];
  }

  @override
  Future<List<String>> getLocations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const ['تهران', 'اصفهان', 'شیراز', 'مشهد', 'البرز'];
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

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
      salary: const Salary(
        amount: null,
        isNegotiable: true,
        display: 'حقوق توافقی',
      ),
      experienceLevel: 'بیش از سه سال',
      publishedAt: '۱۴۰۵/۰۳/۱۰',
      isRemote: false,
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
      salary: const Salary(
        amount: 45000000,
        isNegotiable: false,
        display: 'از ۴۵ میلیون تومان',
      ),
      experienceLevel: 'دو تا چهار سال',
      publishedAt: '۱۴۰۵/۰۳/۰۹',
      isRemote: true,
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
      salary: const Salary(
        amount: 25000000,
        isNegotiable: false,
        display: 'از ۲۵ میلیون تومان',
      ),
      experienceLevel: 'کمتر از سه سال',
      publishedAt: '۱۴۰۵/۰۳/۰۸',
      isRemote: false,
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
      salary: const Salary(
        amount: null,
        isNegotiable: true,
        display: 'حقوق توافقی',
      ),
      experienceLevel: 'دو تا چهار سال',
      publishedAt: '۱۴۰۵/۰۳/۰۷',
      isRemote: true,
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
      salary: const Salary(
        amount: 60000000,
        isNegotiable: false,
        display: 'از ۶۰ میلیون تومان',
      ),
      experienceLevel: 'بیش از سه سال',
      publishedAt: '۱۴۰۵/۰۳/۰۶',
      isRemote: false,
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
      salary: const Salary(
        amount: 20000000,
        isNegotiable: false,
        display: 'از ۲۰ میلیون تومان + پورسانت',
      ),
      experienceLevel: 'کمتر از سه سال',
      publishedAt: '۱۴۰۵/۰۳/۰۵',
      isRemote: false,
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
      salary: const Salary(
        amount: null,
        isNegotiable: true,
        display: 'حقوق توافقی',
      ),
      experienceLevel: 'دو تا چهار سال',
      publishedAt: '۱۴۰۵/۰۳/۰۴',
      isRemote: true,
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
      salary: const Salary(
        amount: 40000000,
        isNegotiable: false,
        display: 'از ۴۰ میلیون تومان',
      ),
      experienceLevel: 'دو تا چهار سال',
      publishedAt: '۱۴۰۵/۰۳/۰۳',
      isRemote: false,
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
      salary: const Salary(
        amount: null,
        isNegotiable: true,
        display: 'حقوق توافقی',
      ),
      experienceLevel: 'بیش از سه سال',
      publishedAt: '۱۴۰۵/۰۳/۰۲',
      isRemote: false,
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
      salary: const Salary(
        amount: null,
        isNegotiable: true,
        display: 'حقوق توافقی',
      ),
      experienceLevel: 'بدون نیاز به سابقه',
      publishedAt: '۱۴۰۵/۰۳/۰۱',
      isRemote: false,
      description:
          'همکاری در پروژه‌های طراحی برند و محتوای بصری زیر نظر تیم خلاقیت.',
      requirements: const [
        'آشنایی با Adobe Illustrator',
        'خلاقیت و انگیزه یادگیری',
      ],
    ),
  ];
}
