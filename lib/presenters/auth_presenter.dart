import '../models/login_request.dart';
import '../models/signup_request.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../models/api_response.dart';

/// Contract the login/sign-up screens implement so the presenter can drive
/// them without knowing anything about Flutter widgets.
abstract class AuthView {
  void showLoading();
  void hideLoading();
  void showError(String message);
  void onAuthSuccess(User user);
}

/// Handles authentication logic and keeps the View free of API calls.
class AuthPresenter {
  final AuthView _view;
  final ApiService _api;

  AuthPresenter(this._view, this._api);

  Future<void> login({required String email, required String password}) async {
    _view.showLoading();
    try {
      final user = await _api.login(
        LoginRequest(email: email, password: password),
      );
      _view.onAuthSuccess(user);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.genericError);
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    _view.showLoading();
    try {
      final user = await _api.signup(
        SignupRequest(name: name, email: email, password: password),
      );
      _view.onAuthSuccess(user);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.genericError);
    } finally {
      _view.hideLoading();
    }
  }
}
