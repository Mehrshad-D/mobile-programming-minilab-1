/// Education record model
class Education {
  final String id;
  final String degree; // مدرک تحصیلی (لیسانس، فوق لیسانس، دکتری)
  final String field; // رشته تحصیلی
  final String university; // دانشگاه
  final int startYear; // سال شروع
  final int? endYear; // سال پایان (null اگر در حال تحصیل)
  final bool isCurrent;

  const Education({
    required this.id,
    required this.degree,
    required this.field,
    required this.university,
    required this.startYear,
    this.endYear,
    this.isCurrent = false,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['id'] as String,
      degree: json['degree'] as String,
      field: json['field'] as String,
      university: json['university'] as String,
      startYear: json['start_year'] as int,
      endYear: json['end_year'] as int?,
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'degree': degree,
    'field': field,
    'university': university,
    'start_year': startYear,
    'end_year': endYear,
    'is_current': isCurrent,
  };
}

/// Work experience model
class WorkExperience {
  final String id;
  final String company; // نام شرکت
  final String position; // موقعیت شغلی
  final String? description; // توضیحات
  final int startYear;
  final int? endYear;
  final bool isCurrent;

  const WorkExperience({
    required this.id,
    required this.company,
    required this.position,
    this.description,
    required this.startYear,
    this.endYear,
    this.isCurrent = false,
  });

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      id: json['id'] as String,
      company: json['company'] as String,
      position: json['position'] as String,
      description: json['description'] as String?,
      startYear: json['start_year'] as int,
      endYear: json['end_year'] as int?,
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company': company,
    'position': position,
    'description': description,
    'start_year': startYear,
    'end_year': endYear,
    'is_current': isCurrent,
  };
}

/// Language skill model
class Language {
  final String id;
  final String name; // زبان (انگلیسی، آلمانی، etc.)
  final String level; // سطح (مبتدی، متوسط، پیشرفته، مسلط)

  const Language({
    required this.id,
    required this.name,
    required this.level,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['id'] as String,
      name: json['name'] as String,
      level: json['level'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'level': level,
  };
}

/// Job preference model
class JobPreference {
  final List<String> categories; // دسته‌بندی‌های شغلی مورد علاقه
  final List<String> provinces; // استان‌های مورد نظر
  final int? expectedSalary; // حقوق مورد انتظار

  const JobPreference({
    this.categories = const [],
    this.provinces = const [],
    this.expectedSalary,
  });

  factory JobPreference.fromJson(Map<String, dynamic> json) {
    return JobPreference(
      categories: (json['categories'] as List<dynamic>?)?.cast<String>() ?? [],
      provinces: (json['provinces'] as List<dynamic>?)?.cast<String>() ?? [],
      expectedSalary: json['expected_salary'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'categories': categories,
    'provinces': provinces,
    'expected_salary': expectedSalary,
  };
}

/// Complete Resume/CV model
class Resume {
  final String id;
  final String? slug;
  final String? avatarUrl;
  final String? cvFileUrl;
  
  // Basic data
  final String name;
  final String? birthDate;
  final String? gender;
  final String? militaryStatus; // وضعیت سربازی
  final String email;
  final String? phone;
  
  // Personal info
  final String? about; // درباره من
  final String? publicContact; // اطلاعات تماس عمومی
  
  // Lists
  final List<Education> education;
  final List<WorkExperience> experiences;
  final List<Language> languages;
  final List<String> skills;
  
  // Preference
  final JobPreference preference;
  
  // Metadata
  final int score; // امتیاز کامل بودن رزومه (0-100)
  final bool isPublic; // عمومی/خصوصی
  final bool isSearchable; // قابل جستجو

  const Resume({
    required this.id,
    this.slug,
    this.avatarUrl,
    this.cvFileUrl,
    required this.name,
    this.birthDate,
    this.gender,
    this.militaryStatus,
    required this.email,
    this.phone,
    this.about,
    this.publicContact,
    this.education = const [],
    this.experiences = const [],
    this.languages = const [],
    this.skills = const [],
    this.preference = const JobPreference(),
    this.score = 0,
    this.isPublic = true,
    this.isSearchable = true,
  });

  factory Resume.fromJson(Map<String, dynamic> json) {
    return Resume(
      id: json['id'] as String,
      slug: json['slug'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      cvFileUrl: json['cv_file_url'] as String?,
      name: json['name'] as String,
      birthDate: json['birth_date'] as String?,
      gender: json['gender'] as String?,
      militaryStatus: json['military_status'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      about: json['about'] as String?,
      publicContact: json['public_contact'] as String?,
      education: (json['education'] as List<dynamic>?)
          ?.map((e) => Education.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      experiences: (json['experiences'] as List<dynamic>?)
          ?.map((e) => WorkExperience.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      languages: (json['languages'] as List<dynamic>?)
          ?.map((e) => Language.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
      preference: JobPreference.fromJson(json['preference'] as Map<String, dynamic>? ?? {}),
      score: json['score'] as int? ?? 0,
      isPublic: json['is_public'] as bool? ?? true,
      isSearchable: json['is_searchable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'avatar_url': avatarUrl,
    'cv_file_url': cvFileUrl,
    'name': name,
    'birth_date': birthDate,
    'gender': gender,
    'military_status': militaryStatus,
    'email': email,
    'phone': phone,
    'about': about,
    'public_contact': publicContact,
    'education': education.map((e) => e.toJson()).toList(),
    'experiences': experiences.map((e) => e.toJson()).toList(),
    'languages': languages.map((e) => e.toJson()).toList(),
    'skills': skills,
    'preference': preference.toJson(),
    'score': score,
    'is_public': isPublic,
    'is_searchable': isSearchable,
  };

  /// Calculate resume completion score
  int calculateScore() {
    int score = 0;
    
    // Basic info (30 points)
    if (name.isNotEmpty) score += 10;
    if (email.isNotEmpty) score += 10;
    if (phone != null && phone!.isNotEmpty) score += 5;
    if (about != null && about!.isNotEmpty) score += 5;
    
    // Education (20 points)
    if (education.isNotEmpty) {
      score += 20;
    }
    
    // Work experience (30 points)
    if (experiences.isNotEmpty) {
      score += 30;
    }
    
    // Skills (10 points)
    if (skills.isNotEmpty) {
      score += 10;
    }
    
    // Languages (10 points)
    if (languages.isNotEmpty) {
      score += 10;
    }
    
    return score.clamp(0, 100);
  }

  Resume copyWith({
    String? id,
    String? slug,
    String? avatarUrl,
    String? cvFileUrl,
    String? name,
    String? birthDate,
    String? gender,
    String? militaryStatus,
    String? email,
    String? phone,
    String? about,
    String? publicContact,
    List<Education>? education,
    List<WorkExperience>? experiences,
    List<Language>? languages,
    List<String>? skills,
    JobPreference? preference,
    int? score,
    bool? isPublic,
    bool? isSearchable,
  }) {
    return Resume(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      cvFileUrl: cvFileUrl ?? this.cvFileUrl,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      militaryStatus: militaryStatus ?? this.militaryStatus,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      about: about ?? this.about,
      publicContact: publicContact ?? this.publicContact,
      education: education ?? this.education,
      experiences: experiences ?? this.experiences,
      languages: languages ?? this.languages,
      skills: skills ?? this.skills,
      preference: preference ?? this.preference,
      score: score ?? this.score,
      isPublic: isPublic ?? this.isPublic,
      isSearchable: isSearchable ?? this.isSearchable,
    );
  }
}