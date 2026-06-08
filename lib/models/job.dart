import 'company.dart';

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
  final String publishedAt;
  final bool isRemote;
  final String? description;
  final List<String> requirements;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.contractType,
    required this.salary,
    required this.experienceLevel,
    required this.publishedAt,
    required this.isRemote,
    this.description,
    this.requirements = const [],
  });

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
      isRemote: json['is_remote'] as bool? ?? false,
      description: json['description'] as String?,
      requirements: (json['requirements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
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
      'is_remote': isRemote,
      'description': description,
      'requirements': requirements,
    };
  }
}
