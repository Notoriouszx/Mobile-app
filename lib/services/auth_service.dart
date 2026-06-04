import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  /// Sign in — Better Auth sets a session cookie in the response.
  /// It does NOT return a token. The cookie is stored automatically by CookieJar.
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final response = await _api.dio.post(
        AppConstants.signInEndpoint,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Better Auth returns { user: {...}, session: {...} }
        // The session cookie is set automatically — no token needed
        final userJson = data['user'] ?? data;
        if (userJson == null) {
          throw Exception('لم يتم استلام بيانات المستخدم');
        }
        return UserModel.fromJson({'user': userJson});
      } else {
        final msg = response.data?['message'] ??
            response.data?['error'] ??
            'فشل تسجيل الدخول (${response.statusCode})';
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          'خطأ في الاتصال بالخادم';
      throw Exception(msg);
    }
  }

  /// Check if there is an active session (cookie is sent automatically)
  Future<UserModel?> getSession() async {
    try {
      final response = await _api.dio.get(AppConstants.sessionEndpoint);
      if (response.statusCode == 200 && response.data?['user'] != null) {
        return UserModel.fromJson(response.data['user']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Sign out — clears server session and local cookies
  Future<void> signOut() async {
    try {
      await _api.dio.post(AppConstants.signOutEndpoint);
    } finally {
      await _api.clearSession();
    }
  }
}
