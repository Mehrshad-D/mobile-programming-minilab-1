import 'job_filters.dart';

/// Frequency options for job alerts
enum AlertFrequency {
  instantly,   // immediately - فوری
  daily,       // daily - روزانه
  weekly,      // weekly - هفتگی
  biweekly;    // every two weeks - دو هفته یکبار

  String get displayName {
    switch (this) {
      case AlertFrequency.instantly:
        return 'فوری';
      case AlertFrequency.daily:
        return 'روزانه';
      case AlertFrequency.weekly:
        return 'هفتگی';
      case AlertFrequency.biweekly:
        return 'دو هفته یکبار';
    }
  }

  static AlertFrequency fromString(String value) {
    switch (value) {
      case 'instantly': return AlertFrequency.instantly;
      case 'daily': return AlertFrequency.daily;
      case 'weekly': return AlertFrequency.weekly;
      case 'biweekly': return AlertFrequency.biweekly;
      default: return AlertFrequency.weekly;
    }
  }
}

/// Job Alert model for saved search notifications
class JobAlert {
  final String id;
  final String name;           // Alert name (e.g., "Python Developer in Tehran")
  final JobFilters filters;    // Search filters for this alert
  final AlertFrequency frequency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastSentAt;
  final int matchCount;        // Number of matching jobs found

  const JobAlert({
    required this.id,
    required this.name,
    required this.filters,
    required this.frequency,
    this.isActive = true,
    required this.createdAt,
    this.lastSentAt,
    this.matchCount = 0,
  });

  factory JobAlert.fromJson(Map<String, dynamic> json) {
    return JobAlert(
      id: json['id'] as String,
      name: json['name'] as String,
      filters: JobFilters.fromJson(json['filters'] as Map<String, dynamic>),
      frequency: AlertFrequency.fromString(json['frequency'] as String),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastSentAt: json['last_sent_at'] != null
          ? DateTime.parse(json['last_sent_at'] as String)
          : null,
      matchCount: json['match_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'filters': filters.toJson(),
    'frequency': frequency.name,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'last_sent_at': lastSentAt?.toIso8601String(),
    'match_count': matchCount,
  };

    JobAlert copyWith({
    String? id,
    String? name,
    JobFilters? filters,
    AlertFrequency? frequency,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastSentAt,
    int? matchCount,
  }) {
    return JobAlert(
      id: id ?? this.id,
      name: name ?? this.name,
      filters: filters ?? this.filters,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastSentAt: lastSentAt ?? this.lastSentAt,
      matchCount: matchCount ?? this.matchCount,
    );
  }
}

/// Alert metadata - available options for creating alerts
class AlertMeta {
  final List<String> frequencies;
  final List<String> jobCategories;
  final List<String> locations;
  final List<String> jobTypes;
  final List<String> workExperiences;

  const AlertMeta({
    required this.frequencies,
    required this.jobCategories,
    required this.locations,
    required this.jobTypes,
    required this.workExperiences,
  });

  factory AlertMeta.fromJson(Map<String, dynamic> json) {
    return AlertMeta(
      frequencies: (json['frequencies'] as List<dynamic>?)?.cast<String>() ?? [],
      jobCategories: (json['job_categories'] as List<dynamic>?)?.cast<String>() ?? [],
      locations: (json['locations'] as List<dynamic>?)?.cast<String>() ?? [],
      jobTypes: (json['job_types'] as List<dynamic>?)?.cast<String>() ?? [],
      workExperiences: (json['work_experiences'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}