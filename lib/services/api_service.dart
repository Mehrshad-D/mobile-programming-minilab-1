import 'dart:io';
import '../models/api_response.dart';
import '../models/auth_session.dart';
import '../models/company.dart';
import '../models/job.dart';
import '../models/job_category.dart';
import '../models/job_filters.dart';
import '../models/job_search_meta.dart';
import '../models/job_skill.dart';
import '../models/login_request.dart';
import '../models/login_result.dart';
import '../models/province.dart';
import '../models/signup_request.dart';
import '../models/user.dart';
import '../models/resume.dart';
import '../models/application.dart';
import '../models/job_alert.dart';
import '../models/feedback.dart';

/// Abstract API service interface.
/// Views never call this directly — they go through presenters.
abstract class ApiService {
  // ---------------------------------------------------------------------------
  // Authentication (Section 5.3 — Sanctum Cookie/CSRF flow)
  // ---------------------------------------------------------------------------

  /// `GET /login/user` — loads the login page and returns the CSRF token plus
  /// session cookies (`JSESSID`, `XSRF-TOKEN`). Must be called before
  /// [submitLogin] so the CSRF token is available.
  Future<AuthSession> getLoginPage();

  /// `POST /login/user` — submits the form-urlencoded login request and returns
  /// a [LoginResult] modelling the 302 redirect (home on success, back to the
  /// login page on failure). Throws [ApiException] with 419 on CSRF mismatch.
  Future<LoginResult> submitLogin(LoginRequest request);

  Future<User> signup(SignupRequest request);
  Future<void> logout();
  User? get currentUser;

  // ---------------------------------------------------------------------------
  // Jobs
  // ---------------------------------------------------------------------------
  Future<PaginatedResponse<Job>> getJobs(JobFilters filters);
  Future<Job> getJobById(String id);
  Future<Company> getCompanyBySlug(String slug);
  Future<PaginatedResponse<Job>> getCompanyJobs(String slug, {int page = 1});

  // ---------------------------------------------------------------------------
  // Profile & applications
  // ---------------------------------------------------------------------------
  Future<User> getProfile();
  Future<List<Job>> getAppliedJobs();
  Future<void> applyToJob(String jobId);
  
  // NEW METHODS:
  Future<User> updateProfile(User user);
  Future<String> uploadAvatar(File imageFile);

  // ---------------------------------------------------------------------------
  // Reference data (used by filters and meta endpoints)
  // ---------------------------------------------------------------------------
  Future<List<String>> getCategories();
  Future<List<String>> getLocations();
  Future<List<String>> getJobTypes();
  Future<List<String>> getWorkExperiences();
  Future<List<({String label, int value})>> getSalaryRanges();
  Future<List<({String key, String label})>> getBenefits();

  // ---------------------------------------------------------------------------
  // Section 5.2: Meta / Reference data
  // ---------------------------------------------------------------------------
  Future<List<JobCategory>> getJobCategories();
  Future<JobSearchMeta> getJobSearchMeta();
  Future<List<Province>> getProvinces();
  Future<List<JobSkill>> searchSkills(String query);
  Future<Job?> getLastAppliedJob();



  // ---------------------------------------------------------------------------
  // Resume / CV Builder (Section 5.4) — all require authenticated session
  // ---------------------------------------------------------------------------

  /// `GET /api/v10/resume` — list resumes for the authenticated user.
  Future<List<Resume>> getResumes();

  /// Returns the primary resume (convenience wrapper used by existing screens).
  Future<Resume> getResume();

  /// Returns a specific resume by id and makes it the active one for editing.
  Future<Resume> getResumeById(String cvId);

  /// `POST /api/v10/resume`
  Future<Resume> createResume(Resume resume);

  /// Deletes a resume owned by the authenticated user.
  Future<void> deleteResume(String cvId);

  Future<Resume> updateResume(Resume resume);

  /// `GET /api/v10/resume/{lang}/personal-info` (`lang` = `fa` | `en`).
  Future<Map<String, dynamic>> getPersonalInfo(String lang);

  /// `PUT /api/v10/resume/{lang}/personal-info`
  Future<Resume> updatePersonalInfo(
    Map<String, dynamic> personalInfo, {
    String lang = 'fa',
  });

  /// `GET /api/v10/resume/fa/link`
  Future<String> getResumeLink();

  /// `GET /api/v10/resume/translation?lang=`
  Future<Map<String, dynamic>> getResumeTranslation(String lang);

  // CV Builder slices (cv_id validated against authenticated user)
  Future<Resume> getCvBasicData(String cvId);
  Future<Resume> updateCvBasicData(String cvId, Map<String, dynamic> data);
  Future<Resume> getCvPersonal(String cvId);
  Future<Resume> updateCvPersonal(String cvId, Map<String, dynamic> data);
  Future<Resume> getCvEducation(String cvId);
  Future<Resume> updateCvEducation(String cvId, List<Education> education);
  Future<Resume> addEducation(Education education);
  Future<Resume> updateEducation(String educationId, Education education);
  Future<void> deleteEducation(String educationId);
  Future<Resume> getCvExperience(String cvId);
  Future<Resume> updateCvExperience(String cvId, List<WorkExperience> experiences);
  Future<Resume> addExperience(WorkExperience experience);
  Future<Resume> updateExperience(String experienceId, WorkExperience experience);
  Future<void> deleteExperience(String experienceId);
  Future<Resume> getCvLanguages(String cvId);
  Future<Resume> updateLanguages(List<Language> languages);
  Future<Resume> getCvSkills(String cvId);
  Future<Resume> updateSkills(List<String> skills);

  /// `GET /api/v10/jobseeker-app/cv-builder/{cv_id}/score`
  Future<int> getResumeScore();

  /// `POST .../avatar` — multipart profile image for the CV.
  Future<String> uploadCvAvatar(String cvId, File imageFile);

  /// `POST .../cv-file` — multipart resume document.
  Future<String> uploadResumeFile(File file);

  /// `PUT .../slug` — validates uniqueness.
  Future<Resume> updateResumeSlug(String cvId, String slug);

  Future<void> togglePublicity(bool isPublic);
  Future<void> toggleSearchStatus(bool isSearchable);



  // Add after the existing methods, before the closing brace:

  // ---------------------------------------------------------------------------
  // Section 5.5: Applications
  // ---------------------------------------------------------------------------
  Future<List<JobApplication>> getApplications();
  Future<JobApplication> getApplicationDetail(String applicationId);
  Future<JobApplication> uploadCoverLetter(String applicationId, String content);

  /// `POST .../applications/{app_id}/cover-letter-upload` — multipart upload of
  /// a cover-letter document (pdf/doc/docx). Validated for type and size.
  Future<JobApplication> uploadCoverLetterFile(String applicationId, File file);
  Future<JobApplication> updateCoverLetter(String applicationId, String content);
  Future<void> cancelApplication(String applicationId);

  // ---------------------------------------------------------------------------
  // Section 5.6: Companies (Enhanced)
  // ---------------------------------------------------------------------------
  Future<Company> getCompanyDetail(String slug);
  Future<Map<String, dynamic>> getCompanyApplyData(String companyId, String jobId);

  /// `GET /api/v10/companies/{company_slug}/jobs/{job_slug}` — public job detail
  /// resolved by slug; throws 403 for non-public postings.
  Future<Job> getCompanyJobBySlug(String companySlug, String jobSlug);
  Future<Company> followCompany(String companyId);
  Future<Company> unfollowCompany(String companyId);
  Future<bool> isFollowingCompany(String companyId);
  Future<int> getCompanyFollowers(String companyId);

  // ---------------------------------------------------------------------------
  // Section 5.7: Job Alerts
  // ---------------------------------------------------------------------------
  Future<List<JobAlert>> getJobAlerts();
  Future<JobAlert> createJobAlert(JobAlert alert);
  Future<void> deleteJobAlert(String alertId);
  Future<AlertMeta> getJobAlertMeta();
  Future<JobAlert> updateJobAlert(String alertId, JobAlert alert);
  Future<void> toggleJobAlert(String alertId, bool isActive);


  // ---------------------------------------------------------------------------
  // Section 5.8: Utility
  // ---------------------------------------------------------------------------
  Future<EmailValidationResult> checkEmail(String email);
  Future<FeedbackResult> submitFeedback(FeedbackRequest feedback);
  Future<FeedbackResult> submitContact(ContactRequest contact);
  Future<FeedbackResult> getFeedbackResult(String id);
  Future<void> registerDevice(DeviceRegistration device);
  Future<void> registerFCMDevice(String fcmToken);
  Future<List<ViolationReason>> getViolationReasons();
  Future<void> reportViolation(ViolationReport report);
  Future<void> markNotificationAsSeen(String notificationId);
  Future<void> markAllNotificationsAsSeen();

  /// `POST /api/v10/doc-notification-cookie/` — stores the notification cookie.
  Future<void> storeNotificationCookie(String cookie);
}