/// Represents the authentication session established by `GET /login/user`
/// (section 5.3). It carries the Laravel Sanctum CSRF token (exposed via the
/// `<meta name="csrf-token">` tag on the real login page) together with the
/// session cookies the server would set.
class AuthSession {
  /// Value of `<meta name="csrf-token" content="...">`, sent back as `_token`.
  final String csrfToken;

  /// The `JSESSID` session cookie.
  final String jsessid;

  /// The `XSRF-TOKEN` cookie used by Sanctum for CSRF protection.
  final String xsrfToken;

  const AuthSession({
    required this.csrfToken,
    required this.jsessid,
    required this.xsrfToken,
  });

  /// The exact `Cookie` header the spec requires on `POST /login/user`:
  /// `XSRF-TOKEN={token}; JSESSID={session}`.
  String get cookieHeader => 'XSRF-TOKEN=$xsrfToken; JSESSID=$jsessid';

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      csrfToken: json['csrf_token'] as String,
      jsessid: json['jsessid'] as String,
      xsrfToken: json['xsrf_token'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'csrf_token': csrfToken,
        'jsessid': jsessid,
        'xsrf_token': xsrfToken,
      };
}
