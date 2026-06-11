/// Company model
class Company {
  final String id;
  final String name;
  final String slug;
  final String industry;
  final String? city;
  final int? employeeCount;
  final String? about;
  final String? logoUrl;
  final bool isFollowed;
  final int followersCount;
  final double? rating;
  final String? website;
  final String? email;
  final String? phone;

  const Company({
    required this.id,
    required this.name,
    required this.slug,
    required this.industry,
    this.city,
    this.employeeCount,
    this.about,
    this.logoUrl,
    this.isFollowed = false,
    this.followersCount = 0,
    this.rating,
    this.website,
    this.email,
    this.phone,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      industry: json['industry'] as String,
      city: json['city'] as String?,
      employeeCount: json['employee_count'] as int?,
      about: json['about'] as String?,
      logoUrl: json['logo_url'] as String?,
      isFollowed: json['is_followed'] as bool? ?? false,
      followersCount: json['followers_count'] as int? ?? 0,
      rating: json['rating'] as double?,
      website: json['website'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'industry': industry,
    'city': city,
    'employee_count': employeeCount,
    'about': about,
    'logo_url': logoUrl,
    'is_followed': isFollowed,
    'followers_count': followersCount,
    'rating': rating,
    'website': website,
    'email': email,
    'phone': phone,
  };
}