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
}