import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  /// Sign in with email + password.
  ///
  /// Better Auth responds with { "user": {...}, "session": {...} }
  /// and sets a `better-auth.session_token` cookie in Set-Cookie header.
  ///
  /// Mobile  → CookieManager stores + replays the cookie automatically.
  /// Web     → browser stores + replays the cookie (withCredentials=true).
  ///
  /// We do NOT store any token. Never. Better Auth is cookie-based only.
  Future<UserModel> signIn(String email, String password) async {
    try {
      final response = await _api.dio.post(
        AppConstants.signInEndpoint,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final userJson = data['user'] as Map<String, dynamic>?;
        if (userJson == null) {
          throw Exception('لم يتم استلام بيانات المستخدم');
        }
        // Cookie is stored automatically — nothing extra to do here.
        return UserModel.fromJson(userJson);
      }

      throw Exception(_extractError(response.data, response.statusCode));
    } on DioException catch (e) {
      throw Exception(_extractError(e.response?.data, e.response?.statusCode));
    }
  }

  /// Verify there is an active session.
  /// The session cookie is sent automatically — no token needed.
  Future<UserModel?> getSession() async {
    try {
      final response = await _api.dio.get(AppConstants.sessionEndpoint);
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>?;
        final userJson = data?['user'] as Map<String, dynamic>?;
        if (userJson != null) return UserModel.fromJson(userJson);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Sign out — invalidates the server session and clears local cookies.
  Future<void> signOut() async {
    try {
      await _api.dio.post(AppConstants.signOutEndpoint);
    } finally {
      await _api.clearSession();
    }
  }

  String _extractError(dynamic body, int? statusCode) {
    if (body is Map) {
      return (body['message'] ?? body['error'] ?? 'خطأ (${statusCode ?? '?'})').toString();
    }
    return 'خطأ في الاتصال بالخادم';
  }
}
