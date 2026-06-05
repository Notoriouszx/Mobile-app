import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  /// Sign in with email + password.
  ///
  /// Better Auth responds with:
  ///   { "user": {...}, "session": {...} }
  /// AND sets a `better-auth.session_token` cookie in the response headers.
  ///
  /// On mobile  → CookieManager (dio_cookie_manager) stores the cookie
  ///              automatically and sends it on every subsequent request.
  /// On web     → the browser stores the cookie automatically because
  ///              withCredentials = true.
  ///
  /// We do NOT store a Bearer token — Better Auth is cookie-based.
  Future<UserModel> signIn(String email, String password) async {
    try {
      final response = await _api.dio.post(
        AppConstants.signInEndpoint,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        // Better Auth returns { user: {...}, session: {...} }
        final userJson = data['user'] as Map<String, dynamic>?;
        if (userJson == null) {
          throw Exception('لم يتم استلام بيانات المستخدم');
        }
        // Cookie is stored automatically — nothing extra to do.
        return UserModel.fromJson(userJson);
      }

      final msg = _extractError(response.data, response.statusCode);
      throw Exception(msg);
    } on DioException catch (e) {
      final msg = _extractError(e.response?.data, e.response?.statusCode);
      throw Exception(msg);
    }
  }

  /// Verify there is an active session by calling Better Auth's
  /// /api/auth/get-session endpoint.  The session cookie is sent
  /// automatically by the cookie jar / browser.
  Future<UserModel?> getSession() async {
    try {
      final response = await _api.dio.get(AppConstants.sessionEndpoint);
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>?;
        final userJson = data?['user'] as Map<String, dynamic>?;
        if (userJson != null) {
          return UserModel.fromJson(userJson);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Sign out — tells the server to invalidate the session cookie,
  /// then clears the local cookie jar (mobile).
  Future<void> signOut() async {
    try {
      await _api.dio.post(AppConstants.signOutEndpoint);
    } finally {
      await _api.clearSession();
    }
  }

  // ─── helpers ──────────────────────────────────────────────────────
  String _extractError(dynamic body, int? statusCode) {
    if (body is Map) {
      return (body['message'] ?? body['error'] ?? 'خطأ (${statusCode ?? '?'})').toString();
    }
    return 'خطأ في الاتصال بالخادم';
  }
}
