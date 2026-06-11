import '../models/company.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../models/api_response.dart';

/// Contract for the company screen.
abstract class CompanyView {
  void showLoading();
  void hideLoading();
  void showError(String message);
  void showCompany(Company company, List<Job> jobs);
  void onFollowChanged(bool isFollowing);
}

class CompanyPresenter {
  final CompanyView _view;
  final ApiService _api;
  List<Job> _currentJobs = [];

  CompanyPresenter(this._view, this._api);

  Future<void> loadCompany(String slug) async {
    _view.showLoading();
    try {
      final company = await _api.getCompanyBySlug(slug);
      final jobsResponse = await _api.getCompanyJobs(slug);
      _currentJobs = jobsResponse.data;  // Store jobs
      _view.showCompany(company, _currentJobs);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.networkError);
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> followCompany(String companyId) async {
    _view.showLoading();
    try {
      final updatedCompany = await _api.followCompany(companyId);
      _view.onFollowChanged(true);
      _view.showCompany(updatedCompany, _currentJobs);  // Use stored jobs
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.genericError);
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> unfollowCompany(String companyId) async {
    _view.showLoading();
    try {
      final updatedCompany = await _api.unfollowCompany(companyId);
      _view.onFollowChanged(false);
      _view.showCompany(updatedCompany, _currentJobs);  // Use stored jobs
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.genericError);
    } finally {
      _view.hideLoading();
    }
  }
}