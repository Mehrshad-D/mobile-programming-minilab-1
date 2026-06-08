/// Represents a company that posts jobs.
class Company {
  final String id;
  final String name;
  final String slug;
  final String? logo;
  final String industry;
  final String? about;
  final String? city;
  final int? employeeCount;

  const Company({
    required this.id,
    required this.name,
    required this.slug,
    required this.industry,
    this.logo,
    this.about,
    this.city,
    this.employeeCount,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      logo: json['logo'] as String?,
      industry: json['industry'] as String,
      about: json['about'] as String?,
      city: json['city'] as String?,
      employeeCount: json['employee_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'logo': logo,
      'industry': industry,
      'about': about,
      'city': city,
      'employee_count': employeeCount,
    };
  }
}
