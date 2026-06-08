/// Represents an authenticated job seeker.
class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? headline;
  final String? city;
  final String? about;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.headline,
    this.city,
    this.about,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      headline: json['headline'] as String?,
      city: json['city'] as String?,
      about: json['about'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'headline': headline,
      'city': city,
      'about': about,
      'avatar_url': avatarUrl,
    };
  }
}
