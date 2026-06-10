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
}

/// Loads a company together with the jobs it has posted.
class CompanyPresenter {
  final CompanyView _view;
  final ApiService _api;

  CompanyPresenter(this._view, this._api);

  Future<void> loadCompany(String slug) async {
    _view.showLoading();
    try {
      final company = await _api.getCompanyBySlug(slug);
      final jobs = await _api.getCompanyJobs(slug);
      _view.showCompany(company, jobs.data);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.networkError);
    } finally {
      _view.hideLoading();
    }
  }
}
