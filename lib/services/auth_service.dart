import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final _api = ApiService();

  /// Sign in via Better Auth email+password provider
  Future<UserModel> signIn(String email, String password) async {
    try {
      final response = await _api.dio.post(
        AppConstants.signInEndpoint,
        data: {
          'email': email,
          'password': password,
          'rememberMe': true,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Better Auth returns { user, session }
        return UserModel.fromJson(data);
      } else {
        throw Exception(response.data['error'] ?? 'فشل تسجيل الدخول');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? e.response?.data?['message'];
      throw Exception(msg ?? 'خطأ في الاتصال بالخادم');
    }
  }

  /// Get current session (Better Auth session)
  Future<UserModel?> getSession() async {
    try {
      final response = await _api.dio.get(AppConstants.sessionEndpoint);
      if (response.statusCode == 200 && response.data != null) {
        return UserModel.fromJson(response.data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _api.dio.post(AppConstants.signOutEndpoint);
    } catch (_) {}
    await _api.clearCookies();
  }
}
