/// Payload for `POST /login/user` (section 5.3).
///
/// The real endpoint expects an `application/x-www-form-urlencoded` body with
/// the fields `_token`, `redirect_url`, `identifier`, `password` and an
/// optional `remember_me=on`. [toFormUrlEncoded] produces exactly that string.
class LoginRequest {
  /// The user's email (sent as `identifier`).
  final String identifier;
  final String password;

  /// The CSRF token from the login page (sent as `_token`).
  final String token;

  /// Optional post-login redirect target (sent as `redirect_url`).
  final String redirectUrl;

  /// When true, adds `remember_me=on` to the body.
  final bool rememberMe;

  const LoginRequest({
    required this.identifier,
    required this.password,
    required this.token,
    this.redirectUrl = '',
    this.rememberMe = false,
  });

  /// Builds the `application/x-www-form-urlencoded` request body.
  String toFormUrlEncoded() {
    final parts = <String>[
      '_token=${Uri.encodeQueryComponent(token)}',
      'redirect_url=${Uri.encodeQueryComponent(redirectUrl)}',
      'identifier=${Uri.encodeQueryComponent(identifier)}',
      'password=${Uri.encodeQueryComponent(password)}',
    ];
    if (rememberMe) parts.add('remember_me=on');
    return parts.join('&');
  }
}
