import 'dart:io';
import '../models/api_response.dart';
import '../models/company.dart';
import '../models/job.dart';
import '../models/job_category.dart';
import '../models/job_filters.dart';
import '../models/job_search_meta.dart';
import '../models/job_skill.dart';
import '../models/login_request.dart';
import '../models/province.dart';
import '../models/signup_request.dart';
import '../models/user.dart';
import '../models/resume.dart';
import '../models/application.dart';
import '../models/job_alert.dart';

/// Abstract API service interface.
/// Views never call this directly — they go through presenters.
abstract class ApiService {
  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------
  Future<User> login(LoginRequest request);
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
  // Resume / CV Builder (Section 5.4)
  // ---------------------------------------------------------------------------
  Future<Resume> getResume();
  Future<Resume> createResume(Resume resume);
  Future<Resume> updateResume(Resume resume);
  Future<Resume> updatePersonalInfo(Map<String, dynamic> personalInfo);
  Future<Resume> addEducation(Education education);
  Future<Resume> updateEducation(String educationId, Education education);
  Future<void> deleteEducation(String educationId);
  Future<Resume> addExperience(WorkExperience experience);
  Future<Resume> updateExperience(String experienceId, WorkExperience experience);
  Future<void> deleteExperience(String experienceId);
  Future<Resume> updateLanguages(List<Language> languages);
  Future<Resume> updateSkills(List<String> skills);
  Future<int> getResumeScore();
  Future<String> uploadResumeFile(File file);
  Future<void> togglePublicity(bool isPublic);
  Future<void> toggleSearchStatus(bool isSearchable);



  // Add after the existing methods, before the closing brace:

  // ---------------------------------------------------------------------------
  // Section 5.5: Applications
  // ---------------------------------------------------------------------------
  Future<List<JobApplication>> getApplications();
  Future<JobApplication> getApplicationDetail(String applicationId);
  Future<JobApplication> uploadCoverLetter(String applicationId, String content);
  Future<JobApplication> updateCoverLetter(String applicationId, String content);
  Future<void> cancelApplication(String applicationId);

  // ---------------------------------------------------------------------------
  // Section 5.6: Companies (Enhanced)
  // ---------------------------------------------------------------------------
  Future<Company> getCompanyDetail(String slug);
  Future<Map<String, dynamic>> getCompanyApplyData(String companyId, String jobId);
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
}