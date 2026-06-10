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
  final String? province;
  final String? birthDate;
  final String? gender;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.headline,
    this.city,
    this.about,
    this.avatarUrl,
    this.province,
    this.birthDate,
    this.gender,
  });

  /// Creates a copy of this user with updated fields
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? headline,
    String? city,
    String? about,
    String? avatarUrl,
    String? province,
    String? birthDate,
    String? gender,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      headline: headline ?? this.headline,
      city: city ?? this.city,
      about: about ?? this.about,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      province: province ?? this.province,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
    );
  }

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
      province: json['province'] as String?,
      birthDate: json['birth_date'] as String?,
      gender: json['gender'] as String?,
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
      'province': province,
      'birth_date': birthDate,
      'gender': gender,
    };
  }

  /// Returns initials for avatar fallback
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0];
    return '${parts[0][0]}${parts[1][0]}';
  }
}