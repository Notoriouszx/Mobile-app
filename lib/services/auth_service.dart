import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final _api = ApiService();

  /// Sign in via Better Auth email+password provider
  /// Better Auth expects POST to /api/auth/sign-in/email with email and password
  /// Response: { user: {...}, session: {...} } or { user: {...} }
  Future<UserModel> signIn(String email, String password) async {
    try {
      final response = await _api.dio.post(
        AppConstants.signInEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('SignIn response: $data');
        // Better Auth returns { user, session } at top level
        return UserModel.fromJson(data);
      } else {
        final errorMsg = response.data?['error'] ?? response.data?['message'] ?? 'فشل تسجيل الدخول';
        throw Exception(errorMsg);
      }
    } on DioException catch (e) {
      print('DioException: ${e.response?.statusCode} - ${e.response?.data}');
      final msg = e.response?.data?['error'] ?? e.response?.data?['message'];
      throw Exception(msg ?? 'خطأ في الاتصال بالخادم');
    } catch (e) {
      print('Unexpected error: $e');
      rethrow;
    }
  }

  /// Get current session (Better Auth session)
  /// Endpoint: GET /api/auth/get-session
  /// Returns: { user: {...}, session: {...} } if authenticated, null otherwise
  Future<UserModel?> getSession() async {
    try {
      final response = await _api.dio.get(AppConstants.sessionEndpoint);
      if (response.statusCode == 200 && response.data != null) {
        print('Session response: ${response.data}');
        return UserModel.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      print('Session check DioException: ${e.response?.statusCode}');
      return null;
    } catch (e) {
      print('Session check error: $e');
      return null;
    }
  }

  /// Sign out via Better Auth
  /// Endpoint: POST /api/auth/sign-out
  Future<void> signOut() async {
    try {
      await _api.dio.post(AppConstants.signOutEndpoint);
      print('Signed out successfully');
    } catch (e) {
      print('Sign out error: $e');
    }
    await _api.clearCookies();
  }
}
