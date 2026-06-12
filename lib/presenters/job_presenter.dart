import '../models/filter_meta.dart';
import '../models/job.dart';
import '../models/job_filters.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../models/api_response.dart';

/// Contract for the home screen (job list + search + pagination).
abstract class JobListView {
  void showLoading();
  void hideLoading();
  void showError(String message);
  void showJobs(List<Job> jobs);
  void showLoadingMore(bool isLoadingMore);
  void showLocations(List<String> locations);
  void showFilterMeta(FilterMeta meta);
  void showLastAppliedJob(Job? job);
}

/// Drives the job list: search, pull-to-refresh and incremental pagination.
class JobListPresenter {
  final JobListView _view;
  final ApiService _api;

  JobListPresenter(this._view, this._api);

  final List<Job> _jobs = [];
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = false;

  /// The active search query; reused when paginating so filters stick.
  JobFilters _filters = const JobFilters();

  bool get hasMore => _currentPage < _lastPage;

  /// Loads the list of provinces used to populate the location filter.
  Future<void> loadLocations() async {
    try {
      final locations = await _api.getLocations();
      _view.showLocations(locations);
    } catch (_) {
      // The filter is optional; ignore failures silently.
    }
  }

  /// Loads the most recent job the user applied to, to show a "continue" card.
  /// Non-critical: silently ignored if unavailable or not logged in.
  Future<void> loadLastAppliedJob() async {
    try {
      final job = await _api.getLastAppliedJob();
      _view.showLastAppliedJob(job);
    } catch (_) {
      _view.showLastAppliedJob(null);
    }
  }

  /// Loads the reference data for the filter bottom-sheet (categories, job
  /// types, work experience, salary ranges, benefits).
  Future<void> loadFilterMeta() async {
    try {
      final categories = await _api.getCategories();
      final jobTypes = await _api.getJobTypes();
      final workExperiences = await _api.getWorkExperiences();
      final salaryRanges = await _api.getSalaryRanges();
      final benefits = await _api.getBenefits();
      _view.showFilterMeta(
        FilterMeta(
          categories: categories,
          jobTypes: jobTypes,
          workExperiences: workExperiences,
          salaryRanges: salaryRanges,
          benefits: benefits,
        ),
      );
    } catch (_) {
      // The filter sheet is optional; ignore failures silently.
    }
  }

  /// Loads the first page. Pass [filters] to apply a new search; omit it to
  /// reload the current query (e.g. pull-to-refresh).
  Future<void> loadJobs([JobFilters? filters]) async {
    if (_isLoading) return;
    _isLoading = true;
    _filters = (filters ?? _filters).copyWith(page: 1);
    _currentPage = 1;
    _view.showLoading();
    try {
      final response = await _api.getJobs(_filters);
      _jobs
        ..clear()
        ..addAll(response.data);
      _currentPage = response.meta.currentPage;
      _lastPage = response.meta.lastPage;
      _view.showJobs(List.unmodifiable(_jobs));
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.networkError);
    } finally {
      _isLoading = false;
      _view.hideLoading();
    }
  }

  /// Appends the next page of results, keeping the active filters.
  Future<void> loadMore() async {
    if (_isLoading || !hasMore) return;
    _isLoading = true;
    _view.showLoadingMore(true);
    final nextQuery = _filters.copyWith(page: _currentPage + 1);
    try {
      final response = await _api.getJobs(nextQuery);
      _filters = nextQuery;
      _currentPage = response.meta.currentPage;
      _lastPage = response.meta.lastPage;
      _jobs.addAll(response.data);
      _view.showJobs(List.unmodifiable(_jobs));
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.networkError);
    } finally {
      _isLoading = false;
      _view.showLoadingMore(false);
    }
  }
}

/// Contract for the job detail screen.
abstract class JobDetailView {
  void showLoading();
  void hideLoading();
  void showError(String message);
  void showJob(Job job);
  void showApplyData(Map<String, dynamic> applyData);
  void onApplied();
}

/// Loads a single job and submits an application.
class JobDetailPresenter {
  final JobDetailView _view;
  final ApiService _api;

  JobDetailPresenter(this._view, this._api);

  Future<void> loadJob(String id) async {
    _view.showLoading();
    try {
      final job = await _api.getJobById(id);
      _view.showJob(job);
      await _loadApplyData(job);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.networkError);
    } finally {
      _view.hideLoading();
    }
  }

  /// Fetches apply eligibility (already applied? has resume?) for the job.
  /// Non-critical: failures (e.g. not logged in) are ignored silently.
  Future<void> _loadApplyData(Job job) async {
    try {
      final data = await _api.getCompanyApplyData(job.company.id, job.id);
      _view.showApplyData(data);
    } catch (_) {
      // Eligibility hints are optional; keep the default apply button.
    }
  }

  Future<void> apply(String jobId) async {
    try {
      await _api.applyToJob(jobId);
      _view.onApplied();
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.genericError);
    }
  }
}
