/// A skill as returned by `GET /api/v10/job-skills/search?q=` (section 5.2).
class JobSkill {
  final int id;
  final String name;
  final bool suggested;
  final bool isNew;
  final int active;
  final int total;

  const JobSkill({
    required this.id,
    required this.name,
    this.suggested = false,
    this.isNew = false,
    this.active = 1,
    required this.total,
  });

  factory JobSkill.fromJson(Map<String, dynamic> json) {
    return JobSkill(
      id: json['id'] as int,
      name: json['name'] as String,
      suggested: json['suggested'] as bool? ?? false,
      isNew: json['is_new'] as bool? ?? false,
      active: json['active'] as int? ?? 1,
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'suggested': suggested,
        'is_new': isNew,
        'active': active,
        'total': total,
      };
}
