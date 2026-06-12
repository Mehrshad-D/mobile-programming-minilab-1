import '../utils/constants.dart';
import 'user.dart';

/// Models the `302 Redirect` outcome of `POST /login/user` (section 5.3):
/// success redirects to the homepage, failure redirects back to `/login/user`.
class LoginResult {
  final bool success;

  /// The `Location` header the server would return with the 302.
  final String redirectLocation;

  /// The authenticated user on success; `null` on failure.
  final User? user;

  const LoginResult._({
    required this.success,
    required this.redirectLocation,
    this.user,
  });

  factory LoginResult.success(User user) => LoginResult._(
        success: true,
        redirectLocation: ApiRoutes.home,
        user: user,
      );

  factory LoginResult.failure() => const LoginResult._(
        success: false,
        redirectLocation: ApiRoutes.loginPage,
      );
}
