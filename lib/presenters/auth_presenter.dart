import '../models/api_response.dart';
import '../models/login_request.dart';
import '../models/signup_request.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

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

  /// Drives the section 5.3 two-step Sanctum login:
  /// 1. `GET /login/user` to obtain the CSRF token + session cookies.
  /// 2. `POST /login/user` with the form-urlencoded credentials.
  /// The 302 redirect outcome is mapped to success/failure for the View.
  Future<void> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _view.showLoading();
    try {
      // Step 1 — load the login page and read the CSRF token.
      final session = await _api.getLoginPage();

      // Step 2 — submit the form with the issued CSRF token.
      final result = await _api.submitLogin(
        LoginRequest(
          identifier: email,
          password: password,
          token: session.csrfToken,
          rememberMe: rememberMe,
        ),
      );

      if (result.success && result.user != null) {
        _view.onAuthSuccess(result.user!);
      } else {
        // 302 → /login/user means invalid credentials.
        _view.showError('ایمیل یا رمز عبور اشتباه است');
      }
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
