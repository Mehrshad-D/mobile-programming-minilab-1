import 'job.dart';
import 'dart:ui';

/// Application status
enum ApplicationStatus {
  pending,    // در انتظار بررسی
  reviewing,  // در حال بررسی
  accepted,   // پذیرفته شده
  rejected,   // رد شده
  cancelled;  // لغو شده

  String get displayName {
    switch (this) {
      case ApplicationStatus.pending:
        return 'در انتظار بررسی';
      case ApplicationStatus.reviewing:
        return 'در حال بررسی';
      case ApplicationStatus.accepted:
        return 'پذیرفته شده';
      case ApplicationStatus.rejected:
        return 'رد شده';
      case ApplicationStatus.cancelled:
        return 'لغو شده';
    }
  }

  Color get color {
    switch (this) {
      case ApplicationStatus.pending:
        return const Color(0xFFFFA000);
      case ApplicationStatus.reviewing:
        return const Color(0xFF2196F3);
      case ApplicationStatus.accepted:
        return const Color(0xFF4CAF50);
      case ApplicationStatus.rejected:
        return const Color(0xFFF44336);
      case ApplicationStatus.cancelled:
        return const Color(0xFF9E9E9E);
    }
  }
}

/// Cover letter model
class CoverLetter {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Optional URL of an uploaded cover-letter document (multipart upload).
  final String? fileUrl;

  const CoverLetter({
    required this.id,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.fileUrl,
  });

  factory CoverLetter.fromJson(Map<String, dynamic> json) {
    return CoverLetter(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      fileUrl: json['file_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'file_url': fileUrl,
  };
}

/// Job Application model
class JobApplication {
  final String id;
  final Job job;
  final DateTime appliedAt;
  final ApplicationStatus status;
  final CoverLetter? coverLetter;
  final String? resumeUrl;

  const JobApplication({
    required this.id,
    required this.job,
    required this.appliedAt,
    required this.status,
    this.coverLetter,
    this.resumeUrl,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['id'] as String,
      job: Job.fromJson(json['job'] as Map<String, dynamic>),
      appliedAt: DateTime.parse(json['applied_at'] as String),
      status: _parseStatus(json['status'] as String),
      coverLetter: json['cover_letter'] != null
          ? CoverLetter.fromJson(json['cover_letter'] as Map<String, dynamic>)
          : null,
      resumeUrl: json['resume_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'job': job.toJson(),
    'applied_at': appliedAt.toIso8601String(),
    'status': status.name,
    'cover_letter': coverLetter?.toJson(),
    'resume_url': resumeUrl,
  };

  JobApplication copyWith({
    ApplicationStatus? status,
    CoverLetter? coverLetter,
    String? resumeUrl,
  }) {
    return JobApplication(
      id: id,
      job: job,
      appliedAt: appliedAt,
      status: status ?? this.status,
      coverLetter: coverLetter ?? this.coverLetter,
      resumeUrl: resumeUrl ?? this.resumeUrl,
    );
  }

  static ApplicationStatus _parseStatus(String status) {
    switch (status) {
      case 'pending': return ApplicationStatus.pending;
      case 'reviewing': return ApplicationStatus.reviewing;
      case 'accepted': return ApplicationStatus.accepted;
      case 'rejected': return ApplicationStatus.rejected;
      case 'cancelled': return ApplicationStatus.cancelled;
      default: return ApplicationStatus.pending;
    }
  }
}