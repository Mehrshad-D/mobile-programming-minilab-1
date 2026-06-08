import '../models/job.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

/// Contract for the home screen (job list + search + pagination).
abstract class JobListView {
  void showLoading();
  void hideLoading();
  void showError(String message);
  void showJobs(List<Job> jobs);
  void showLoadingMore(bool isLoadingMore);
  void showLocations(List<String> locations);
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

  String? _keyword;
  String? _location;

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

  /// Loads the first page, optionally applying a new search filter.
  Future<void> loadJobs({String? keyword, String? location}) async {
    if (_isLoading) return;
    _isLoading = true;
    _keyword = keyword;
    _location = location;
    _currentPage = 1;
    _view.showLoading();
    try {
      final response = await _api.getJobs(
        page: _currentPage,
        keyword: _keyword,
        location: _location,
      );
      _jobs
        ..clear()
        ..addAll(response.data);
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

  /// Appends the next page of results to the existing list.
  Future<void> loadMore() async {
    if (_isLoading || !hasMore) return;
    _isLoading = true;
    _view.showLoadingMore(true);
    try {
      final response = await _api.getJobs(
        page: _currentPage + 1,
        keyword: _keyword,
        location: _location,
      );
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
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.networkError);
    } finally {
      _view.hideLoading();
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
