import '../models/job.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

/// Contract for the profile screen.
abstract class ProfileView {
  void showLoading();
  void hideLoading();
  void showError(String message);
  void showProfile(User user, List<Job> appliedJobs);
  void onLoggedOut();
}

/// Loads the user's profile together with their applied jobs and handles logout.
class ProfilePresenter {
  final ProfileView _view;
  final ApiService _api;

  ProfilePresenter(this._view, this._api);

  Future<void> loadProfile() async {
    _view.showLoading();
    try {
      final user = await _api.getProfile();
      final appliedJobs = await _api.getAppliedJobs();
      _view.showProfile(user, appliedJobs);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.networkError);
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> logout() async {
    _view.showLoading();
    try {
      await _api.logout();
      _view.onLoggedOut();
    } catch (_) {
      _view.showError(AppStrings.genericError);
    } finally {
      _view.hideLoading();
    }
  }
}
