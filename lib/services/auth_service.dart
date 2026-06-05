import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  /// Sign in with email + password.
  ///
  /// The backend returns:
  ///   { "token": "...", "user": {...}, "redirect": false }
  ///
  /// We save the token via `_api.saveToken()` so that the token interceptor
  /// can attach it as `Authorization: Bearer <token>` to every request.
  /// (Cookies are also set, but they do not work cross‑origin on web.)
  Future<UserModel> signIn(String email, String password) async {
    try {
      final response = await _api.dio.post(
        AppConstants.signInEndpoint,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token == null) {
          throw Exception('لم يتم استلام رمز المصادقة');
        }
        // Save the Bearer token for future requests
        await _api.saveToken(token);

        final userJson = data['user'] as Map<String, dynamic>?;
        if (userJson == null) {
          throw Exception('لم يتم استلام بيانات المستخدم');
        }
        return UserModel.fromJson(userJson);
      }

      final msg = _extractError(response.data, response.statusCode);
      throw Exception(msg);
    } on DioException catch (e) {
      final msg = _extractError(e.response?.data, e.response?.statusCode);
      throw Exception(msg);
    }
  }

  /// Verify there is an active session.
  /// The token interceptor automatically adds the Bearer token.
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

  /// Sign out – clears the token and any session cookies.
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
