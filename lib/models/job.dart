import 'company.dart';

/// Stable keys for the `filters[has_*]` checkboxes described in section 5.1.
/// A job stores the subset of benefits it offers; the search filters by them.
class JobBenefit {
  JobBenefit._();

  static const String usd = 'usd';
  static const String militaryPlacement = 'military_placement';
  static const String loan = 'loan';
  static const String project = 'project';
  static const String bonus = 'bonus';
  static const String commission = 'commission';
  static const String overtimeOffering = 'overtime_offering';
  static const String afternoonShift = 'afternoon_shift';
  static const String promotion = 'promotion';
  static const String partTime = 'part_time';
  static const String disabilitySupport = 'disability_support';
  static const String flexibleHours = 'flexible_hours';
  static const String supplementaryInsurance = 'supplementary_insurance';
  static const String esop = 'esop';
  static const String businessTrip = 'business_trip';
}

/// Geographic location of a job.
class JobLocation {
  final String province;
  final String city;

  const JobLocation({required this.province, required this.city});

  factory JobLocation.fromJson(Map<String, dynamic> json) {
    return JobLocation(
      province: json['province'] as String,
      city: json['city'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'province': province, 'city': city};

  String get display => province == city ? city : '$province، $city';
}

/// Salary information; may be negotiable instead of a fixed amount.
class Salary {
  final int? amount;
  final bool isNegotiable;
  final String display;

  const Salary({
    this.amount,
    required this.isNegotiable,
    required this.display,
  });

  factory Salary.fromJson(Map<String, dynamic> json) {
    return Salary(
      amount: json['amount'] as int?,
      isNegotiable: json['is_negotiable'] as bool? ?? false,
      display: json['display'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'is_negotiable': isNegotiable,
        'display': display,
      };
}

/// A single job posting.
class Job {
  final String id;
  final String title;
  final Company company;
  final JobLocation location;
  final String contractType;
  final Salary salary;
  final String experienceLevel;

  /// Persian-formatted date shown in the UI (e.g. '۱۴۰۵/۰۳/۱۰').
  final String publishedAt;

  /// Machine-comparable timestamp used for `sort_by=published_at_desc`.
  final DateTime postedAt;

  final bool isRemote;
  final bool isInternship;

  /// Job category, matched against `filters[job_categories]`.
  final String category;

  /// Benefit keys this job offers, matched against `filters[has_*]`.
  final Set<String> benefits;

  final String? description;
  final List<String> requirements;

  /// Whether the posting is publicly visible. Private/expired postings are
  /// hidden from the public job-by-slug endpoint (section 5.6).
  final bool isPublished;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.contractType,
    required this.salary,
    required this.experienceLevel,
    required this.publishedAt,
    required this.postedAt,
    required this.isRemote,
    required this.category,
    this.isInternship = false,
    this.benefits = const {},
    this.description,
    this.requirements = const [],
    this.isPublished = true,
  });

  /// URL slug used by `GET /companies/{company_slug}/jobs/{job_slug}`.
  /// Derived from the stable id so no seed data changes are required.
  String get slug => id;

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as String,
      title: json['title'] as String,
      company: Company.fromJson(json['company'] as Map<String, dynamic>),
      location: JobLocation.fromJson(json['location'] as Map<String, dynamic>),
      contractType: json['contract_type'] as String,
      salary: Salary.fromJson(json['salary'] as Map<String, dynamic>),
      experienceLevel: json['experience_level'] as String,
      publishedAt: json['published_at'] as String,
      postedAt: DateTime.tryParse(json['posted_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isRemote: json['is_remote'] as bool? ?? false,
      isInternship: json['is_internship'] as bool? ?? false,
      category: json['category'] as String? ?? '',
      benefits: (json['benefits'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      description: json['description'] as String?,
      requirements: (json['requirements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isPublished: json['is_published'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company.toJson(),
      'location': location.toJson(),
      'contract_type': contractType,
      'salary': salary.toJson(),
      'experience_level': experienceLevel,
      'published_at': publishedAt,
      'posted_at': postedAt.toIso8601String(),
      'is_remote': isRemote,
      'is_internship': isInternship,
      'category': category,
      'benefits': benefits.toList(),
      'description': description,
      'requirements': requirements,
      'is_published': isPublished,
    };
  }
}
