import '../models/api_response.dart';
import '../models/company.dart';
import '../models/job.dart';
import '../models/job_filters.dart';
import '../models/login_request.dart';
import '../models/signup_request.dart';
import '../models/user.dart';

/// Thrown for any handled API failure so presenters can show a clean message.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Abstract contract for the data layer.
///
/// Presenters depend only on this interface, never on a concrete
/// implementation. That keeps the app testable and lets us swap the in-app
/// mock for a real HTTP client without touching the UI or presenters.
abstract class ApiService {
  Future<User> login(LoginRequest request);

  Future<User> signup(SignupRequest request);

  Future<void> logout();

  User? get currentUser;

  /// Search jobs. All `GET /jobs` parameters from section 5.1 are carried by
  /// [JobFilters], including paging via [JobFilters.page].
  Future<PaginatedResponse<Job>> getJobs(JobFilters filters);

  Future<Job> getJobById(String id);

  Future<Company> getCompanyBySlug(String slug);

  Future<PaginatedResponse<Job>> getCompanyJobs(String slug, {int page = 1});

  Future<User> getProfile();

  Future<List<Job>> getAppliedJobs();

  Future<List<String>> getCategories();

  Future<List<String>> getLocations();

  Future<void> applyToJob(String jobId);
}
