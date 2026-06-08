/// A province as returned by `GET /api/v10/region/province` (section 5.2),
/// wrapped in a `{ "data": [...] }` envelope by the endpoint.
class Province {
  final int id;
  final String englishName;
  final String name;
  final String slug;

  const Province({
    required this.id,
    required this.englishName,
    required this.name,
    required this.slug,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id'] as int,
      englishName: json['english_name'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'english_name': englishName,
        'name': name,
        'slug': slug,
      };
}
