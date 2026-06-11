/// Feedback model for user feedback submission
class FeedbackRequest {
  final String subject;
  final String message;
  final int? rating;
  final String? email;

  const FeedbackRequest({
    required this.subject,
    required this.message,
    this.rating,
    this.email,
  });

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'message': message,
    'rating': rating,
    'email': email,
  };
}

/// Feedback result response
class FeedbackResult {
  final String id;
  final String status;
  final DateTime submittedAt;
  final String? trackingCode;

  const FeedbackResult({
    required this.id,
    required this.status,
    required this.submittedAt,
    this.trackingCode,
  });

  factory FeedbackResult.fromJson(Map<String, dynamic> json) {
    return FeedbackResult(
      id: json['id'] as String,
      status: json['status'] as String,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      trackingCode: json['tracking_code'] as String?,
    );
  }
}

/// Contact form model
class ContactRequest {
  final String name;
  final String email;
  final String subject;
  final String message;

  const ContactRequest({
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'subject': subject,
    'message': message,
  };
}

/// Violation report reason
class ViolationReason {
  final String id;
  final String title;
  final String description;

  const ViolationReason({
    required this.id,
    required this.title,
    required this.description,
  });

  factory ViolationReason.fromJson(Map<String, dynamic> json) {
    return ViolationReason(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }
}

/// Violation report request
class ViolationReport {
  final String jobId;
  final String reasonId;
  final String? additionalInfo;

  const ViolationReport({
    required this.jobId,
    required this.reasonId,
    this.additionalInfo,
  });

  Map<String, dynamic> toJson() => {
    'job_id': jobId,
    'reason_id': reasonId,
    'additional_info': additionalInfo,
  };
}

/// Device registration for notifications
class DeviceRegistration {
  final String deviceId;
  final String fcmToken;
  final String platform; // 'android', 'ios', 'web'
  final String? appVersion;

  const DeviceRegistration({
    required this.deviceId,
    required this.fcmToken,
    required this.platform,
    this.appVersion,
  });

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'fcm_token': fcmToken,
    'platform': platform,
    'app_version': appVersion,
  };
}

/// Email validation result
class EmailValidationResult {
  final bool isValid;
  final String? message;
  final String? domain;
  final bool? isDisposable;

  const EmailValidationResult({
    required this.isValid,
    this.message,
    this.domain,
    this.isDisposable,
  });

  factory EmailValidationResult.fromJson(Map<String, dynamic> json) {
    return EmailValidationResult(
      isValid: json['is_valid'] as bool,
      message: json['message'] as String?,
      domain: json['domain'] as String?,
      isDisposable: json['is_disposable'] as bool?,
    );
  }
}