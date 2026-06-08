/// A job category as returned by `GET /api/v10/job/categories` (section 5.2).
class JobCategory {
  final int id;
  final String machineName;
  final String name;
  final String englishName;
  final String? icon;
  final int popularity;
  final int homePopularity;

  const JobCategory({
    required this.id,
    required this.machineName,
    required this.name,
    required this.englishName,
    this.icon,
    required this.popularity,
    required this.homePopularity,
  });

  factory JobCategory.fromJson(Map<String, dynamic> json) {
    return JobCategory(
      id: json['id'] as int,
      machineName: json['machine_name'] as String,
      name: json['name'] as String,
      englishName: json['english_name'] as String,
      icon: json['icon'] as String?,
      popularity: json['popularity'] as int? ?? 0,
      homePopularity: json['home_popularity'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'machine_name': machineName,
        'name': name,
        'english_name': englishName,
        'icon': icon,
        'popularity': popularity,
        'home_popularity': homePopularity,
      };
}
